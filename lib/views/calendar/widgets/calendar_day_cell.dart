import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final int count;
  final bool isUnavailable;
  final int unavailableCount;
  final bool isShaggingUnavailable;
  final bool isSelected;
  final bool isToday;
  final bool isOutside;

  const CalendarDayCell({
    super.key,
    required this.day,
    this.count = 0,
    this.isUnavailable = false,
    this.unavailableCount = 0,
    this.isShaggingUnavailable = false,
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

    Color backgroundColor = isUnavailable && !isOutside ? redTint : Colors.transparent;
    Color textColor = isOutside
        ? colorScheme.onSurface.withValues(alpha: 0.25)
        : (isUnavailable && !isSelected && !isToday
            ? const Color(0xFFC62828)
            : colorScheme.onSurface);

    BoxBorder? border = isUnavailable && !isOutside && !isSelected && !isToday
        ? Border.all(color: redColor.withValues(alpha: 0.35), width: 1.0)
        : null;

    List<BoxShadow> shadows = [];

    if (isSelected) {
      backgroundColor = isUnavailable
          ? Color.alphaBlend(redTint, colorScheme.primary.withValues(alpha: 0.16))
          : colorScheme.primary.withValues(alpha: 0.14);
      border = Border.all(color: colorScheme.primary, width: 2.0);
      shadows = [
        BoxShadow(
          color: colorScheme.primary.withValues(alpha: 0.18),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (isToday) {
      backgroundColor = isUnavailable
          ? Color.alphaBlend(redTint, colorScheme.secondary.withValues(alpha: 0.12))
          : colorScheme.secondary.withValues(alpha: 0.10);
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${day.day}',
                      style: GoogleFonts.fredoka(
                        fontSize: daySize,
                        fontWeight: isSelected || isToday
                            ? FontWeight.w700
                            : (isUnavailable ? FontWeight.w600 : FontWeight.w500),
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
              if (isShaggingUnavailable && !isOutside)
                Positioned(
                  top: 2,
                  right: 3,
                  child: Text(
                    '😢',
                    style: TextStyle(
                      fontSize: (cellHeight * 0.24).clamp(9.0, 13.0),
                      height: 1.0,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
