import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/plan_activity.dart';
import '../../models/activity_notification.dart';
import '../../models/day_unavailability.dart';
import '../../models/app_user.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class PlanService {
  final StorageService _storageService;
  final NotificationService _notificationService;
  StreamSubscription? _activitySubscription;
  final Set<String> _seenChangeIds = <String>{};

  PlanService(this._storageService, this._notificationService);

  /// Stream items for a given shared space
  Stream<List<PlanActivity>> streamSpaceActivities({
    required String spaceId,
    required AppUser currentUser,
    Function(String message)? onGroupActivityNotice,
  }) {
    if (spaceId.isEmpty) {
      return Stream.value(_storageService.getSpaceActivities(spaceId));
    }

    try {
      final collection = FirebaseFirestore.instance
          .collection('spaces')
          .doc(spaceId)
          .collection('activities');

      final subscriptionStartTime = DateTime.now();
      bool isInitialSnapshot = true;

      return collection.snapshots().map((snapshot) {
        final List<PlanActivity> activities = [];

        for (final doc in snapshot.docs) {
          try {
            final activity = PlanActivity.fromMap(doc.data());
            if (!activity.deleted) {
              activities.add(activity);
            }
          } catch (e) {
            debugPrint('Error parsing activity: $e');
          }
        }

        // Check for changes made by other members to send notifications
        final settings = _storageService.getSettings();
        if (settings.groupActivityNotifications && snapshot.docChanges.isNotEmpty) {
          if (isInitialSnapshot) {
            // First snapshot contains all existing documents: mark them as seen and DO NOT fire live notifications!
            for (final change in snapshot.docChanges) {
              try {
                final activity = PlanActivity.fromMap(change.doc.data() as Map<String, dynamic>);
                _seenChangeIds.add('${activity.id}_${activity.updatedAt.millisecondsSinceEpoch}');
              } catch (_) {}
            }
            isInitialSnapshot = false;
          } else {
            // Subsequent live snapshots: only notify for genuine new live events
            for (final change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
                try {
                  final activity = PlanActivity.fromMap(change.doc.data() as Map<String, dynamic>);
                  final modifier = activity.lastModifiedBy ?? activity.creatorName;
                  final changeKey = '${activity.id}_${activity.updatedAt.millisecondsSinceEpoch}';

                  // Only notify if:
                  // 1. Modified by someone other than current user
                  // 2. We haven't already notified for this exact change revision
                  // 3. The update was actually done recently (since subscription or within the last 60 seconds)
                  final isRecent = activity.updatedAt.isAfter(subscriptionStartTime.subtract(const Duration(seconds: 15))) ||
                      DateTime.now().difference(activity.updatedAt).inSeconds < 60;

                  if (modifier.isNotEmpty &&
                      modifier != currentUser.displayName &&
                      !_seenChangeIds.contains(changeKey) &&
                      isRecent) {
                    _seenChangeIds.add(changeKey);

                    // Prevent unbounded set growth
                    if (_seenChangeIds.length > 500) {
                      _seenChangeIds.clear();
                    }

                    String noticeText;
                    if (change.type == DocumentChangeType.added) {
                      noticeText = '$modifier added: "${activity.title}" for ${activity.date}';
                    } else {
                      noticeText = '$modifier updated "${activity.title}" (${activity.date})';
                    }

                    _notificationService.showGroupActivityNotification(
                      title: 'Super Planner 🗓️',
                      body: noticeText,
                    );

                    if (onGroupActivityNotice != null) {
                      onGroupActivityNotice(noticeText);
                    }
                  }
                } catch (_) {}
              }
            }
          }
        }

        // Save in local storage cache
        _storageService.saveSpaceActivities(spaceId, activities);
        return activities;
      });
    } catch (e) {
      debugPrint('Error setting up activity stream: $e');
      return Stream.value(_storageService.getSpaceActivities(spaceId));
    }
  }

  /// Stream notifications for a given shared space
  Stream<List<ActivityNotification>> streamSpaceNotifications({
    required String spaceId,
    required AppUser currentUser,
  }) {
    if (spaceId.isEmpty) {
      return Stream.value(_storageService.getSpaceNotifications(spaceId));
    }

    try {
      final collection = FirebaseFirestore.instance
          .collection('spaces')
          .doc(spaceId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(80);

      return collection.snapshots().map((snapshot) {
        final readIds = _storageService.getReadNotificationIds(spaceId);
        final List<ActivityNotification> list = [];
        for (final doc in snapshot.docs) {
          try {
            final notif = ActivityNotification.fromMap(doc.data());
            final isRead = notif.isRead ||
                readIds.contains(notif.id) ||
                (currentUser.displayName.isNotEmpty &&
                    notif.authorName == currentUser.displayName);
            list.add(notif.copyWith(isRead: isRead));
          } catch (e) {
            debugPrint('Error parsing notification: $e');
          }
        }
        _storageService.saveSpaceNotifications(spaceId, list);
        return list;
      });
    } catch (e) {
      debugPrint('Error streaming notifications: $e');
      return Stream.value(_storageService.getSpaceNotifications(spaceId));
    }
  }

  /// Log a notification entry both locally and in Firestore
  Future<void> logNotification({
    required String spaceId,
    required ActivityNotification notification,
  }) async {
    final cached = _storageService.getSpaceNotifications(spaceId);
    cached.removeWhere((n) => n.id == notification.id);
    cached.insert(0, notification);
    await _storageService.saveSpaceNotifications(spaceId, cached);

    if (spaceId.isNotEmpty && spaceId != 'space_default') {
      try {
        await FirebaseFirestore.instance
            .collection('spaces')
            .doc(spaceId)
            .collection('notifications')
            .doc(notification.id)
            .set(notification.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore notification log error: $e');
      }
    }
  }

  /// Save or update an item
  Future<PlanActivity> saveActivity({
    required PlanActivity activity,
    required AppUser user,
  }) async {
    final updated = activity.copyWith(
      lastModifiedBy: user.displayName,
      updatedAt: DateTime.now(),
    );

    // 1. Save locally
    final cached = _storageService.getSpaceActivities(activity.spaceId);
    final index = cached.indexWhere((a) => a.id == updated.id);
    if (index >= 0) {
      cached[index] = updated;
    } else {
      cached.add(updated);
    }
    await _storageService.saveSpaceActivities(activity.spaceId, cached);

    // 2. Sync to cloud Firestore
    if (activity.spaceId.isNotEmpty) {
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore
            .collection('spaces')
            .doc(activity.spaceId)
            .collection('activities')
            .doc(updated.id)
            .set(updated.toMap(), SetOptions(merge: true));

        // Update space last notice
        await firestore.collection('spaces').doc(activity.spaceId).set({
          'lastActivityNotice': '${user.displayName} added "${updated.title}" for ${updated.date}',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore activity sync error: $e');
      }
    }

    return updated;
  }

  /// Toggle upvote 👍 on an item
  Future<PlanActivity> toggleUpvote({
    required PlanActivity activity,
    required AppUser user,
  }) async {
    final upvoters = List<String>.from(activity.upvoterIds);
    if (upvoters.contains(user.id)) {
      upvoters.remove(user.id);
    } else {
      upvoters.add(user.id);
    }

    final updated = activity.copyWith(
      upvoterIds: upvoters,
      lastModifiedBy: user.displayName,
      updatedAt: DateTime.now(),
    );

    return saveActivity(activity: updated, user: user);
  }

  /// Toggle done / checked status
  Future<PlanActivity> toggleDone({
    required PlanActivity activity,
    required AppUser user,
  }) async {
    final updated = activity.copyWith(
      isDone: !activity.isDone,
      lastModifiedBy: user.displayName,
      updatedAt: DateTime.now(),
    );

    return saveActivity(activity: updated, user: user);
  }

  /// Delete an activity / item
  Future<void> deleteActivity({
    required PlanActivity activity,
    required AppUser user,
  }) async {
    // 1. Remove from local cache
    final cached = _storageService.getSpaceActivities(activity.spaceId);
    cached.removeWhere((a) => a.id == activity.id);
    await _storageService.saveSpaceActivities(activity.spaceId, cached);

    // 2. Mark deleted in Firestore
    if (activity.spaceId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('spaces')
            .doc(activity.spaceId)
            .collection('activities')
            .doc(activity.id)
            .set({
          'deleted': true,
          'lastModifiedBy': user.displayName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error deleting cloud activity: $e');
      }
    }
  }

  /// Stream member unavailabilities for a given shared space
  Stream<List<DayUnavailability>> streamSpaceUnavailabilities({
    required String spaceId,
  }) {
    if (spaceId.isEmpty) {
      return Stream.value(_storageService.getSpaceUnavailabilities(spaceId));
    }

    try {
      final collection = FirebaseFirestore.instance
          .collection('spaces')
          .doc(spaceId)
          .collection('unavailabilities');

      return collection.snapshots().map((snapshot) {
        final List<DayUnavailability> unavailabilities = [];
        final Set<String> seenKeys = <String>{};

        for (final doc in snapshot.docs) {
          try {
            final u = DayUnavailability.fromMap(doc.data());
            final cleanName = u.userName.toLowerCase().trim();
            final key = '${u.date}_$cleanName';
            if (!seenKeys.contains(key) && !seenKeys.contains('${u.date}_${u.userId}')) {
              seenKeys.add(key);
              seenKeys.add('${u.date}_${u.userId}');
              unavailabilities.add(u);
            }
          } catch (e) {
            debugPrint('Error parsing unavailability: $e');
          }
        }
        _storageService.saveSpaceUnavailabilities(spaceId, unavailabilities);
        return unavailabilities;
      });
    } catch (e) {
      debugPrint('Error streaming unavailabilities: $e');
      return Stream.value(_storageService.getSpaceUnavailabilities(spaceId));
    }
  }

  /// Toggle a member's unavailability for a specific date
  Future<void> toggleUserUnavailability({
    required String spaceId,
    required String date,
    required AppUser user,
  }) async {
    final unavailId = '${spaceId}_${date}_${user.id}';
    final cached = _storageService.getSpaceUnavailabilities(spaceId);
    final cleanUserName = user.displayName.toLowerCase().trim();

    final isAlreadyUnavailable = cached.any((u) =>
        u.date == date &&
        (u.id == unavailId ||
            u.userId == user.id ||
            u.userName.toLowerCase().trim() == cleanUserName ||
            u.userName == 'Lil "LeBg" Binks'));

    if (isAlreadyUnavailable) {
      // Remove all matching entries locally
      cached.removeWhere((u) =>
          u.date == date &&
          (u.id == unavailId ||
              u.userId == user.id ||
              u.userName.toLowerCase().trim() == cleanUserName ||
              u.userName == 'Lil "LeBg" Binks'));
      await _storageService.saveSpaceUnavailabilities(spaceId, cached);

      if (spaceId.isNotEmpty && spaceId != 'space_default') {
        try {
          final firestore = FirebaseFirestore.instance;
          final snap = await firestore
              .collection('spaces')
              .doc(spaceId)
              .collection('unavailabilities')
              .where('date', isEqualTo: date)
              .get();

          for (final doc in snap.docs) {
            final data = doc.data();
            final uid = data['userId'] as String? ?? '';
            final uName = (data['userName'] as String? ?? '').toLowerCase().trim();
            if (uid == user.id || uName == cleanUserName || uName == 'lil "lebg" binks' || doc.id.contains(user.id)) {
              await doc.reference.delete();
            }
          }
        } catch (e) {
          debugPrint('Error removing cloud unavailability: $e');
        }
      }
    } else {
      // Remove any lingering duplicates before adding
      cached.removeWhere((u) =>
          u.date == date &&
          (u.id == unavailId ||
              u.userId == user.id ||
              u.userName.toLowerCase().trim() == cleanUserName ||
              u.userName == 'Lil "LeBg" Binks'));

      final newUnavail = DayUnavailability(
        id: unavailId,
        spaceId: spaceId,
        date: date,
        userId: user.id,
        userName: user.displayName,
        userPhotoUrl: user.photoUrl,
        createdAt: DateTime.now(),
      );

      cached.add(newUnavail);
      await _storageService.saveSpaceUnavailabilities(spaceId, cached);

      if (spaceId.isNotEmpty && spaceId != 'space_default') {
        try {
          final firestore = FirebaseFirestore.instance;
          // Delete any ghost document for this date first
          final snap = await firestore
              .collection('spaces')
              .doc(spaceId)
              .collection('unavailabilities')
              .where('date', isEqualTo: date)
              .get();

          for (final doc in snap.docs) {
            final data = doc.data();
            final uName = (data['userName'] as String? ?? '').toLowerCase().trim();
            if (uName == cleanUserName || uName == 'lil "lebg" binks' || doc.id.contains(user.id)) {
              await doc.reference.delete();
            }
          }

          await firestore
              .collection('spaces')
              .doc(spaceId)
              .collection('unavailabilities')
              .doc(unavailId)
              .set(newUnavail.toMap());
        } catch (e) {
          debugPrint('Error saving cloud unavailability: $e');
        }
      }
    }
  }

  void dispose() {
    _activitySubscription?.cancel();
  }
}
