import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/iap_service.dart';
import '../core/services/storage_service.dart';
import '../core/theme/theme_palettes.dart';
import '../models/app_settings.dart';
import 'mood_provider.dart';
import 'streak_provider.dart';

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

  /// Restore purchases (themes & emoji packs)
  Future<Map<String, dynamic>> restorePurchases({String? userId}) async {
    final restored = await _iapService.restorePurchases(userId: userId);
    state = _storageService.getSettings();
    return restored;
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

  /// Toggle daily 9:00 PM reminder
  Future<void> toggleNotifications(bool enabled) async {
    final updated = state.copyWith(notificationsEnabled: enabled);
    state = updated;
    await _storageService.saveSettings(updated);
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
