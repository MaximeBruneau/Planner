import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// A card displayed when there are no activities for a selected day.
/// Provides an option to pick a random idea.
class EmptyDayCard extends StatelessWidget {
  /// The date that is currently selected
  final DateTime selectedDay;

  /// The emoji representing the current theme
  final String themeEmoji;

  /// Callback when the random idea button is tapped
  final VoidCallback onRandomIdeaTap;

  const EmptyDayCard({
    super.key,
    required this.selectedDay,
    required this.themeEmoji,
    required this.onRandomIdeaTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        child: Center(
          child: Column(
            children: [
              Text(themeEmoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                "No ideas or plans yet",
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Type above to add the first plan for ${DateFormat('MMMM d').format(selectedDay)}!",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onRandomIdeaTap,
                icon: const Text("🎲", style: TextStyle(fontSize: 16)),
                label: Text(
                  "Pick an idea from the bank 💡",
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
