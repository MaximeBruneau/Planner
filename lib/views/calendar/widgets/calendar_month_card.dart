import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'calendar_day_cell.dart';

/// Monthly calendar card wrapping the TableCalendar with custom styling and cell indicators.
class CalendarMonthCard extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final double adaptiveRowHeight;
  final double adaptiveDaysOfWeekHeight;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final void Function(DateTime focusedDay) onPageChanged;
  final int Function(DateTime day) getCountForDate;
  final bool Function(DateTime day)? isUnavailableForDate;
  final int Function(DateTime day)? getUnavailableCountForDate;
  final bool Function(DateTime day)? isShaggingAvailableForDate;

  const CalendarMonthCard({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.adaptiveRowHeight,
    required this.adaptiveDaysOfWeekHeight,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.getCountForDate,
    this.isUnavailableForDate,
    this.getUnavailableCountForDate,
    this.isShaggingAvailableForDate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarFormat: CalendarFormat.month,
          rowHeight: adaptiveRowHeight,
          daysOfWeekHeight: adaptiveDaysOfWeekHeight,
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            headerPadding: const EdgeInsets.symmetric(vertical: 4.0),
            titleTextStyle: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: GoogleFonts.fredoka(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            weekendStyle: GoogleFonts.fredoka(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final count = getCountForDate(day);
              final isUnavailable = isUnavailableForDate?.call(day) ?? false;
              final unavailableCount = getUnavailableCountForDate?.call(day) ?? 0;
              final isShaggingAvailable = isShaggingAvailableForDate?.call(day) ?? false;
              return CalendarDayCell(
                day: day,
                count: count,
                isUnavailable: isUnavailable,
                unavailableCount: unavailableCount,
                isShaggingAvailable: isShaggingAvailable,
              );
            },
            selectedBuilder: (context, day, focusedDay) {
              final count = getCountForDate(day);
              final isUnavailable = isUnavailableForDate?.call(day) ?? false;
              final unavailableCount = getUnavailableCountForDate?.call(day) ?? 0;
              final isShaggingAvailable = isShaggingAvailableForDate?.call(day) ?? false;
              return CalendarDayCell(
                day: day,
                count: count,
                isUnavailable: isUnavailable,
                unavailableCount: unavailableCount,
                isShaggingAvailable: isShaggingAvailable,
                isSelected: true,
              );
            },
            todayBuilder: (context, day, focusedDay) {
              final count = getCountForDate(day);
              final isUnavailable = isUnavailableForDate?.call(day) ?? false;
              final unavailableCount = getUnavailableCountForDate?.call(day) ?? 0;
              final isShaggingAvailable = isShaggingAvailableForDate?.call(day) ?? false;
              return CalendarDayCell(
                day: day,
                count: count,
                isUnavailable: isUnavailable,
                unavailableCount: unavailableCount,
                isShaggingAvailable: isShaggingAvailable,
                isToday: true,
                isSelected: isSameDay(selectedDay, day),
              );
            },
            outsideBuilder: (context, day, focusedDay) {
              return CalendarDayCell(
                day: day,
                isOutside: true,
              );
            },
          ),
          onDaySelected: onDaySelected,
          onPageChanged: onPageChanged,
        ),
      ),
    );
  }
}
