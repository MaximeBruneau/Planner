import 'package:flutter_test/flutter_test.dart';
import 'package:my_dairy/models/mood_entry.dart';
import 'package:my_dairy/models/partner_info.dart';
import 'package:my_dairy/providers/partner_provider.dart';

void main() {
  group('Stats & Duo Mood Distribution Suite Tests', () {
    test('Calculates individual percentages and most frequent mood', () {
      final entries = [
        MoodEntry(date: '2026-08-01', emoji: '🌸'),
        MoodEntry(date: '2026-08-02', emoji: '🌸'),
        MoodEntry(date: '2026-08-03', emoji: '🌸'),
        MoodEntry(date: '2026-08-04', emoji: '😊'),
      ];

      final counts = <String, int>{};
      for (final e in entries) {
        counts[e.emoji] = (counts[e.emoji] ?? 0) + 1;
      }

      expect(counts['🌸'], equals(3));
      expect(counts['😊'], equals(1));

      final total = entries.length;
      final pinkPercent = (counts['🌸']! / total) * 100;
      final smilePercent = (counts['😊']! / total) * 100;

      expect(pinkPercent, equals(75.0));
      expect(smilePercent, equals(25.0));
    });

    test('Calculates mutual vibe sync count correctly', () {
      final userEntries = [
        MoodEntry(date: '2026-08-10', emoji: '🌸'),
        MoodEntry(date: '2026-08-11', emoji: '✨'),
        MoodEntry(date: '2026-08-12', emoji: '😴'),
        MoodEntry(date: '2026-08-13', emoji: '💖'),
      ];

      final partnerEntries = {
        '2026-08-10': MoodEntry(date: '2026-08-10', emoji: '🌸'), // Match!
        '2026-08-11': MoodEntry(date: '2026-08-11', emoji: '😢'), // Different
        '2026-08-12': MoodEntry(date: '2026-08-12', emoji: '😴'), // Match!
        '2026-08-13': MoodEntry(date: '2026-08-13', emoji: '💖'), // Match!
      };

      int syncCount = 0;
      for (final u in userEntries) {
        final p = partnerEntries[u.date];
        if (p != null && !p.deleted && p.emoji == u.emoji) {
          syncCount++;
        }
      }

      expect(syncCount, equals(3));
    });

    test('PartnerState filters partner entries prior to pairedAt date in analytics', () {
      final pairingDate = DateTime(2026, 8, 15);
      final partnerInfo = PartnerInfo(
        uid: 'partner_99',
        displayName: 'Camille 🐰',
        email: 'camille@example.com',
        pairedAt: pairingDate,
      );

      final state = PartnerState(
        partnerInfo: partnerInfo,
        partnerEntries: {
          '2026-08-10': MoodEntry(date: '2026-08-10', emoji: '🌸'), // Prior -> filtered
          '2026-08-14': MoodEntry(date: '2026-08-14', emoji: '🌸'), // Prior -> filtered
          '2026-08-15': MoodEntry(date: '2026-08-15', emoji: '🐰'), // Same day -> kept
          '2026-08-16': MoodEntry(date: '2026-08-16', emoji: '✨'), // Post -> kept
        },
      );

      expect(state.getPartnerEntryForDate('2026-08-10'), isNull);
      expect(state.getPartnerEntryForDate('2026-08-14'), isNull);
      expect(state.getPartnerEntryForDate('2026-08-15'), isNotNull);
      expect(state.getPartnerEntryForDate('2026-08-16'), isNotNull);
      expect(state.filteredPartnerEntries.length, equals(2));
    });
  });
}
