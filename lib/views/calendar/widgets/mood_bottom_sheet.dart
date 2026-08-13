import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/mood_entry.dart';
import '../../../providers/mood_provider.dart';
import '../../../providers/settings_provider.dart';

class MoodBottomSheet extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final MoodEntry? existingEntry;

  const MoodBottomSheet({
    super.key,
    required this.selectedDate,
    this.existingEntry,
  });

  static Future<void> show(
    BuildContext context, {
    required DateTime selectedDate,
    MoodEntry? existingEntry,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: MoodBottomSheet(
          selectedDate: selectedDate,
          existingEntry: existingEntry,
        ),
      ),
    );
  }

  @override
  ConsumerState<MoodBottomSheet> createState() => _MoodBottomSheetState();
}

class _MoodBottomSheetState extends ConsumerState<MoodBottomSheet> {
  late String _selectedEmoji;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final customEmojis = ref.read(settingsProvider).customEmojis;
    _selectedEmoji = widget.existingEntry?.emoji ??
        (customEmojis.isNotEmpty ? customEmojis[0] : '😊');
    _noteController =
        TextEditingController(text: widget.existingEntry?.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final vibeEmojis = settings.customEmojis;

    final formattedDate = DateFormat('MMMM d').format(widget.selectedDate);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle pill
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Date Subtitle
            Text(
              formattedDate,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 4),

            // Title
            Text(
              "How's your vibe, friend? ✨",
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),

            // Emoji selector row / grid
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: vibeEmojis.map((emoji) {
                final isSelected = _selectedEmoji == emoji;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedEmoji = emoji;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.1),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Note label
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Add a little thought... 📝 (Optional)",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.9),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // TextField
            TextField(
              controller: _noteController,
              maxLines: 3,
              minLines: 2,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: "A quiet moment for yourself: How did today go? ✨",
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saveVibe,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.existingEntry == null
                          ? "Save My Vibe 🌻"
                          : "Update My Vibe 🌻",
                    ),
                  ],
                ),
              ),
            ),

            if (widget.existingEntry != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _deleteVibe,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.error,
                  size: 20,
                ),
                label: Text(
                  "Delete Entry",
                  style: TextStyle(color: colorScheme.error),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }

  void _saveVibe() {
    ref.read(moodProvider.notifier).setEntry(
          date: widget.selectedDate,
          emoji: _selectedEmoji,
          note: _noteController.text,
        );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Vibe saved for ${DateFormat('MMM d').format(widget.selectedDate)}! 🌸"),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _deleteVibe() {
    ref.read(moodProvider.notifier).deleteEntry(widget.selectedDate);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Entry removed"),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
