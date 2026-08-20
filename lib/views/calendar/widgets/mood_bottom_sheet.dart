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
      useSafeArea: false,
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
    final screenHeight = MediaQuery.of(context).size.height;

    final formattedDate =
        DateFormat('EEEE, MMMM d').format(widget.selectedDate);

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          )
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Date Subtitle
            Text(
              formattedDate,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),

            // Title
            Text(
              "How's your vibe today? ✨",
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 22),

            // Selected Emoji Spotlight
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedEmoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Selected Vibe",
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Emoji selector row / grid (10 active deck emojis)
            Wrap(
              spacing: 12,
              runSpacing: 12,
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
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.08),
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 28),
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
                child: Text(
                  widget.existingEntry == null
                      ? "Save My Vibe 🌻"
                      : "Update My Vibe 🌻",
                  style: const TextStyle(fontSize: 16),
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
        content: Text(
            "Vibe saved for ${DateFormat('MMM d').format(widget.selectedDate)}! 🌸"),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
