import 'package:flutter_test/flutter_test.dart';
import 'package:my_dairy/models/mood_entry.dart';
import 'package:my_dairy/models/app_settings.dart';
import 'package:my_dairy/models/app_user.dart';
import 'package:my_dairy/core/constants/default_emojis.dart';
import 'package:my_dairy/core/constants/notification_messages.dart';
import 'package:my_dairy/core/theme/theme_palettes.dart';

void main() {
  group('MoodEntry Model Tests', () {
    test('serialization and deserialization work correctly', () {
      final entry = MoodEntry(
        date: '2026-08-13',
        emoji: '🥑',
        note: 'Had a wonderful cozy day!',
        userId: 'user_123',
        deleted: false,
        syncStatus: 'synced',
      );

      final map = entry.toMap();
      expect(map['date'], equals('2026-08-13'));
      expect(map['emoji'], equals('🥑'));
      expect(map['note'], equals('Had a wonderful cozy day!'));
      expect(map['userId'], equals('user_123'));
      expect(map['deleted'], isFalse);
      expect(map['syncStatus'], equals('synced'));

      final reconstructed = MoodEntry.fromMap(map);
      expect(reconstructed.date, equals(entry.date));
      expect(reconstructed.emoji, equals(entry.emoji));
      expect(reconstructed.note, equals(entry.note));
      expect(reconstructed.userId, equals(entry.userId));
      expect(reconstructed.deleted, equals(entry.deleted));
    });

    test('json encoding and decoding works', () {
      final entry = MoodEntry(
        date: '2026-08-14',
        emoji: '🌿',
        note: 'Peaceful evening walk',
      );

      final jsonStr = entry.toJson();
      final decoded = MoodEntry.fromJson(jsonStr);

      expect(decoded.date, equals('2026-08-14'));
      expect(decoded.emoji, equals('🌿'));
      expect(decoded.note, equals('Peaceful evening walk'));
    });
  });

  group('AppUser Model Tests', () {
    test('AppUser serialization and deserialization with duo & theme fields', () {
      final user = AppUser(
        id: '12345',
        email: 'friend@example.com',
        displayName: 'Best Friend',
        photoUrl: 'https://example.com/avatar.png',
        partnerId: 'partner_999',
        unlockedThemes: ['pastel_pink', 'deep_ocean'],
        claimedFlameMilestones: {'50': true},
      );

      final jsonStr = user.toJson();
      final decoded = AppUser.fromJson(jsonStr);

      expect(decoded.id, equals('12345'));
      expect(decoded.email, equals('friend@example.com'));
      expect(decoded.displayName, equals('Best Friend'));
      expect(decoded.photoUrl, equals('https://example.com/avatar.png'));
      expect(decoded.partnerId, equals('partner_999'));
      expect(decoded.unlockedThemes, contains('pastel_pink'));
      expect(decoded.unlockedThemes, contains('deep_ocean'));
      expect(decoded.claimedFlameMilestones['50'], isTrue);
    });
  });

  group('AppSettings Model Tests', () {
    test('default settings initialization', () {
      final settings = AppSettings();
      expect(settings.themeId, equals('pastel_pink'));
      expect(settings.unlockedThemes, contains('pastel_pink'));
      expect(settings.customEmojis.length, equals(10));
      expect(settings.customEmojis.first, equals(DefaultEmojis.list.first));
      expect(settings.notificationsEnabled, isTrue);
    });

    test('copyWith updates settings properly', () {
      final settings = AppSettings();
      final updated = settings.copyWith(
        themeId: 'starry_night',
        unlockedThemes: ['pastel_pink', 'starry_night'],
        notificationsEnabled: false,
      );

      expect(updated.themeId, equals('starry_night'));
      expect(updated.unlockedThemes.length, equals(2));
      expect(updated.notificationsEnabled, isFalse);
      expect(updated.customEmojis.length, equals(10));
    });

    test('isThemeUnlocked returns true for free theme Pastel Pink', () {
      final settings = AppSettings();
      expect(settings.isThemeUnlocked('pastel_pink'), isTrue);
      expect(settings.isThemeUnlocked('starry_night'), isFalse);
    });
  });

  group('Theme Palettes & Notification Constants Tests', () {
    test('AppPalettes list has exactly 13 distinct color palettes', () {
      expect(AppPalettes.list.length, equals(13));
      final names = AppPalettes.list.map((p) => p.name).toSet();
      expect(names.length, equals(13));

      // Verify blue palettes exist with fish emojis
      final lightBlue =
          AppPalettes.list.firstWhere((p) => p.name == 'Light Blue');
      expect(lightBlue.emoji, equals('🐟'));

      final deepOcean =
          AppPalettes.list.firstWhere((p) => p.name == 'Deep Ocean');
      expect(deepOcean.emoji, equals('🐠'));

      final aquaLagoon =
          AppPalettes.list.firstWhere((p) => p.name == 'Aqua Lagoon');
      expect(aquaLagoon.emoji, equals('🐡'));
    });

    test('NotificationMessages list has 20 cute messages', () {
      expect(NotificationMessages.messages.length, equals(20));
      final randomMsg = NotificationMessages.getRandomMessage();
      expect(NotificationMessages.messages.contains(randomMsg), isTrue);
    });
  });
}
