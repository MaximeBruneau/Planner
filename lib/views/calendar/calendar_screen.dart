import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/mood_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/theme_palettes.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';
import 'widgets/calendar_day_cell.dart';
import 'widgets/logged_vibe_summary_card.dart';
import 'widgets/mood_bottom_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  bool _hasAutoPrompted = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;

    // Smart Auto-Prompt on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSmartAutoPrompt();
    });
  }

  void _checkSmartAutoPrompt() {
    if (_hasAutoPrompted) return;
    _hasAutoPrompted = true;

    final moodNotifier = ref.read(moodProvider.notifier);
    final today = DateTime.now();
    final hasEntry = moodNotifier.hasEntryForDate(today);

    if (!hasEntry && mounted) {
      MoodBottomSheet.show(
        context,
        selectedDate: today,
        existingEntry: null,
      );
    }
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
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);

    final paletteIndex = (settings.themeIndex >= 0 && settings.themeIndex < AppPalettes.list.length)
        ? settings.themeIndex
        : 0;
    final palette = AppPalettes.list[paletteIndex];

    final isFuture = _isFutureDate(_selectedDay);
    final selectedEntry = ref.read(moodProvider.notifier).getEntryForDate(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "My Vibe ",
              style: GoogleFonts.fredoka(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              palette.emoji,
              style: const TextStyle(fontSize: 21),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: "Vibe Stats",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: "Settings",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0, left: 4.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage: authState.user?.photoUrl != null
                    ? NetworkImage(authState.user!.photoUrl!)
                    : null,
                child: authState.user?.photoUrl == null
                    ? Text(
                        authState.user != null
                            ? (authState.user!.displayName.isNotEmpty
                                ? authState.user!.displayName[0].toUpperCase()
                                : 'U')
                            : '👤',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
          child: Column(
            children: [
              // Monthly Compact Calendar View
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2035, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    startingDayOfWeek: StartingDayOfWeek.sunday,
                    calendarFormat: CalendarFormat.month,
                    rowHeight: 42,
                    daysOfWeekHeight: 22,
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      headerPadding: const EdgeInsets.symmetric(vertical: 2.0),
                      leftChevronPadding: const EdgeInsets.all(4.0),
                      rightChevronPadding: const EdgeInsets.all(4.0),
                      leftChevronMargin: EdgeInsets.zero,
                      rightChevronMargin: EdgeInsets.zero,
                      titleTextStyle: GoogleFonts.fredoka(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      weekendStyle: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        final entry = ref
                            .read(moodProvider.notifier)
                            .getEntryForDate(day);
                        return CalendarDayCell(
                          day: day,
                          emoji: entry?.emoji,
                          isOutside: false,
                        );
                      },
                      selectedBuilder: (context, day, focusedDay) {
                        final entry = ref
                            .read(moodProvider.notifier)
                            .getEntryForDate(day);
                        return CalendarDayCell(
                          day: day,
                          emoji: entry?.emoji,
                          isSelected: true,
                        );
                      },
                      todayBuilder: (context, day, focusedDay) {
                        final entry = ref
                            .read(moodProvider.notifier)
                            .getEntryForDate(day);
                        return CalendarDayCell(
                          day: day,
                          emoji: entry?.emoji,
                          isToday: true,
                          isSelected: isSameDay(_selectedDay, day),
                        );
                      },
                      outsideBuilder: (context, day, focusedDay) {
                        final entry = ref
                            .read(moodProvider.notifier)
                            .getEntryForDate(day);
                        return CalendarDayCell(
                          day: day,
                          emoji: entry?.emoji,
                          isOutside: true,
                        );
                      },
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });

                      final entry = ref
                          .read(moodProvider.notifier)
                          .getEntryForDate(selectedDay);

                      // If day is NOT filled and NOT in future -> open bottom sheet modal over calendar!
                      if (entry == null && !_isFutureDate(selectedDay)) {
                        MoodBottomSheet.show(
                          context,
                          selectedDate: selectedDay,
                          existingEntry: null,
                        );
                      }
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Bottom Section below Calendar based on Selected Date state
              if (isFuture) ...[
                // Future Date Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    child: Row(
                      children: [
                        const Text("🔮", style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE, MMMM d').format(_selectedDay),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Future Date",
                                style: GoogleFonts.fredoka(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                "Vibe logging is not available for future days.",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (selectedEntry != null) ...[
                // Logged Date Card (Below calendar with summary text + pencil edit icon ✏️)
                LoggedVibeSummaryCard(
                  selectedDate: _selectedDay,
                  entry: selectedEntry,
                ),
              ] else ...[
                // Unlogged Date Prompt Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              palette.emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "No vibe logged yet 🌸",
                                style: GoogleFonts.fredoka(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMM d').format(_selectedDay) ==
                                        DateFormat('MMM d').format(DateTime.now())
                                    ? "Tap to log today's vibe"
                                    : "Tap to log vibe for ${DateFormat('MMM d').format(_selectedDay)}",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            MoodBottomSheet.show(
                              context,
                              selectedDate: _selectedDay,
                              existingEntry: null,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text("Log Vibe 🌸"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
