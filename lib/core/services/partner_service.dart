import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_user.dart';
import '../../models/mood_entry.dart';
import '../../models/partner_info.dart';
import '../../models/pairing_code.dart';
import '../../providers/mood_provider.dart';
import 'storage_service.dart';

class PartnerService {
  final StorageService _storageService;

  PartnerService(this._storageService);

  /// Generate a unique 6-character invitation code with 10-minute automatic expiration
  Future<String> generatePairingCode(AppUser currentUser) async {
    final random = Random();
    final number = 100000 + random.nextInt(900000);
    final code = 'VIBE-$number';

    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: 10));

      final pairingCodeObj = PairingCode(
        code: code,
        creatorUserId: currentUser.id,
        creatorDisplayName: currentUser.displayName,
        creatorEmail: currentUser.email,
        creatorPhotoUrl: currentUser.photoUrl,
        createdAt: now,
        expiresAt: expiresAt,
        used: false,
      );

      await firestore.collection('pairing_codes').doc(code).set(
        pairingCodeObj.toMap(),
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception("Connection timed out. Please check your internet connection.");
        },
      );

      return code;
    } on FirebaseException catch (fe) {
      if (fe.code == 'permission-denied') {
        throw Exception(
          "Permission denied. Please ensure Firestore security rules are deployed.",
        );
      }
      throw Exception(fe.message ?? fe.code);
    } catch (e) {
      debugPrint('Error generating pairing code: $e');
      rethrow;
    }
  }

  /// Redeem an invitation code to pair 1-on-1 with Partner
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
      final codeDocRef = firestore.collection('pairing_codes').doc(cleanCode);

      final snapshot = await codeDocRef.get().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception("Connection timed out while verifying the code.");
        },
      );

      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception("Code not found, please check and try again.");
      }

      final data = snapshot.data()!;
      final pairingCode = PairingCode.fromMap(data);

      // Check if code has already been used
      if (pairingCode.used) {
        throw Exception("This code has already been used.");
      }

      // Check if code has expired (10 minutes lifetime)
      if (pairingCode.isExpired) {
        throw Exception("Code has expired. Please request a new code.");
      }

      final ownerUid = pairingCode.creatorUserId;
      if (ownerUid.isEmpty || ownerUid == currentUser.id) {
        throw Exception("You cannot use your own code.");
      }

      final now = DateTime.now();
      final partnerForCurrentUser = PartnerInfo(
        uid: ownerUid,
        displayName: pairingCode.creatorDisplayName,
        email: pairingCode.creatorEmail ?? '',
        photoUrl: pairingCode.creatorPhotoUrl,
        pairedAt: now,
      );

      final partnerForOwner = PartnerInfo(
        uid: currentUser.id,
        displayName: currentUser.displayName,
        email: currentUser.email,
        photoUrl: currentUser.photoUrl,
        pairedAt: now,
      );

      final connectionId = '${currentUser.id}_$ownerUid';
      final connectionDocRef =
          firestore.collection('partner_connections').doc(connectionId);

      // 1. Mark pairing code as claimed
      try {
        await codeDocRef.set({
          'used': true,
          'claimedBy': currentUser.id,
          'claimantInfo': partnerForOwner.toMap(),
          'claimedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Mark code used notice: $e');
      }

      // 2. Link partner on current user
      await firestore.collection('users').doc(currentUser.id).set(
        {
          'partnerId': ownerUid,
          'partnerInfo': partnerForCurrentUser.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 3. Link partner on creator
      try {
        await firestore.collection('users').doc(ownerUid).set(
          {
            'partnerId': currentUser.id,
            'partnerInfo': partnerForOwner.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('Direct creator doc update notice (handled by sync): $e');
      }

      // 4. Create partner connection doc
      try {
        await connectionDocRef.set({
          'id': connectionId,
          'userA': currentUser.id,
          'userB': ownerUid,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Connection doc create notice: $e');
      }

      // 5. Automatic Duo Pass synchronization between partners
      try {
        // Check if creator has active Duo Pass
        final creatorDoc = await firestore.collection('users').doc(ownerUid).get();
        if (creatorDoc.exists && creatorDoc.data() != null) {
          final cData = creatorDoc.data()!;
          if (cData['isDuoPass'] == true) {
            final expiryStr = cData['premiumExpiryDate'] as String?;
            await firestore.collection('users').doc(currentUser.id).set({
              'premiumGrantedByPartner': true,
              'premiumGrantedByUserId': ownerUid,
              'premiumExpiryDate': expiryStr,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            final currentSettings = _storageService.getSettings();
            DateTime? expiry;
            if (expiryStr != null) {
              try { expiry = DateTime.parse(expiryStr); } catch (_) {}
            }
            await _storageService.saveSettings(currentSettings.copyWith(
              premiumGrantedByPartner: true,
              premiumExpiryDate: expiry ?? currentSettings.premiumExpiryDate,
            ));
          }
        }

        // Check if claimant has active Duo Pass
        final claimantDoc = await firestore.collection('users').doc(currentUser.id).get();
        if (claimantDoc.exists && claimantDoc.data() != null) {
          final clData = claimantDoc.data()!;
          if (clData['isDuoPass'] == true) {
            final expiryStr = clData['premiumExpiryDate'] as String?;
            await firestore.collection('users').doc(ownerUid).set({
              'premiumGrantedByPartner': true,
              'premiumGrantedByUserId': currentUser.id,
              'premiumExpiryDate': expiryStr,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }
      } catch (e) {
        debugPrint('Duo Pass pairing sync notice: $e');
      }

      // Save locally
      await _storageService.savePartner(partnerForCurrentUser);
      return partnerForCurrentUser;
    } on FirebaseException catch (fe) {
      if (fe.code == 'permission-denied') {
        throw Exception(
          "Permission denied by Firestore. Please deploy firestore.rules security rules.",
        );
      }
      throw Exception(fe.message ?? fe.code);
    } catch (e) {
      debugPrint('Error redeeming pairing code: $e');
      rethrow;
    }
  }

  /// Bilateral unpair: clears partner links on both sides and marks connection as dissolved
  Future<void> unpairPartner(String currentUid, String partnerUid) async {

    try {
      final firestore = FirebaseFirestore.instance;

      if (currentUid.isNotEmpty) {
        try {
          final userDoc = await firestore.collection('users').doc(currentUid).get();
          final isOwner = userDoc.exists && (userDoc.data()?['isDuoPass'] == true || userDoc.data()?['isPremium'] == true);

          final Map<String, dynamic> updateData = {
            'partnerId': null,
            'partnerInfo': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          // If current user is not the direct purchaser, revoke gifted Duo Pass
          if (!isOwner) {
            updateData['premiumGrantedByPartner'] = false;
            updateData['premiumGrantedByUserId'] = FieldValue.delete();
          }

          await firestore.collection('users').doc(currentUid).set(
            updateData,
            SetOptions(merge: true),
          );
        } catch (e) {
          debugPrint('Unpair current user notice: $e');
        }

        // Clean up any pairing codes created by current user
        try {
          final codesQuery = await firestore
              .collection('pairing_codes')
              .where('creatorUserId', isEqualTo: currentUid)
              .get();
          for (final doc in codesQuery.docs) {
            await doc.reference.delete();
          }
        } catch (e) {
          debugPrint('Clean creator pairing codes notice: $e');
        }
      }

      if (partnerUid.isNotEmpty) {
        try {
          final partnerDoc = await firestore.collection('users').doc(partnerUid).get();
          final isPartnerOwner = partnerDoc.exists && (partnerDoc.data()?['isDuoPass'] == true || partnerDoc.data()?['isPremium'] == true);

          final Map<String, dynamic> partnerUpdateData = {
            'partnerId': null,
            'partnerInfo': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          // If partner is not the direct purchaser, revoke gifted Duo Pass
          if (!isPartnerOwner) {
            partnerUpdateData['premiumGrantedByPartner'] = false;
            partnerUpdateData['premiumGrantedByUserId'] = FieldValue.delete();
          }

          await firestore.collection('users').doc(partnerUid).set(
            partnerUpdateData,
            SetOptions(merge: true),
          );
        } catch (e) {
          debugPrint('Unpair partner notice: $e');
        }

        // Clean up any pairing codes created by partner
        try {
          final partnerCodesQuery = await firestore
              .collection('pairing_codes')
              .where('creatorUserId', isEqualTo: partnerUid)
              .get();
          for (final doc in partnerCodesQuery.docs) {
            await doc.reference.delete();
          }
        } catch (e) {
          debugPrint('Clean partner pairing codes notice: $e');
        }

        final connectionId1 = '${currentUid}_$partnerUid';
        final connectionId2 = '${partnerUid}_$currentUid';

        try {
          await firestore.collection('partner_connections').doc(connectionId1).set(
            {'status': 'dissolved', 'dissolvedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true),
          );
          await firestore.collection('partner_connections').doc(connectionId2).set(
            {'status': 'dissolved', 'dissolvedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true),
          );
        } catch (e) {
          debugPrint('Dissolve connection notice: $e');
        }
      }
    } catch (e) {
      debugPrint('Cloud unpair notice: $e');
    } finally {
      await _storageService.savePartner(null);
      await _storageService.savePartnerEntries({});

      // Revoke locally if not direct purchaser
      final localSettings = _storageService.getSettings();
      if (!localSettings.isDuoPass && !localSettings.isPremium) {
        final isThemeStillUnlocked = localSettings.isThemeUnlocked(localSettings.themeId);
        final updatedSettings = localSettings.copyWith(
          premiumGrantedByPartner: false,
          themeId: isThemeStillUnlocked ? localSettings.themeId : 'pastel_pink',
          themeIndex: isThemeStillUnlocked ? localSettings.themeIndex : 0,
        );
        await _storageService.saveSettings(updatedSettings);
      }
    }
  }

  /// Listen to real-time partner entries from Firestore (Read-Only)
  /// Privacy Guard: Never expose entries prior to the date of pairing
  Stream<Map<String, MoodEntry>> streamPartnerEntries(
    String partnerUid, {
    DateTime? pairedAt,
  }) {
    if (partnerUid.isEmpty) {
      return Stream.value({});
    }

    final pairingDateStr = pairedAt != null
        ? "${pairedAt.year}-${pairedAt.month.toString().padLeft(2, '0')}-${pairedAt.day.toString().padLeft(2, '0')}"
        : null;

    try {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(partnerUid)
          .collection('mood_entries')
          .where('deleted', isNotEqualTo: true)
          .snapshots()
          .map((snapshot) {
        final Map<String, MoodEntry> entries = {};
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final entry = MoodEntry.fromMap(data);
          if (!entry.deleted) {
            // Privacy filter: Only include entries on or after pairing date
            if (pairingDateStr == null || entry.date.compareTo(pairingDateStr) >= 0) {
              entries[entry.date] = entry;
            }
          }
        }
        // Update local partner cache
        _storageService.savePartnerEntries(entries);
        return entries;
      });
    } catch (e) {
      debugPrint('Error streaming partner entries: $e');
      final local = _storageService.getPartnerEntries();
      if (pairingDateStr != null) {
        local.removeWhere((date, _) => date.compareTo(pairingDateStr) < 0);
      }
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
          .asyncMap((doc) async {
        if (doc.exists && doc.data() != null && doc.data()!['partnerInfo'] != null) {
          final rawMap = doc.data()!['partnerInfo'] as Map<String, dynamic>;
          final partner = PartnerInfo.fromMap(rawMap);
          _storageService.savePartner(partner);
          return partner;
        }

        _storageService.savePartner(null);
        return null;
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
