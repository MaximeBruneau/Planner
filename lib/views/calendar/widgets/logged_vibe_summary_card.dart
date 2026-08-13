import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/mood_entry.dart';
import 'mood_bottom_sheet.dart';

class LoggedVibeSummaryCard extends ConsumerWidget {
  final DateTime selectedDate;
  final MoodEntry entry;

  const LoggedVibeSummaryCard({
    super.key,
    required this.selectedDate,
    required this.entry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formattedDate = DateFormat('EEEE, MMMM d').format(selectedDate);
    final hasNote = entry.note.trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Emoji Badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Vibe Logged ✨",
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                // Pencil Edit Button ✏️
                IconButton.filledTonal(
                  onPressed: () {
                    MoodBottomSheet.show(
                      context,
                      selectedDate: selectedDate,
                      existingEntry: entry,
                    );
                  },
                  tooltip: "Edit Vibe ✏️",
                  icon: const Icon(
                    Icons.edit_rounded,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Note Summary Text Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasNote ? entry.note : "No note written for this day.",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      height: 1.4,
                      color: hasNote
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.4),
                      fontStyle: hasNote ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
