import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../providers/mood_provider.dart';
import '../../../providers/settings_provider.dart';

class InlineMoodEditor extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const InlineMoodEditor({
    super.key,
    required this.selectedDate,
  });

  @override
  ConsumerState<InlineMoodEditor> createState() => _InlineMoodEditorState();
}

class _InlineMoodEditorState extends ConsumerState<InlineMoodEditor> {
  late String _selectedEmoji;
  late TextEditingController _noteController;
  DateTime? _lastDate;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void didUpdateWidget(covariant InlineMoodEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      _initData();
    }
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _initData() {
    _lastDate = widget.selectedDate;
    final entry = ref.read(moodProvider.notifier).getEntryForDate(widget.selectedDate);
    final customEmojis = ref.read(settingsProvider).customEmojis;

    _selectedEmoji = entry?.emoji ??
        (customEmojis.isNotEmpty ? customEmojis[0] : '😊');
    _noteController = TextEditingController(text: entry?.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool _isFutureDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final moodMap = ref.watch(moodProvider); // Rebuild when entries change
    final settings = ref.watch(settingsProvider);
    final vibeEmojis = settings.customEmojis;

    final entryKey = MoodNotifier.formatDateKey(widget.selectedDate);
    final existingEntry = moodMap[entryKey];

    // If entry changed externally or dates switched, refresh controller text if not editing
    if (existingEntry?.note != null && _noteController.text != existingEntry!.note) {
      if (_lastDate != widget.selectedDate) {
        _selectedEmoji = existingEntry.emoji;
        _noteController.text = existingEntry.note;
        _lastDate = widget.selectedDate;
      }
    }

    final formattedDate = DateFormat('EEEE, MMMM d').format(widget.selectedDate);
    final isFuture = _isFutureDate(widget.selectedDate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFuture
                          ? "Future Date 🔮"
                          : existingEntry != null
                              ? "Logged Vibe ✨"
                              : "How's your vibe today? ✨",
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                if (existingEntry != null && !isFuture)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      existingEntry.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (isFuture) ...[
              // Future date message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    const Text("⏳", style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "You can only log vibes for today or past dates. Check back on $formattedDate!",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Emoji Selector Row / Grid (10 active deck emojis)
              Wrap(
                spacing: 10,
                runSpacing: 10,
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
                        width: 48,
                        height: 48,
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
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Note Input Field
              TextField(
                controller: _noteController,
                maxLines: 3,
                minLines: 2,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: "Add a little thought... 📝 (Optional)",
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Save / Delete Action Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saveVibe,
                        child: Text(
                          existingEntry == null
                              ? "Save My Vibe 🌻"
                              : "Update My Vibe 🌻",
                        ),
                      ),
                    ),
                  ),
                  if (existingEntry != null) ...[
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: _deleteVibe,
                      tooltip: "Delete Entry",
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
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

    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "Vibe saved for ${DateFormat('MMM d').format(widget.selectedDate)}! 🌸"),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _deleteVibe() {
    ref.read(moodProvider.notifier).deleteEntry(widget.selectedDate);
    setState(() {
      _noteController.clear();
    });

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
