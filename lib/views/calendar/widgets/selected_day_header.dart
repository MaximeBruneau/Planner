import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// A header displaying the selected day and the count of activities.
class SelectedDayHeader extends StatelessWidget {
  /// The date that is currently selected
  final DateTime selectedDay;

  /// The number of activities scheduled for the selected day
  final int itemCount;

  const SelectedDayHeader({
    super.key,
    required this.selectedDay,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          DateFormat('EEEE, MMMM d').format(selectedDay),
          style: GoogleFonts.fredoka(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        if (itemCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "$itemCount item${itemCount > 1 ? 's' : ''}",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}
