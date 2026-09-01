import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final int count;
  final bool isUnavailable;
  final int unavailableCount;
  final bool isShaggingAvailable;
  final bool isSelected;
  final bool isToday;
  final bool isOutside;

  const CalendarDayCell({
    super.key,
    required this.day,
    this.count = 0,
    this.isUnavailable = false,
    this.unavailableCount = 0,
    this.isShaggingAvailable = false,
    this.isSelected = false,
    this.isToday = false,
    this.isOutside = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasItems = count > 0;

    const redColor = Color(0xFFE53935);
    final redTint = redColor.withValues(alpha: isSelected ? 0.24 : 0.16);

    const greenColor = Color(0xFF43A047);
    final greenTint = greenColor.withValues(alpha: isSelected ? 0.24 : 0.16);

    // Priority: Red (unavailability) takes priority over Green (shaging tool)
    final bool showRed = isUnavailable;
    final bool showGreen = !isUnavailable && isShaggingAvailable;

    Color backgroundColor = Colors.transparent;
    if (!isOutside) {
      if (showRed) {
        backgroundColor = redTint;
      } else if (showGreen) {
        backgroundColor = greenTint;
      }
    }

    Color textColor = isOutside
        ? colorScheme.onSurface.withValues(alpha: 0.25)
        : (showRed && !isSelected && !isToday
            ? const Color(0xFFC62828)
            : (showGreen && !isSelected && !isToday
                ? const Color(0xFF2E7D32)
                : colorScheme.onSurface));

    BoxBorder? border = (!isOutside && !isSelected && !isToday)
        ? (showRed
            ? Border.all(color: redColor.withValues(alpha: 0.35), width: 1.0)
            : (showGreen
                ? Border.all(color: greenColor.withValues(alpha: 0.35), width: 1.0)
                : null))
        : null;

    List<BoxShadow> shadows = [];

    if (isSelected) {
      backgroundColor = showRed
          ? Color.alphaBlend(redTint, colorScheme.primary.withValues(alpha: 0.16))
          : (showGreen
              ? Color.alphaBlend(greenTint, colorScheme.primary.withValues(alpha: 0.16))
              : colorScheme.primary.withValues(alpha: 0.14));
      border = Border.all(color: colorScheme.primary, width: 2.0);
      shadows = [
        BoxShadow(
          color: colorScheme.primary.withValues(alpha: 0.18),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (isToday) {
      backgroundColor = showRed
          ? Color.alphaBlend(redTint, colorScheme.secondary.withValues(alpha: 0.12))
          : (showGreen
              ? Color.alphaBlend(greenTint, colorScheme.secondary.withValues(alpha: 0.12))
              : colorScheme.secondary.withValues(alpha: 0.10));
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
                    fontWeight: isSelected || isToday ? FontWeight.w700 : (isUnavailable ? FontWeight.w600 : FontWeight.w500),
                    color: isSelected
                        ? colorScheme.primary
                        : (isToday
                            ? colorScheme.secondary
                            : textColor.withValues(alpha: isOutside ? 0.25 : 0.9)),
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
