import 'package:intl/intl.dart';

class DateUtilsHelper {
  static final DateFormat _ymdFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _shortDateFormat = DateFormat('MMM d');
  static final DateFormat _fullDateFormat = DateFormat('EEEE, MMMM d');

  /// Formats date to 'yyyy-MM-dd' string
  static String formatYmd(DateTime date) {
    return _ymdFormat.format(date);
  }

  /// Parses 'yyyy-MM-dd' string to DateTime
  static DateTime? parseYmd(String dateStr) {
    try {
      return _ymdFormat.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  /// Returns true if date is strictly in the future (after today)
  static bool isFutureDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isAfter(today);
  }

  /// Returns true if two dates are on the same calendar day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Formats date to 'MMMM yyyy' (e.g. August 2026)
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Formats date to 'MMM d' (e.g. Aug 18)
  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }

  /// Formats date to 'EEEE, MMMM d' (e.g. Tuesday, August 18)
  static String formatFullDate(DateTime date) {
    return _fullDateFormat.format(date);
  }

  /// Resilient parser for DateTime supporting Firestore Timestamps, strings, ints, and DateTimes
  static DateTime parseDateTime(dynamic value, [DateTime? fallback]) {
    final defaultFallback = fallback ?? DateTime.now();
    if (value == null) return defaultFallback;
    if (value is DateTime) return value;

    // Handle Firestore Timestamp object (has toDate() method)
    try {
      if (value.runtimeType.toString().contains('Timestamp')) {
        final toDateMethod = (value as dynamic).toDate;
        if (toDateMethod != null) {
          final res = toDateMethod();
          if (res is DateTime) return res;
        }
      }
    } catch (_) {}

    // Handle int (timestamp in millis or seconds)
    if (value is int) {
      if (value < 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    // Handle String
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;

      // Match Firestore string representation e.g. "Timestamp(seconds=1787062680, nanoseconds=757000000)"
      final match = RegExp(r'seconds=(\d+)').firstMatch(value);
      if (match != null) {
        final seconds = int.tryParse(match.group(1)!);
        if (seconds != null) {
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      }
    }

    return defaultFallback;
  }
}
