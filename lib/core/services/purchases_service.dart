import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/emoji_pack.dart';
import '../../providers/mood_provider.dart';
import '../theme/theme_palettes.dart';
import 'storage_service.dart';



/// Product Identifiers Configuration for DuoVibe
class DuoVibeProducts {
  // Subscriptions
  static const String premiumMonthly = 'duovibe_premium_monthly';
  static const String premiumYearly = 'duovibe_premium_yearly'; // Star Offer (7-Day Trial)
  static const String duoPassYearly = 'duovibe_duopass_yearly'; // Pass Duo (2 Accounts)

  // Entitlements
  static const String entitlementPremium = 'duovibe_premium';
  static const String entitlementDuoPass = 'duo_pass';

  // Unit / Master Bundles
  static const String allThemesBundle = 'all_themes_pack';
  static const String allEmojiPacksBundle = 'all_emoji_packs_bundle';

  static String themeProductId(String themeId) => 'theme_$themeId';
  static String packProductId(String packId) => 'pack_$packId';
}

enum SubscriptionTier {
  monthly,
  yearlyWithTrial,
  duoPass,
}

class PurchasesService {
  final StorageService _storageService;

  PurchasesService(this._storageService);

  /// Initialize RevenueCat SDK if available / configure listeners
  Future<void> init({String? userId}) async {
    debugPrint('PurchasesService initialized for user: $userId');
    // If user is already signed in, check if partner granted Duo Pass
    if (userId != null && userId.isNotEmpty) {
      await checkPartnerGrantedPremium(currentUserId: userId);
    }
  }

  /// Purchase Premium Subscription (Monthly or Yearly with 7-day Trial)
  Future<bool> purchaseSubscription({
    required SubscriptionTier tier,
    String? userId,
    String? partnerId,
  }) async {
    try {
      final settings = _storageService.getSettings();
      final isDuo = tier == SubscriptionTier.duoPass;
      final expiryDate = DateTime.now().add(
        tier == SubscriptionTier.monthly
            ? const Duration(days: 30)
            : const Duration(days: 365),
      );

      final updatedSettings = settings.copyWith(
        isPremium: true,
        isDuoPass: isDuo,
        premiumExpiryDate: expiryDate,
      );

      await _storageService.saveSettings(updatedSettings);

      // Cloud sync to Firestore
      if (userId != null && userId.isNotEmpty) {
        try {
          final Map<String, dynamic> updateData = {
            'isPremium': true,
            'isDuoPass': isDuo,
            'premiumTier': tier.name,
            'premiumExpiryDate': expiryDate.toIso8601String(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .set(updateData, SetOptions(merge: true));

          // If Duo Pass, grant premium status to partner as well
          if (isDuo && partnerId != null && partnerId.isNotEmpty) {
            await syncDuoPassPartnerStatus(
              userId: userId,
              partnerId: partnerId,
              isActive: true,
              expiryDate: expiryDate,
            );
          }
        } catch (e) {
          debugPrint('Firestore sync after subscription purchase: $e');
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      return false;
    }
  }

  /// Purchase a single theme by ID (1,99 €)
  Future<bool> purchaseSingleTheme({
    required String themeId,
    String? userId,
  }) async {
    try {
      final settings = _storageService.getSettings();
      if (!settings.unlockedThemes.contains(themeId)) {
        final updatedThemes = List<String>.from(settings.unlockedThemes)..add(themeId);
        final updatedSettings = settings.copyWith(
          unlockedThemes: updatedThemes,
          themeId: themeId,
          themeIndex: AppPalettes.getIndexById(themeId),
        );
        await _storageService.saveSettings(updatedSettings);

        if (userId != null && userId.isNotEmpty) {
          try {
            await FirebaseFirestore.instance.collection('users').doc(userId).set({
              'unlockedThemes': updatedThemes,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } catch (e) {
            debugPrint('Cloud sync after single theme purchase: $e');
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error purchasing single theme: $e');
      return false;
    }
  }

  /// Purchase a single Emoji Pack by ID (0,99 €)
  Future<bool> purchaseSingleEmojiPack({
    required String packId,
    String? userId,
  }) async {
    try {
      final settings = _storageService.getSettings();
      if (!settings.unlockedEmojiPacks.contains(packId)) {
        final updatedPacks = List<String>.from(settings.unlockedEmojiPacks)..add(packId);
        final updatedSettings = settings.copyWith(
          unlockedEmojiPacks: updatedPacks,
        );
        await _storageService.saveSettings(updatedSettings);

        if (userId != null && userId.isNotEmpty) {
          try {
            await FirebaseFirestore.instance.collection('users').doc(userId).set({
              'unlockedEmojiPacks': updatedPacks,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } catch (e) {
            debugPrint('Cloud sync after single emoji pack purchase: $e');
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error purchasing single emoji pack: $e');
      return false;
    }
  }

  /// Purchase All Themes Pack (3,99 €)
  Future<bool> purchaseAllThemesPack({String? userId}) async {
    try {
      final allThemeIds = AppPalettes.list.map((p) => p.id).toList();
      final settings = _storageService.getSettings();
      final updatedSettings = settings.copyWith(
        unlockedThemes: allThemeIds,
      );
      await _storageService.saveSettings(updatedSettings);

      if (userId != null && userId.isNotEmpty) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(userId).set({
            'unlockedThemes': allThemeIds,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Cloud sync after all-themes purchase: $e');
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error purchasing all themes pack: $e');
      return false;
    }
  }

  /// Purchase All Emoji Packs Master Bundle (2,99 €)
  Future<bool> purchaseAllEmojiPacks({String? userId}) async {
    try {
      final allPackIds = EmojiPacks.list.map((p) => p.id).toList();
      final settings = _storageService.getSettings();
      final updatedSettings = settings.copyWith(
        unlockedEmojiPacks: allPackIds,
      );
      await _storageService.saveSettings(updatedSettings);

      if (userId != null && userId.isNotEmpty) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(userId).set({
            'unlockedEmojiPacks': allPackIds,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Cloud sync after all-emoji-packs purchase: $e');
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error purchasing all emoji packs: $e');
      return false;
    }
  }

  /// Restore all purchases (Subscriptions, Duo Pass, Themes, Emoji Packs)
  Future<Map<String, dynamic>> restorePurchases({
    String? userId,
    String? partnerId,
  }) async {
    try {
      final settings = _storageService.getSettings();
      var currentThemes = List<String>.from(settings.unlockedThemes);
      var currentEmojiPacks = List<String>.from(settings.unlockedEmojiPacks);
      bool isPremium = settings.isPremium;
      bool isDuoPass = settings.isDuoPass;
      bool premiumGrantedByPartner = settings.premiumGrantedByPartner;
      DateTime? expiry = settings.premiumExpiryDate;

      // Check Firestore if signed in
      if (userId != null && userId.isNotEmpty) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            final data = userDoc.data()!;
            if (data['isPremium'] == true) {
              isPremium = true;
            }
            if (data['isDuoPass'] == true) {
              isDuoPass = true;
            }
            if (data['premiumGrantedByPartner'] == true) {
              premiumGrantedByPartner = true;
            }
            if (data['premiumExpiryDate'] != null) {
              try {
                expiry = DateTime.parse(data['premiumExpiryDate'].toString());
              } catch (_) {}
            }

            final cloudThemes = data['unlockedThemes'] as List?;
            if (cloudThemes != null) {
              for (final t in cloudThemes) {
                final tStr = t.toString();
                if (!currentThemes.contains(tStr)) {
                  currentThemes.add(tStr);
                }
              }
            }

            final cloudEmojiPacks = data['unlockedEmojiPacks'] as List?;
            if (cloudEmojiPacks != null) {
              for (final p in cloudEmojiPacks) {
                final pStr = p.toString();
                if (!currentEmojiPacks.contains(pStr)) {
                  currentEmojiPacks.add(pStr);
                }
              }
            }
          }

          // Check if partner holds an active Duo Pass
          final partnerGranted = await checkPartnerGrantedPremium(currentUserId: userId);
          if (partnerGranted) {
            premiumGrantedByPartner = true;
          }
        } catch (e) {
          debugPrint('Cloud restore error: $e');
        }
      }

      if (!currentThemes.contains('pastel_pink')) {
        currentThemes.insert(0, 'pastel_pink');
      }
      if (!currentEmojiPacks.contains(EmojiPacks.defaultPackId)) {
        currentEmojiPacks.insert(0, EmojiPacks.defaultPackId);
      }

      final updated = settings.copyWith(
        unlockedThemes: currentThemes,
        unlockedEmojiPacks: currentEmojiPacks,
        isPremium: isPremium,
        isDuoPass: isDuoPass,
        premiumGrantedByPartner: premiumGrantedByPartner,
        premiumExpiryDate: expiry,
      );

      await _storageService.saveSettings(updated);

      return {
        'isPremium': updated.hasActivePremium,
        'themes': currentThemes,
        'emojiPacks': currentEmojiPacks,
      };
    } catch (e) {
      debugPrint('Restore purchases general error: $e');
      return {
        'isPremium': _storageService.getSettings().hasActivePremium,
        'themes': _storageService.getSettings().unlockedThemes,
        'emojiPacks': _storageService.getSettings().unlockedEmojiPacks,
      };
    }
  }

  /// Sync Duo Pass status to partner's account
  Future<void> syncDuoPassPartnerStatus({
    required String userId,
    required String partnerId,
    required bool isActive,
    DateTime? expiryDate,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(partnerId).set({
        'premiumGrantedByPartner': isActive,
        'premiumGrantedByUserId': userId,
        'premiumExpiryDate': expiryDate?.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Sync Duo Pass to partner error: $e');
    }
  }

  /// Stream real-time Duo Pass status for current user (watches both own doc and partner doc)
  Stream<bool> streamPartnerGrantedPremium({
    required String currentUserId,
    String? partnerId,
  }) {
    if (currentUserId.isEmpty) return Stream.value(false);

    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists || userDoc.data() == null) return false;
      final userData = userDoc.data()!;

      // 1. Check direct flag on current user document
      if (userData['premiumGrantedByPartner'] == true) {
        final expiryStr = userData['premiumExpiryDate'] as String?;
        if (expiryStr != null) {
          try {
            final expiry = DateTime.parse(expiryStr);
            if (expiry.isAfter(DateTime.now())) return true;
          } catch (_) {}
        } else {
          return true;
        }
      }

      // 2. Cross-check partner's document for active Duo Pass
      final effectivePartnerId = partnerId ?? (userData['partnerId'] as String?);
      if (effectivePartnerId != null && effectivePartnerId.isNotEmpty) {
        try {
          final partnerDoc =
              await firestore.collection('users').doc(effectivePartnerId).get();
          if (partnerDoc.exists && partnerDoc.data() != null) {
            final pData = partnerDoc.data()!;
            if (pData['isDuoPass'] == true) {
              final expiryStr = pData['premiumExpiryDate'] as String?;
              DateTime? expiry;
              if (expiryStr != null) {
                try {
                  expiry = DateTime.parse(expiryStr);
                } catch (_) {}
              }
              if (expiry == null || expiry.isAfter(DateTime.now())) {
                // Auto-sync status to current user's document as well
                await syncDuoPassPartnerStatus(
                  userId: effectivePartnerId,
                  partnerId: currentUserId,
                  isActive: true,
                  expiryDate: expiry,
                );
                return true;
              }
            }
          }
        } catch (e) {
          debugPrint('Cross-check partner Duo Pass notice: $e');
        }
      }

      return false;
    });
  }

  /// Check if the connected partner has activated a Duo Pass for this user
  Future<bool> checkPartnerGrantedPremium({
    required String currentUserId,
    String? partnerId,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('users').doc(currentUserId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['premiumGrantedByPartner'] == true) {
          final settings = _storageService.getSettings();
          final updated = settings.copyWith(premiumGrantedByPartner: true);
          await _storageService.saveSettings(updated);
          return true;
        }

        // Cross-check partner
        final effectivePartnerId = partnerId ?? (data['partnerId'] as String?);
        if (effectivePartnerId != null && effectivePartnerId.isNotEmpty) {
          final partnerDoc =
              await firestore.collection('users').doc(effectivePartnerId).get();
          if (partnerDoc.exists && partnerDoc.data() != null) {
            final pData = partnerDoc.data()!;
            if (pData['isDuoPass'] == true) {
              final expiryStr = pData['premiumExpiryDate'] as String?;
              DateTime? expiry;
              if (expiryStr != null) {
                try {
                  expiry = DateTime.parse(expiryStr);
                } catch (_) {}
              }
              final settings = _storageService.getSettings();
              final updated = settings.copyWith(
                premiumGrantedByPartner: true,
                premiumExpiryDate: expiry ?? settings.premiumExpiryDate,
              );
              await _storageService.saveSettings(updated);

              // Also persist back to user's doc
              await syncDuoPassPartnerStatus(
                userId: effectivePartnerId,
                partnerId: currentUserId,
                isActive: true,
                expiryDate: expiry,
              );
              return true;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Check partner granted premium error: $e');
    }
    return false;
  }
}

final purchasesServiceProvider = Provider<PurchasesService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return PurchasesService(storageService);
});
