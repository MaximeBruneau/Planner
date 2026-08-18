import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_dairy/core/services/streak_service.dart';
import 'package:my_dairy/core/theme/theme_palettes.dart';
import 'package:my_dairy/models/mood_entry.dart';

void main() {
  group('Personal Streak Algorithm Tests', () {
    final refDate = DateTime(2026, 8, 18); // Reference Tuesday

    test('returns 0 when entries map is empty', () {
      final streak = StreakService.calculatePersonalStreak({}, refDate);
      expect(streak, 0);
    });

    test('counts streak when logged today', () {
      final entries = {
        '2026-08-18': MoodEntry(date: '2026-08-18', emoji: '🌸'),
        '2026-08-17': MoodEntry(date: '2026-08-17', emoji: '😊'),
        '2026-08-16': MoodEntry(date: '2026-08-16', emoji: '🎉'),
      };
      final streak = StreakService.calculatePersonalStreak(entries, refDate);
      expect(streak, 3);
    });

    test('counts streak when not logged today but logged yesterday (grace period)', () {
      final entries = {
        '2026-08-17': MoodEntry(date: '2026-08-17', emoji: '😊'),
        '2026-08-16': MoodEntry(date: '2026-08-16', emoji: '🎉'),
        '2026-08-15': MoodEntry(date: '2026-08-15', emoji: '🌿'),
      };
      final streak = StreakService.calculatePersonalStreak(entries, refDate);
      expect(streak, 3);
    });

    test('resets streak to 0 if both today and yesterday are missed', () {
      final entries = {
        '2026-08-16': MoodEntry(date: '2026-08-16', emoji: '🎉'),
        '2026-08-15': MoodEntry(date: '2026-08-15', emoji: '🌿'),
      };
      final streak = StreakService.calculatePersonalStreak(entries, refDate);
      expect(streak, 0);
    });

    test('stops counting streak when there is a gap in previous days', () {
      final entries = {
        '2026-08-18': MoodEntry(date: '2026-08-18', emoji: '🌸'),
        '2026-08-17': MoodEntry(date: '2026-08-17', emoji: '😊'),
        // Gap on 2026-08-16
        '2026-08-15': MoodEntry(date: '2026-08-15', emoji: '🌿'),
      };
      final streak = StreakService.calculatePersonalStreak(entries, refDate);
      expect(streak, 2);
    });

    test('ignores deleted entries in streak calculation', () {
      final entries = {
        '2026-08-18': MoodEntry(date: '2026-08-18', emoji: '🌸'),
        '2026-08-17': MoodEntry(date: '2026-08-17', emoji: '😊', deleted: true),
        '2026-08-16': MoodEntry(date: '2026-08-16', emoji: '🎉'),
      };
      final streak = StreakService.calculatePersonalStreak(entries, refDate);
      expect(streak, 1);
    });
  });

  group('Duo Flame 🔥 Algorithm Tests', () {
    final refDate = DateTime(2026, 8, 18);

    test('returns 0 when either partner has no entries', () {
      final uEntries = {'2026-08-18': MoodEntry(date: '2026-08-18', emoji: '🌸')};
      final pEntries = <String, MoodEntry>{};
      final flames = StreakService.calculateDuoFlames(uEntries, pEntries, refDate);
      expect(flames, 0);
    });

    test('increments duo flames when both log on the same calendar day', () {
      final uEntries = {
        '2026-08-18': MoodEntry(date: '2026-08-18', emoji: '🌸'),
        '2026-08-17': MoodEntry(date: '2026-08-17', emoji: '😊'),
        '2026-08-16': MoodEntry(date: '2026-08-16', emoji: '🎉'),
      };
      final pEntries = {
        '2026-08-18': MoodEntry(date: '2026-08-18', emoji: '🐰'),
        '2026-08-17': MoodEntry(date: '2026-08-17', emoji: '✨'),
        '2026-08-16': MoodEntry(date: '2026-08-16', emoji: '🌻'),
      };
      final flames = StreakService.calculateDuoFlames(uEntries, pEntries, refDate);
      expect(flames, 3);
    });

    test('resets duo flames to 0 if one partner misses a day in between', () {
      final uEntries = {
        '2026-08-18': MoodEntry(date: '2026-08-18', emoji: '🌸'),
        '2026-08-17': MoodEntry(date: '2026-08-17', emoji: '😊'),
        '2026-08-16': MoodEntry(date: '2026-08-16', emoji: '🎉'),
      };
      final pEntries = {
        '2026-08-18': MoodEntry(date: '2026-08-18', emoji: '🐰'),
        // Partner missed 2026-08-17
        '2026-08-16': MoodEntry(date: '2026-08-16', emoji: '🌻'),
      };
      final flames = StreakService.calculateDuoFlames(uEntries, pEntries, refDate);
      expect(flames, 1);
    });
  });

  group('50-Flame Milestone Random Theme Unlock Tests', () {
    test('returns null when duo flames < 50', () {
      final unlock = StreakService.checkAndClaim50FlameMilestone(
        duoFlames: 49,
        currentUnlockedThemes: ['pastel_pink'],
        claimedMilestones: {},
      );
      expect(unlock, isNull);
    });

    test('returns null when 50 milestone was already claimed', () {
      final unlock = StreakService.checkAndClaim50FlameMilestone(
        duoFlames: 50,
        currentUnlockedThemes: ['pastel_pink'],
        claimedMilestones: {'50': true},
      );
      expect(unlock, isNull);
    });

    test('unlocks a random paid theme when reaching 50 duo flames', () {
      final unlock = StreakService.checkAndClaim50FlameMilestone(
        duoFlames: 50,
        currentUnlockedThemes: ['pastel_pink'],
        claimedMilestones: {},
        random: Random(42), // deterministic seed
      );
      expect(unlock, isNotNull);
      expect(unlock, isNot('pastel_pink'));
      expect(AppPalettes.paidThemeIds.contains(unlock), isTrue);
    });

    test('returns all_unlocked when all paid themes are already owned', () {
      final allThemes = AppPalettes.list.map((p) => p.id).toList();
      final unlock = StreakService.checkAndClaim50FlameMilestone(
        duoFlames: 55,
        currentUnlockedThemes: allThemes,
        claimedMilestones: {},
      );
      expect(unlock, equals('all_unlocked'));
    });
  });
}
