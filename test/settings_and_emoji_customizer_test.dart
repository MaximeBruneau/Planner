import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_dairy/models/app_settings.dart';
import 'package:my_dairy/core/services/storage_service.dart';
import 'package:my_dairy/core/services/purchases_service.dart';
import 'package:my_dairy/core/services/iap_service.dart';
import 'package:my_dairy/providers/settings_provider.dart';

void main() {
  group('Settings & Emoji Customizer Tests', () {
    test('Default AppSettings initialized with Pastel Pink and 21:00 reminder', () {
      final settings = AppSettings();
      expect(settings.themeId, equals('pastel_pink'));
      expect(settings.notificationsEnabled, isTrue);
      expect(settings.notificationTime, equals('21:00'));
      expect(settings.isDuoPass, isFalse);
    });

    test('Customizing mood emoji updates specific index properly', () {
      final settings = AppSettings();
      expect(settings.customEmojis.isNotEmpty, isTrue);
      expect(settings.customEmojis[0], equals('😄'));

      final updated = settings.copyWith(
        customEmojis: ['🐰', '🌸', '✨', '☕', '🌧️', '🌙'],
      );

      expect(updated.customEmojis[0], equals('🐰'));
      expect(updated.customEmojis[1], equals('🌸'));
      expect(updated.customEmojis.length, equals(6));
    });

    test('Updating notification time persists correctly via SettingsNotifier', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();
      final purchases = PurchasesService(storage);
      final iap = IapService(storage, purchases);

      final notifier = SettingsNotifier(storage, iap);
      expect(notifier.state.notificationTime, equals('21:00'));

      await notifier.updateNotificationTime('19:45');
      expect(notifier.state.notificationTime, equals('19:45'));

      final saved = storage.getSettings();
      expect(saved.notificationTime, equals('19:45'));
    });

    test('Toggling notifications on and off persists in storage', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();
      final purchases = PurchasesService(storage);
      final iap = IapService(storage, purchases);

      final notifier = SettingsNotifier(storage, iap);
      expect(notifier.state.notificationsEnabled, isTrue);

      await notifier.toggleNotifications(false);
      expect(notifier.state.notificationsEnabled, isFalse);

      final saved = storage.getSettings();
      expect(saved.notificationsEnabled, isFalse);
    });

    test('Customizing mood emoji updates active 10-slot deck properly via SettingsNotifier', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();
      final purchases = PurchasesService(storage);
      final iap = IapService(storage, purchases);

      final notifier = SettingsNotifier(storage, iap);
      expect(notifier.state.customEmojis.length, equals(10));

      // Update slot 1 (index 0) and slot 10 (index 9) with emojis from the 20 starter pack
      await notifier.updateEmoji(0, '🚀');
      await notifier.updateEmoji(9, '✨');

      expect(notifier.state.customEmojis[0], equals('🚀'));
      expect(notifier.state.customEmojis[9], equals('✨'));
      expect(notifier.state.customEmojis.length, equals(10));

      final saved = storage.getSettings();
      expect(saved.customEmojis[0], equals('🚀'));
      expect(saved.customEmojis[9], equals('✨'));
    });

    test('canUseCustomKeyboardEmojis is true when isPremium or hasAllEmojiPacks', () {
      final freeSettings = AppSettings();
      expect(freeSettings.canUseCustomKeyboardEmojis, isFalse);

      final premiumSettings = AppSettings(isPremium: true);
      expect(premiumSettings.canUseCustomKeyboardEmojis, isTrue);

      final allPacksSettings = AppSettings(
        unlockedEmojiPacks: [
          'default_pack',
          'cute_animals',
          'food_treats',
          'vibes_moods',
          'nature_chill',
          'gaming_geek',
          'duo_love',
        ],
      );
      expect(allPacksSettings.hasAllEmojiPacks, isTrue);
      expect(allPacksSettings.canUseCustomKeyboardEmojis, isTrue);
    });

    test('Changing theme updates themeId and persists in storage', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();
      final purchases = PurchasesService(storage);
      final iap = IapService(storage, purchases);

      final notifier = SettingsNotifier(storage, iap);
      expect(notifier.state.themeId, equals('pastel_pink'));

      // Pastel Pink is free by default so update succeeds
      await notifier.updateThemeById('pastel_pink');
      expect(notifier.state.themeId, equals('pastel_pink'));

      final saved = storage.getSettings();
      expect(saved.themeId, equals('pastel_pink'));
    });
  });
}
