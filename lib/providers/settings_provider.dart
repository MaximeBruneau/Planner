import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/iap_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/purchases_service.dart';
import '../core/services/storage_service.dart';
import '../core/theme/theme_palettes.dart';
import '../models/app_settings.dart';
import '../models/emoji_pack.dart';
import 'mood_provider.dart';


class SettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storageService;
  final IapService _iapService;

  SettingsNotifier(this._storageService, this._iapService)
      : super(_storageService.getSettings());

  /// Update theme by ID (e.g. 'pastel_pink', 'starry_night')
  Future<void> updateThemeById(String themeId) async {
    if (!state.isThemeUnlocked(themeId)) {
      return; // Theme is locked, do not apply
    }
    final index = AppPalettes.getIndexById(themeId);
    final updated = state.copyWith(
      themeId: themeId,
      themeIndex: index,
    );
    state = updated;
    await _storageService.saveSettings(updated);
  }

  /// Update theme by numeric index
  Future<void> updateTheme(int index) async {
    final palette = AppPalettes.getByIndex(index);
    await updateThemeById(palette.id);
  }

  /// Purchase and unlock a single theme
  Future<bool> purchaseAndApplyTheme(String themeId, {String? userId}) async {
    final success = await _iapService.purchaseTheme(
      themeId: themeId,
      userId: userId,
    );
    if (success) {
      state = _storageService.getSettings();
    }
    return success;
  }

  /// Purchase and unlock All Themes pack
  Future<bool> purchaseAllThemesPack({String? userId}) async {
    final success = await _iapService.purchaseAllThemesPack(userId: userId);
    if (success) {
      state = _storageService.getSettings();
    }
    return success;
  }

  /// Purchase and unlock a single Emoji Pack ($0.99)
  Future<bool> purchaseEmojiPack(String packId, {String? userId}) async {
    final success = await _iapService.purchaseEmojiPack(
      packId: packId,
      userId: userId,
    );
    if (success) {
      state = _storageService.getSettings();
    }
    return success;
  }

  /// Purchase and unlock All Emoji Packs master bundle ($2.99)
  Future<bool> purchaseAllEmojiPacks({String? userId}) async {
    final success = await _iapService.purchaseAllEmojiPacks(userId: userId);
    if (success) {
      state = _storageService.getSettings();
    }
    return success;
  }

  /// Purchase Premium Subscription (Monthly, Yearly with Trial, or Duo Pass)
  Future<bool> purchaseSubscription({
    required SubscriptionTier tier,
    String? userId,
    String? partnerId,
  }) async {
    final success = await _iapService.purchaseSubscription(
      tier: tier,
      userId: userId,
      partnerId: partnerId,
    );
    if (success) {
      state = _storageService.getSettings();
    }
    return success;
  }

  /// Restore purchases (themes, emoji packs & premium subscriptions)
  Future<Map<String, dynamic>> restorePurchases({
    String? userId,
    String? partnerId,
  }) async {
    final restored = await _iapService.restorePurchases(
      userId: userId,
      partnerId: partnerId,
    );
    state = _storageService.getSettings();
    return restored;
  }

  /// Reset all purchases and lock all premium themes & emoji packs (Sandbox test mode)
  Future<void> resetPurchasesToFree({String? userId}) async {
    final updated = state.copyWith(
      unlockedThemes: ['pastel_pink'],
      unlockedEmojiPacks: [EmojiPacks.defaultPackId],
      isPremium: false,
      isDuoPass: false,
      premiumGrantedByPartner: false,
      themeId: 'pastel_pink',
      themeIndex: 0,
    );
    state = updated;
    await _storageService.saveSettings(updated);

    if (userId != null && userId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'unlockedThemes': ['pastel_pink'],
          'unlockedEmojiPacks': [EmojiPacks.defaultPackId],
          'isPremium': false,
          'isDuoPass': false,
          'premiumGrantedByPartner': false,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }


  /// Update a specific emoji slot in the 10 custom emojis
  Future<void> updateEmoji(int index, String emoji) async {
    final list = List<String>.from(state.customEmojis);
    if (index >= 0 && index < list.length) {
      list[index] = emoji;
    } else if (list.length < 10) {
      list.add(emoji);
    }
    await updateCustomEmojis(list);
  }

  /// Update favorite 10 emojis
  Future<void> updateCustomEmojis(List<String> emojis) async {
    final updated = state.copyWith(customEmojis: emojis);
    state = updated;
    await _storageService.saveSettings(updated);
  }

  /// Toggle daily reminder
  Future<void> toggleNotifications(bool enabled) async {
    final updated = state.copyWith(notificationsEnabled: enabled);
    state = updated;
    await _storageService.saveSettings(updated);

    if (enabled) {
      final parts = updated.notificationTime.split(':');
      final hour = int.tryParse(parts[0]) ?? 21;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      NotificationService().scheduleDailyReminder(
        hasEntryToday: () {
          final entries = _storageService.getAllEntries();
          final now = DateTime.now();
          final todayKey =
              "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
          return entries.containsKey(todayKey) && !entries[todayKey]!.deleted;
        },
        hour: hour,
        minute: minute,
      );
    } else {
      NotificationService().cancelAll();
    }
  }

  /// Update daily reminder notification time (e.g. "20:30")
  Future<void> updateNotificationTime(String time) async {
    final updated = state.copyWith(notificationTime: time);
    state = updated;
    await _storageService.saveSettings(updated);

    if (updated.notificationsEnabled) {
      final parts = time.split(':');
      final hour = int.tryParse(parts[0]) ?? 21;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      NotificationService().scheduleDailyReminder(
        hasEntryToday: () {
          final entries = _storageService.getAllEntries();
          final now = DateTime.now();
          final todayKey =
              "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
          return entries.containsKey(todayKey) && !entries[todayKey]!.deleted;
        },
        hour: hour,
        minute: minute,
      );
    }
  }



  /// Check if a theme is unlocked
  bool isThemeUnlocked(String themeId) {
    return state.isThemeUnlocked(themeId);
  }

  /// Check if an emoji pack is unlocked
  bool isEmojiPackUnlocked(String packId) {
    return state.isEmojiPackUnlocked(packId);
  }

  /// Check if a specific emoji is unlocked
  bool isEmojiUnlocked(String emoji) {
    return state.isEmojiUnlocked(emoji);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final iapService = ref.watch(iapServiceProvider);
  return SettingsNotifier(storageService, iapService);
});
