import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/emoji_pack.dart';
import '../theme/theme_palettes.dart';
import 'storage_service.dart';
import 'streak_service.dart';

class IapService {
  final StorageService _storageService;

  IapService(this._storageService);

  /// Purchase a single theme by ID
  Future<bool> purchaseTheme({
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

        // Sync to cloud if user is signed in
        if (userId != null && userId.isNotEmpty) {
          try {
            await FirebaseFirestore.instance.collection('users').doc(userId).set({
              'unlockedThemes': updatedThemes,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } catch (e) {
            debugPrint('Cloud sync after theme purchase notice: $e');
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error purchasing theme: $e');
      return false;
    }
  }

  /// Purchase "All Themes Pack" to unlock all 12 paid themes at once
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
          debugPrint('Cloud sync after all-themes purchase notice: $e');
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error purchasing all themes pack: $e');
      return false;
    }
  }

  /// Purchase a single emoji pack by ID ($0.99)
  Future<bool> purchaseEmojiPack({
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
            debugPrint('Cloud sync after emoji pack purchase notice: $e');
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error purchasing emoji pack: $e');
      return false;
    }
  }

  /// Purchase "All Emoji Packs" master bundle ($2.99)
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
          debugPrint('Cloud sync after all-emoji-packs purchase notice: $e');
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error purchasing all emoji packs: $e');
      return false;
    }
  }

  /// Restore purchases (themes & emoji packs)
  Future<Map<String, dynamic>> restorePurchases({String? userId}) async {
    try {
      final settings = _storageService.getSettings();
      var currentThemes = List<String>.from(settings.unlockedThemes);
      var currentEmojiPacks = List<String>.from(settings.unlockedEmojiPacks);

      // If user is connected to cloud, fetch from Firestore
      if (userId != null && userId.isNotEmpty) {
        try {
          final doc =
              await FirebaseFirestore.instance.collection('users').doc(userId).get();
          if (doc.exists && doc.data() != null) {
            final cloudThemes = doc.data()!['unlockedThemes'] as List?;
            if (cloudThemes != null) {
              for (final t in cloudThemes) {
                final tStr = t.toString();
                if (!currentThemes.contains(tStr)) {
                  currentThemes.add(tStr);
                }
              }
            }
            final cloudEmojiPacks = doc.data()!['unlockedEmojiPacks'] as List?;
            if (cloudEmojiPacks != null) {
              for (final p in cloudEmojiPacks) {
                final pStr = p.toString();
                if (!currentEmojiPacks.contains(pStr)) {
                  currentEmojiPacks.add(pStr);
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Cloud fetch during restore purchases notice: $e');
        }
      }

      if (!currentThemes.contains('pastel_pink')) {
        currentThemes.insert(0, 'pastel_pink');
      }
      if (!currentEmojiPacks.contains(EmojiPacks.defaultPackId)) {
        currentEmojiPacks.insert(0, EmojiPacks.defaultPackId);
      }

      await _storageService.saveSettings(
        settings.copyWith(
          unlockedThemes: currentThemes,
          unlockedEmojiPacks: currentEmojiPacks,
        ),
      );

      return {
        'themes': currentThemes,
        'emojiPacks': currentEmojiPacks,
      };
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return {
        'themes': _storageService.getSettings().unlockedThemes,
        'emojiPacks': _storageService.getSettings().unlockedEmojiPacks,
      };
    }
  }

  /// Claim random theme unlock on reaching 50 duo flames
  Future<String?> claim50FlameMilestone({
    required int duoFlames,
    String? userId,
  }) async {
    final settings = _storageService.getSettings();
    final unlockedThemes = settings.unlockedThemes;
    final claimedMilestones = settings.claimedFlameMilestones;

    final result = StreakService.checkAndClaim50FlameMilestone(
      duoFlames: duoFlames,
      currentUnlockedThemes: unlockedThemes,
      claimedMilestones: claimedMilestones,
    );

    if (result == null) return null;

    final updatedMilestones = Map<String, bool>.from(claimedMilestones)..['50'] = true;
    List<String> updatedThemes = List<String>.from(unlockedThemes);

    if (result != 'all_unlocked') {
      if (!updatedThemes.contains(result)) {
        updatedThemes.add(result);
      }
    }

    final updatedSettings = settings.copyWith(
      unlockedThemes: updatedThemes,
      claimedFlameMilestones: updatedMilestones,
    );
    await _storageService.saveSettings(updatedSettings);

    // Sync milestone claim to Firestore
    if (userId != null && userId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'unlockedThemes': updatedThemes,
          'claimedFlameMilestones': updatedMilestones,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Cloud sync milestone claim notice: $e');
      }
    }

    return result;
  }
}
