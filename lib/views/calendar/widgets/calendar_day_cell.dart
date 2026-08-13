import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final String? emoji;
  final bool isSelected;
  final bool isToday;
  final bool isOutside;

  const CalendarDayCell({
    super.key,
    required this.day,
    this.emoji,
    this.isSelected = false,
    this.isToday = false,
    this.isOutside = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color backgroundColor = Colors.transparent;
    Color textColor = isOutside
        ? colorScheme.onSurface.withValues(alpha: 0.3)
        : colorScheme.onSurface;
    BoxBorder? border;

    if (isSelected) {
      backgroundColor = colorScheme.primaryContainer;
      border = Border.all(color: colorScheme.primary, width: 2);
    } else if (isToday) {
      backgroundColor = colorScheme.secondary.withValues(alpha: 0.2);
      border = Border.all(
        color: colorScheme.secondary,
        width: 1.5,
      );
    }

    return Container(
      margin: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16.0),
        border: border,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: GoogleFonts.fredoka(
              fontSize: 13,
              fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          if (emoji != null && emoji!.isNotEmpty)
            Text(
              emoji!,
              style: const TextStyle(fontSize: 18),
            )
          else
            const SizedBox(height: 18),
        ],
      ),
    );
  }
}
