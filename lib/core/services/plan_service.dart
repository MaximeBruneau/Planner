import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/plan_activity.dart';
import '../../models/activity_notification.dart';
import '../../models/app_user.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class PlanService {
  final StorageService _storageService;
  final NotificationService _notificationService;
  StreamSubscription? _activitySubscription;
  String? _lastNotifiedChangeId;

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
          .collection('activities')
          .where('deleted', isNotEqualTo: true);

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
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
              try {
                final activity = PlanActivity.fromMap(change.doc.data() as Map<String, dynamic>);
                final modifier = activity.lastModifiedBy ?? activity.creatorName;
                final changeKey = '${activity.id}_${activity.updatedAt.millisecondsSinceEpoch}';

                if (modifier.isNotEmpty &&
                    modifier != currentUser.displayName &&
                    changeKey != _lastNotifiedChangeId) {
                  _lastNotifiedChangeId = changeKey;

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
  Stream<List<ActivityNotification>> streamSpaceNotifications({required String spaceId}) {
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
        final List<ActivityNotification> list = [];
        for (final doc in snapshot.docs) {
          try {
            list.add(ActivityNotification.fromMap(doc.data()));
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

  void dispose() {
    _activitySubscription?.cancel();
  }
}
