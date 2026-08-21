import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/shared_space.dart';
import '../../models/app_user.dart';
import 'storage_service.dart';

class SpaceService {
  final StorageService _storageService;

  SpaceService(this._storageService);

  /// Generate a clean, readable 6-character space code like SUPER-4892
  String _generateSpaceCode() {
    final random = Random();
    final number = 1000 + random.nextInt(9000);
    return 'SUPER-$number';
  }

  /// Create a new shared calendar space
  Future<SharedSpace> createSpace({
    required String name,
    required AppUser creator,
  }) async {
    final cleanName = name.trim().isNotEmpty ? name.trim() : 'Our Shared Calendar 🗓️';
    final code = _generateSpaceCode();
    final spaceId = 'space_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}';

    final member = SpaceMember(
      userId: creator.id,
      displayName: creator.displayName,
      email: creator.email,
      photoUrl: creator.photoUrl,
      role: 'owner',
      joinedAt: DateTime.now(),
    );

    final space = SharedSpace(
      id: spaceId,
      name: cleanName,
      code: code,
      creatorId: creator.id,
      memberIds: [creator.id],
      members: {creator.id: member},
      lastActivityNotice: '${creator.displayName} created $cleanName',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Create space document
      await firestore.collection('spaces').doc(spaceId).set(space.toMap());

      // 2. Create space code lookup document
      await firestore.collection('space_codes').doc(code).set({
        'code': code,
        'spaceId': spaceId,
        'spaceName': cleanName,
        'creatorId': creator.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Link space to user document in Firestore
      if (creator.id.isNotEmpty) {
        await firestore.collection('users').doc(creator.id).set({
          'currentSpaceId': spaceId,
          'joinedSpaceIds': FieldValue.arrayUnion([spaceId]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore create space notice (local cache saved): $e');
    }

    // Save locally
    await _storageService.saveCurrentSpace(space);
    return space;
  }

  /// Join an existing shared calendar space using its code (e.g. SUPER-4892 or 4892)
  Future<SharedSpace> joinSpaceByCode({
    required String code,
    required AppUser user,
  }) async {
    final rawInput = code.trim().toUpperCase();
    if (rawInput.isEmpty) {
      throw Exception("Please enter a valid space code.");
    }

    // Generate smart variations of the code to handle various user input formats
    final cleanInput = rawInput.replaceAll(' ', '-');
    final digitsOnly = rawInput.replaceAll(RegExp(r'[^0-9]'), '');
    final candidates = <String>{
      rawInput,
      cleanInput,
      if (digitsOnly.isNotEmpty) 'SUPER-$digitsOnly',
      if (!rawInput.startsWith('SUPER-')) 'SUPER-$rawInput',
    };

    try {
      final firestore = FirebaseFirestore.instance;
      String? resolvedSpaceId;

      // 1. Try finding in `space_codes` collection
      for (final candidate in candidates) {
        final codeDoc = await firestore
            .collection('space_codes')
            .doc(candidate)
            .get()
            .timeout(const Duration(seconds: 6), onTimeout: () {
          return firestore.collection('space_codes').doc('__non_existent__').get();
        });

        if (codeDoc.exists && codeDoc.data() != null) {
          resolvedSpaceId = codeDoc.data()!['spaceId'] as String?;
          if (resolvedSpaceId != null && resolvedSpaceId.isNotEmpty) break;
        }
      }

      // 2. Direct fallback: query `spaces` collection by code field
      if (resolvedSpaceId == null || resolvedSpaceId.isEmpty) {
        for (final candidate in candidates) {
          final querySnap = await firestore
              .collection('spaces')
              .where('code', isEqualTo: candidate)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 6), onTimeout: () {
            return firestore.collection('spaces').where('code', isEqualTo: '__none__').get();
          });

          if (querySnap.docs.isNotEmpty) {
            resolvedSpaceId = querySnap.docs.first.id;
            break;
          }
        }
      }

      if (resolvedSpaceId == null || resolvedSpaceId.isEmpty) {
        throw Exception("Calendar space with code '$rawInput' not found. Please verify the code.");
      }

      // 3. Fetch the space document
      final spaceDoc = await firestore.collection('spaces').doc(resolvedSpaceId).get();
      if (!spaceDoc.exists || spaceDoc.data() == null) {
        throw Exception("This shared calendar is no longer active.");
      }

      final space = SharedSpace.fromMap(spaceDoc.data()!);

      final member = SpaceMember(
        userId: user.id,
        displayName: user.displayName,
        email: user.email,
        photoUrl: user.photoUrl,
        role: space.creatorId == user.id ? 'owner' : 'member',
        joinedAt: DateTime.now(),
      );

      // 4. Update space document with new member
      await firestore.collection('spaces').doc(resolvedSpaceId).set({
        'memberIds': FieldValue.arrayUnion([user.id]),
        'members': {
          user.id: member.toMap(),
        },
        'lastActivityNotice': '${user.displayName} joined the calendar 👋',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 5. Update user document
      if (user.id.isNotEmpty) {
        await firestore.collection('users').doc(user.id).set({
          'currentSpaceId': resolvedSpaceId,
          'joinedSpaceIds': FieldValue.arrayUnion([resolvedSpaceId]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      final updatedMembers = Map<String, SpaceMember>.from(space.members)..[user.id] = member;
      final updatedSpace = space.copyWith(
        memberIds: space.memberIds.contains(user.id) ? space.memberIds : [...space.memberIds, user.id],
        members: updatedMembers,
      );

      await _storageService.saveCurrentSpace(updatedSpace);
      return updatedSpace;
    } on FirebaseException catch (fe) {
      if (fe.code == 'permission-denied') {
        throw Exception("Permission denied. Check Firestore security rules.");
      }
      throw Exception(fe.message ?? fe.code);
    } catch (e) {
      debugPrint('Error joining space: $e');
      rethrow;
    }
  }

  /// Stream real-time shared space updates
  Stream<SharedSpace?> streamSpace(String spaceId) {
    if (spaceId.isEmpty) return Stream.value(_storageService.getCurrentSpace());

    try {
      return FirebaseFirestore.instance
          .collection('spaces')
          .doc(spaceId)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          return _storageService.getCurrentSpace();
        }
        final space = SharedSpace.fromMap(snapshot.data()!);
        _storageService.saveCurrentSpace(space);
        return space;
      });
    } catch (e) {
      debugPrint('Error streaming space: $e');
      return Stream.value(_storageService.getCurrentSpace());
    }
  }

  /// Fetch space from Firestore
  Future<SharedSpace?> fetchSpace(String spaceId) async {
    if (spaceId.isEmpty) return _storageService.getCurrentSpace();

    try {
      final doc = await FirebaseFirestore.instance.collection('spaces').doc(spaceId).get();
      if (doc.exists && doc.data() != null) {
        final space = SharedSpace.fromMap(doc.data()!);
        await _storageService.saveCurrentSpace(space);
        return space;
      }
      return _storageService.getCurrentSpace();
    } catch (e) {
      debugPrint('Error fetching space: $e');
      return _storageService.getCurrentSpace();
    }
  }

  /// Leave a shared space
  Future<void> leaveSpace({
    required String spaceId,
    required String userId,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('spaces').doc(spaceId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'members.$userId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (userId.isNotEmpty) {
        await firestore.collection('users').doc(userId).update({
          'currentSpaceId': null,
          'joinedSpaceIds': FieldValue.arrayRemove([spaceId]),
        });
      }
    } catch (e) {
      debugPrint('Error leaving space: $e');
    } finally {
      await _storageService.saveCurrentSpace(null);
    }
  }
}
