import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_user.dart';
import '../../models/mood_entry.dart';
import '../../models/partner_info.dart';
import '../../providers/mood_provider.dart';
import 'storage_service.dart';

class PartnerService {
  final StorageService _storageService;

  PartnerService(this._storageService);

  /// Generate a unique 6-character invitation code
  Future<String> generatePairingCode(AppUser currentUser) async {
    final random = Random();
    final number = 100000 + random.nextInt(900000);
    final code = 'VIBE-$number';

    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('pairing_codes').doc(code).set({
        'ownerUid': currentUser.id,
        'displayName': currentUser.displayName,
        'email': currentUser.email,
        'photoUrl': currentUser.photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception("Firebase connection timeout. Please check your internet or Firebase Firestore rules.");
        },
      );
      return code;
    } catch (e) {
      debugPrint('Error generating pairing code: $e');
      rethrow;
    }
  }

  /// Redeem an invitation code to pair 1-on-1 with FT
  Future<PartnerInfo> redeemPairingCode({
    required String code,
    required AppUser currentUser,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      throw Exception("Please enter a valid code.");
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore.collection('pairing_codes').doc(cleanCode);
      final snapshot = await docRef.get().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception("Connection timeout while checking code.");
        },
      );

      if (!snapshot.exists) {
        throw Exception("Invalid or expired code. Please check and try again.");
      }

      final data = snapshot.data()!;
      final ownerUid = data['ownerUid'] as String?;
      final ownerDisplayName = data['displayName'] as String? ?? 'FT 🐰';
      final ownerEmail = data['email'] as String? ?? '';
      final ownerPhotoUrl = data['photoUrl'] as String?;

      if (ownerUid == null || ownerUid == currentUser.id) {
        throw Exception("You cannot use your own code.");
      }

      final now = DateTime.now();
      final partnerForCurrentUser = PartnerInfo(
        uid: ownerUid,
        displayName: ownerDisplayName,
        email: ownerEmail,
        photoUrl: ownerPhotoUrl,
        pairedAt: now,
      );

      final partnerForOwner = PartnerInfo(
        uid: currentUser.id,
        displayName: currentUser.displayName,
        email: currentUser.email,
        photoUrl: currentUser.photoUrl,
        pairedAt: now,
      );

      // Batch link both users in Firestore
      final batch = firestore.batch();
      batch.set(
        firestore.collection('users').doc(currentUser.id),
        {'partnerInfo': partnerForCurrentUser.toMap()},
        SetOptions(merge: true),
      );
      batch.set(
        firestore.collection('users').doc(ownerUid),
        {'partnerInfo': partnerForOwner.toMap()},
        SetOptions(merge: true),
      );
      // Remove redeemed code
      batch.delete(docRef);

      await batch.commit().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception("Timeout while saving partner link.");
        },
      );

      // Save locally
      await _storageService.savePartner(partnerForCurrentUser);
      return partnerForCurrentUser;
    } catch (e) {
      debugPrint('Error redeeming pairing code: $e');
      rethrow;
    }
  }


  /// Unpair partner
  Future<void> unpairPartner(String currentUid, String partnerUid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      batch.update(
        firestore.collection('users').doc(currentUid),
        {'partnerInfo': FieldValue.delete()},
      );

      if (partnerUid.isNotEmpty) {
        batch.update(
          firestore.collection('users').doc(partnerUid),
          {'partnerInfo': FieldValue.delete()},
        );
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Cloud unpair notice: $e');
    } finally {
      await _storageService.savePartner(null);
    }
  }

  /// Listen to real-time partner entries from Firestore
  Stream<Map<String, MoodEntry>> streamPartnerEntries(String partnerUid) {
    if (partnerUid.isEmpty) {
      return Stream.value({});
    }

    try {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(partnerUid)
          .collection('mood_entries')
          .snapshots()
          .map((snapshot) {
        final Map<String, MoodEntry> entries = {};
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final entry = MoodEntry.fromMap(data);
          entries[entry.date] = entry;
        }
        // Update local cache
        _storageService.savePartnerEntries(entries);
        return entries;
      });
    } catch (e) {
      debugPrint('Error streaming partner entries: $e');
      final local = _storageService.getPartnerEntries();
      return Stream.value(local);
    }
  }

  /// Real-time stream of the current user's partnerInfo
  Stream<PartnerInfo?> streamUserPartnerInfo(String currentUid) {
    if (currentUid.isEmpty) return Stream.value(null);

    try {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .snapshots()
          .map((doc) {
        if (doc.exists && doc.data() != null && doc.data()!['partnerInfo'] != null) {
          final rawMap = doc.data()!['partnerInfo'] as Map<String, dynamic>;
          final partner = PartnerInfo.fromMap(rawMap);
          _storageService.savePartner(partner);
          return partner;
        } else {
          _storageService.savePartner(null);
          return null;
        }
      });
    } catch (e) {
      debugPrint('Error streaming partner info: $e');
      return Stream.value(_storageService.getSavedPartner());
    }
  }

  /// Fetch user's partner info from Firestore
  Future<PartnerInfo?> fetchCloudPartner(String currentUid) async {
    if (currentUid.isEmpty) return _storageService.getSavedPartner();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .get();

      if (doc.exists && doc.data() != null && doc.data()!['partnerInfo'] != null) {
        final rawMap = doc.data()!['partnerInfo'] as Map<String, dynamic>;
        final partner = PartnerInfo.fromMap(rawMap);
        await _storageService.savePartner(partner);
        return partner;
      } else {
        // If not on cloud, clear local cache
        await _storageService.savePartner(null);
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching cloud partner: $e');
      return _storageService.getSavedPartner();
    }
  }
}

final partnerServiceProvider = Provider<PartnerService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return PartnerService(storageService);
});

