import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/notification_service.dart';
import '../core/services/storage_service.dart';
import '../core/theme/theme_palettes.dart';
import '../models/app_settings.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storageService;
  final NotificationService _notificationService;

  SettingsNotifier(this._storageService, this._notificationService)
      : super(_storageService.getSettings());

  /// Update theme by ID (all 13 themes are free)
  Future<void> updateThemeById(String themeId) async {
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

  /// Toggle group activity change notifications
  Future<void> toggleGroupActivityNotifications(bool enabled) async {
    final updated = state.copyWith(groupActivityNotifications: enabled);
    state = updated;
    await _storageService.saveSettings(updated);
  }

  /// Toggle general notifications
  Future<void> toggleNotifications(bool enabled) async {
    final updated = state.copyWith(notificationsEnabled: enabled);
    state = updated;
    await _storageService.saveSettings(updated);

    if (!enabled) {
      _notificationService.cancelAll();
    }
  }

  /// Update notification time
  Future<void> updateNotificationTime(String time) async {
    final updated = state.copyWith(notificationTime: time);
    state = updated;
    await _storageService.saveSettings(updated);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final notificationService = NotificationService();
  return SettingsNotifier(storageService, notificationService);
});
