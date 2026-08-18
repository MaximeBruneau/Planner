import 'dart:math';
import '../../models/mood_entry.dart';
import '../theme/theme_palettes.dart';
import '../utils/date_utils_helper.dart';

class StreakService {
  /// Calculates personal streak: consecutive days with a logged mood entry.
  /// Stays active if logged today or yesterday. Drops to 0 if both are missed.
  static int calculatePersonalStreak(
    Map<String, MoodEntry> entries, [
    DateTime? referenceDate,
  ]) {
    if (entries.isEmpty) return 0;

    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayKey = DateUtilsHelper.formatYmd(today);
    final yesterdayKey = DateUtilsHelper.formatYmd(yesterday);

    final hasLoggedToday = entries.containsKey(todayKey) && !(entries[todayKey]!.deleted);
    final hasLoggedYesterday =
        entries.containsKey(yesterdayKey) && !(entries[yesterdayKey]!.deleted);

    // If neither today nor yesterday has a log, streak is broken -> 0
    if (!hasLoggedToday && !hasLoggedYesterday) {
      return 0;
    }

    int streak = 0;
    DateTime checkDay = hasLoggedToday ? today : yesterday;

    while (true) {
      final key = DateUtilsHelper.formatYmd(checkDay);
      final entry = entries[key];
      if (entry != null && !entry.deleted) {
        streak++;
        checkDay = checkDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Calculates duo flame: consecutive days where BOTH user and partner logged a mood entry on the same calendar day.
  /// Stays active if both logged today or both logged yesterday.
  static int calculateDuoFlames(
    Map<String, MoodEntry> userEntries,
    Map<String, MoodEntry> partnerEntries, [
    DateTime? referenceDate,
  ]) {
    if (userEntries.isEmpty || partnerEntries.isEmpty) return 0;

    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayKey = DateUtilsHelper.formatYmd(today);
    final yesterdayKey = DateUtilsHelper.formatYmd(yesterday);

    final userToday = userEntries[todayKey];
    final partnerToday = partnerEntries[todayKey];
    final bothLoggedToday = (userToday != null && !userToday.deleted) &&
        (partnerToday != null && !partnerToday.deleted);

    final userYesterday = userEntries[yesterdayKey];
    final partnerYesterday = partnerEntries[yesterdayKey];
    final bothLoggedYesterday = (userYesterday != null && !userYesterday.deleted) &&
        (partnerYesterday != null && !partnerYesterday.deleted);

    if (!bothLoggedToday && !bothLoggedYesterday) {
      return 0;
    }

    int flames = 0;
    DateTime checkDay = bothLoggedToday ? today : yesterday;

    while (true) {
      final key = DateUtilsHelper.formatYmd(checkDay);
      final uEntry = userEntries[key];
      final pEntry = partnerEntries[key];

      final isBothPresent = (uEntry != null && !uEntry.deleted) &&
          (pEntry != null && !pEntry.deleted);

      if (isBothPresent) {
        flames++;
        checkDay = checkDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return flames;
  }

  /// Check if 50-flame milestone can be claimed.
  /// Returns the themeId to unlock, 'all_unlocked' if all paid themes are already unlocked, or null if milestone not reached or already claimed.
  static String? checkAndClaim50FlameMilestone({
    required int duoFlames,
    required List<String> currentUnlockedThemes,
    required Map<String, bool> claimedMilestones,
    Random? random,
  }) {
    if (duoFlames < 50) return null;
    if (claimedMilestones['50'] == true) return null;

    final paidThemes = AppPalettes.paidThemeIds;
    final lockedThemes =
        paidThemes.where((id) => !currentUnlockedThemes.contains(id)).toList();

    if (lockedThemes.isEmpty) {
      return 'all_unlocked'; // Legendary Flame badge
    }

    final rand = random ?? Random();
    final selectedTheme = lockedThemes[rand.nextInt(lockedThemes.length)];
    return selectedTheme;
  }
}
