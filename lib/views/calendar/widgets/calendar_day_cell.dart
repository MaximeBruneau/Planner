import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final int count;
  final bool isSelected;
  final bool isToday;
  final bool isOutside;

  const CalendarDayCell({
    super.key,
    required this.day,
    this.count = 0,
    this.isSelected = false,
    this.isToday = false,
    this.isOutside = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasItems = count > 0;

    Color backgroundColor = Colors.transparent;
    Color textColor = isOutside
        ? colorScheme.onSurface.withValues(alpha: 0.25)
        : colorScheme.onSurface;
    BoxBorder? border;
    List<BoxShadow> shadows = [];

    if (isSelected) {
      backgroundColor = colorScheme.primary.withValues(alpha: 0.14);
      border = Border.all(color: colorScheme.primary, width: 2.0);
      shadows = [
        BoxShadow(
          color: colorScheme.primary.withValues(alpha: 0.18),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (isToday) {
      backgroundColor = colorScheme.secondary.withValues(alpha: 0.10);
      border = Border.all(
        color: colorScheme.secondary,
        width: 1.5,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellHeight = constraints.maxHeight;
        final cellWidth = constraints.maxWidth;

        final double daySize = (cellHeight * 0.32).clamp(13.0, 18.0);
        final double hMargin = (cellWidth * 0.04).clamp(1.0, 3.5);
        final double vMargin = (cellHeight * 0.04).clamp(1.0, 3.5);
        final double radius = (cellHeight * 0.28).clamp(10.0, 18.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: EdgeInsets.symmetric(horizontal: hMargin, vertical: vMargin),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(radius),
            border: border,
            boxShadow: shadows,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${day.day}',
                  style: GoogleFonts.fredoka(
                    fontSize: daySize,
                    fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? colorScheme.primary
                        : (isToday
                            ? colorScheme.secondary
                            : textColor.withValues(alpha: isOutside ? 0.25 : 0.85)),
                  ),
                ),
                if (hasItems && !isOutside) ...[
                  const SizedBox(height: 3),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
