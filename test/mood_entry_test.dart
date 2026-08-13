import 'package:flutter_test/flutter_test.dart';
import 'package:my_dairy/models/mood_entry.dart';
import 'package:my_dairy/models/app_settings.dart';
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
      );

      final map = entry.toMap();
      expect(map['date'], equals('2026-08-13'));
      expect(map['emoji'], equals('🥑'));
      expect(map['note'], equals('Had a wonderful cozy day!'));

      final reconstructed = MoodEntry.fromMap(map);
      expect(reconstructed.date, equals(entry.date));
      expect(reconstructed.emoji, equals(entry.emoji));
      expect(reconstructed.note, equals(entry.note));
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

  group('AppSettings Model Tests', () {
    test('default settings initialization', () {
      final settings = AppSettings();
      expect(settings.themeIndex, equals(0));
      expect(settings.customEmojis.length, equals(10));
      expect(settings.customEmojis.first, equals(DefaultEmojis.list.first));
      expect(settings.notificationsEnabled, isTrue);
    });

    test('copyWith updates settings properly', () {
      final settings = AppSettings();
      final updated = settings.copyWith(
        themeIndex: 2,
        notificationsEnabled: false,
      );

      expect(updated.themeIndex, equals(2));
      expect(updated.notificationsEnabled, isFalse);
      expect(updated.customEmojis.length, equals(10));
    });
  });

  group('Theme Palettes & Notification Constants Tests', () {
    test('AppPalettes list has 10 distinct color palettes', () {
      expect(AppPalettes.list.length, equals(10));
      final names = AppPalettes.list.map((p) => p.name).toSet();
      expect(names.length, equals(10));
    });

    test('NotificationMessages list has 20 cute messages', () {
      expect(NotificationMessages.messages.length, equals(20));
      final randomMsg = NotificationMessages.getRandomMessage();
      expect(NotificationMessages.messages.contains(randomMsg), isTrue);
    });
  });
}
