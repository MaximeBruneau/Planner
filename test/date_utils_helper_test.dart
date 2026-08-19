import 'package:flutter_test/flutter_test.dart';
import 'package:my_dairy/core/utils/date_utils_helper.dart';

void main() {
  group('DateUtilsHelper Robust Parsing & Formatting Tests', () {
    test('formatYmd and parseYmd are bijective', () {
      final date = DateTime(2026, 8, 19);
      final formatted = DateUtilsHelper.formatYmd(date);
      expect(formatted, equals('2026-08-19'));

      final parsed = DateUtilsHelper.parseYmd(formatted);
      expect(parsed, isNotNull);
      expect(parsed?.year, equals(2026));
      expect(parsed?.month, equals(8));
      expect(parsed?.day, equals(19));
    });

    test('parseYmd returns null for malformed string', () {
      expect(DateUtilsHelper.parseYmd('invalid-date'), isNull);
      expect(DateUtilsHelper.parseYmd(''), isNull);
    });

    test('isFutureDate correctly identifies future vs past vs today', () {
      final now = DateTime.now();
      final past = now.subtract(const Duration(days: 2));
      final future = now.add(const Duration(days: 2));
      final today = DateTime(now.year, now.month, now.day);

      expect(DateUtilsHelper.isFutureDate(past), isFalse);
      expect(DateUtilsHelper.isFutureDate(today), isFalse);
      expect(DateUtilsHelper.isFutureDate(future), isTrue);
    });

    test('isSameDay matches same calendar dates irrespective of hour/minute', () {
      final a = DateTime(2026, 8, 19, 8, 30);
      final b = DateTime(2026, 8, 19, 23, 59);
      final c = DateTime(2026, 8, 20, 0, 1);

      expect(DateUtilsHelper.isSameDay(a, b), isTrue);
      expect(DateUtilsHelper.isSameDay(a, c), isFalse);
    });

    test('parseDateTime handles DateTime instance directly', () {
      final now = DateTime(2026, 8, 19, 15, 30);
      expect(DateUtilsHelper.parseDateTime(now), equals(now));
    });

    test('parseDateTime handles ISO-8601 string', () {
      final result = DateUtilsHelper.parseDateTime('2026-08-19T15:30:00.000Z');
      expect(result.year, equals(2026));
      expect(result.month, equals(8));
      expect(result.day, equals(19));
    });

    test('parseDateTime handles integer milliseconds & seconds', () {
      final millis = 1787062680000; // milliseconds
      final seconds = 1787062680; // seconds

      final resMillis = DateUtilsHelper.parseDateTime(millis);
      final resSeconds = DateUtilsHelper.parseDateTime(seconds);

      expect(resMillis.year, equals(resSeconds.year));
      expect(resMillis.month, equals(resSeconds.month));
      expect(resMillis.day, equals(resSeconds.day));
    });

    test('parseDateTime handles Firestore Timestamp string representation', () {
      const firestoreStr = 'Timestamp(seconds=1787062680, nanoseconds=757000000)';
      final result = DateUtilsHelper.parseDateTime(firestoreStr);
      expect(result.year, equals(2026));
    });

    test('parseDateTime returns fallback when input is null or unparseable', () {
      final fallback = DateTime(2025, 1, 1);
      expect(DateUtilsHelper.parseDateTime(null, fallback), equals(fallback));
      expect(DateUtilsHelper.parseDateTime('unparseable string', fallback), equals(fallback));
    });

    test('formatMonthYear, formatShortDate, and formatFullDate output correctly', () {
      final date = DateTime(2026, 8, 19);
      expect(DateUtilsHelper.formatMonthYear(date), equals('August 2026'));
      expect(DateUtilsHelper.formatShortDate(date), equals('Aug 19'));
      expect(DateUtilsHelper.formatFullDate(date), contains('August 19'));
    });
  });
}
