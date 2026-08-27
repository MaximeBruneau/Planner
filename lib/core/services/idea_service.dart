import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bank_idea.dart';
import '../../models/app_user.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class IdeaService {
  final StorageService _storageService;
  final NotificationService _notificationService;
  String? _lastNotifiedChangeId;

  IdeaService(this._storageService, this._notificationService);

  /// Stream loose ideas for a given shared space
  Stream<List<BankIdea>> streamSpaceIdeas({
    required String spaceId,
    required AppUser currentUser,
    Function(String message)? onGroupIdeaNotice,
  }) {
    if (spaceId.isEmpty) {
      return Stream.value(_storageService.getSpaceIdeas(spaceId));
    }

    try {
      final collection = FirebaseFirestore.instance
          .collection('spaces')
          .doc(spaceId)
          .collection('ideas')
          .where('deleted', isNotEqualTo: true);

      return collection.snapshots().map((snapshot) {
        final List<BankIdea> ideas = [];

        for (final doc in snapshot.docs) {
          try {
            final idea = BankIdea.fromMap(doc.data());
            if (!idea.deleted) {
              ideas.add(idea);
            }
          } catch (e) {
            debugPrint('Error parsing bank idea: $e');
          }
        }

        // Notify if another member added/updated an idea in real-time
        final settings = _storageService.getSettings();
        if (settings.groupActivityNotifications && snapshot.docChanges.isNotEmpty) {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
              try {
                final idea = BankIdea.fromMap(change.doc.data() as Map<String, dynamic>);
                final modifier = idea.lastModifiedBy ?? idea.creatorName;
                final changeKey = '${idea.id}_${idea.updatedAt.millisecondsSinceEpoch}';

                if (modifier.isNotEmpty &&
                    modifier != currentUser.displayName &&
                    changeKey != _lastNotifiedChangeId) {
                  _lastNotifiedChangeId = changeKey;

                  String noticeText;
                  if (change.type == DocumentChangeType.added) {
                    noticeText = '$modifier added idea: "${idea.title}" ${idea.category.emoji}';
                  } else {
                    noticeText = '$modifier updated idea "${idea.title}"';
                  }

                  _notificationService.showGroupActivityNotification(
                    title: 'Idea Bank 💡',
                    body: noticeText,
                  );

                  if (onGroupIdeaNotice != null) {
                    onGroupIdeaNotice(noticeText);
                  }
                }
              } catch (_) {}
            }
          }
        }

        // Cache in local storage
        _storageService.saveSpaceIdeas(spaceId, ideas);
        return ideas;
      });
    } catch (e) {
      debugPrint('Error setting up ideas stream: $e');
      return Stream.value(_storageService.getSpaceIdeas(spaceId));
    }
  }

  /// Save or update an idea in local storage & cloud Firestore
  Future<BankIdea> saveIdea({
    required BankIdea idea,
    required AppUser user,
  }) async {
    final updated = idea.copyWith(
      lastModifiedBy: user.displayName,
      updatedAt: DateTime.now(),
    );

    // 1. Save locally
    final cached = _storageService.getSpaceIdeas(idea.spaceId);
    final index = cached.indexWhere((i) => i.id == updated.id);
    if (index >= 0) {
      cached[index] = updated;
    } else {
      cached.add(updated);
    }
    await _storageService.saveSpaceIdeas(idea.spaceId, cached);

    // 2. Sync to Firestore
    if (idea.spaceId.isNotEmpty && idea.spaceId != 'space_default') {
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore
            .collection('spaces')
            .doc(idea.spaceId)
            .collection('ideas')
            .doc(updated.id)
            .set(updated.toMap(), SetOptions(merge: true));

        await firestore.collection('spaces').doc(idea.spaceId).set({
          'lastActivityNotice': '${user.displayName} proposed idea "${updated.title}" ${updated.category.emoji}',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore idea sync error: $e');
      }
    }

    return updated;
  }

  /// Toggle upvote 👍 on an idea
  Future<BankIdea> toggleUpvote({
    required BankIdea idea,
    required AppUser user,
  }) async {
    final upvoters = List<String>.from(idea.upvoterIds);
    if (upvoters.contains(user.id)) {
      upvoters.remove(user.id);
    } else {
      upvoters.add(user.id);
    }

    final updated = idea.copyWith(
      upvoterIds: upvoters,
      lastModifiedBy: user.displayName,
      updatedAt: DateTime.now(),
    );

    return saveIdea(idea: updated, user: user);
  }

  /// Delete an idea
  Future<void> deleteIdea({
    required BankIdea idea,
    required AppUser user,
  }) async {
    // 1. Remove from local cache
    final cached = _storageService.getSpaceIdeas(idea.spaceId);
    cached.removeWhere((i) => i.id == idea.id);
    await _storageService.saveSpaceIdeas(idea.spaceId, cached);

    // 2. Mark deleted in Firestore
    if (idea.spaceId.isNotEmpty && idea.spaceId != 'space_default') {
      try {
        await FirebaseFirestore.instance
            .collection('spaces')
            .doc(idea.spaceId)
            .collection('ideas')
            .doc(idea.id)
            .set({
          'deleted': true,
          'lastModifiedBy': user.displayName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error deleting cloud idea: $e');
      }
    }
  }
}
