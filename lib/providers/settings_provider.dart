import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../core/services/storage_service.dart';
import '../core/services/notification_service.dart';
import 'mood_provider.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storageService;

  SettingsNotifier(this._storageService) : super(AppSettings()) {
    loadSettings();
  }

  void loadSettings() {
    state = _storageService.getSettings();
  }

  Future<void> updateTheme(int index) async {
    final updated = state.copyWith(themeIndex: index);
    state = updated;
    await _storageService.saveSettings(updated);
  }

  Future<void> updateEmoji(int slotIndex, String newEmoji) async {
    if (slotIndex < 0 || slotIndex >= 10) return;
    final currentList = List<String>.from(state.customEmojis);
    currentList[slotIndex] = newEmoji;

    final updated = state.copyWith(customEmojis: currentList);
    state = updated;
    await _storageService.saveSettings(updated);
  }

  Future<void> updateCustomEmojis(List<String> newEmojis) async {
    if (newEmojis.length != 10) return;
    final updated = state.copyWith(customEmojis: List<String>.from(newEmojis));
    state = updated;
    await _storageService.saveSettings(updated);
  }

  Future<void> toggleNotifications(bool enabled) async {
    final updated = state.copyWith(notificationsEnabled: enabled);
    state = updated;
    await _storageService.saveSettings(updated);

    if (!enabled) {
      await NotificationService().cancelAll();
    }
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SettingsNotifier(storage);
});
