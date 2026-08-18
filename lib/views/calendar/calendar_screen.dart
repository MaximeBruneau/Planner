import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/mood_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/partner_provider.dart';
import '../../providers/streak_provider.dart';
import '../../core/theme/theme_palettes.dart';
import '../../core/utils/date_utils_helper.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';
import 'widgets/calendar_day_cell.dart';
import 'widgets/logged_vibe_summary_card.dart';
import 'widgets/mood_bottom_sheet.dart';
import 'widgets/partner_pairing_card.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  bool _hasAutoPrompted = false;
  int _selectedTabIndex = 0; // 0: My Vibe, 1: FT Vibe

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;

    // Smart Auto-Prompt on launch for user's own vibe
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSmartAutoPrompt();
    });
  }

  void _checkSmartAutoPrompt() {
    if (_hasAutoPrompted || _selectedTabIndex != 0) return;
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
    return DateUtilsHelper.isFutureDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);
    final partnerState = ref.watch(partnerProvider);
    final partnerNotifier = ref.read(partnerProvider.notifier);
    final streakState = ref.watch(streakProvider);

    final palette = AppPalettes.getById(settings.themeId);
    final isFuture = _isFutureDate(_selectedDay);

    final selectedUserEntry =
        ref.read(moodProvider.notifier).getEntryForDate(_selectedDay);
    final selectedPartnerEntry =
        partnerNotifier.getPartnerEntryForDate(_selectedDay);

    final partnerName =
        partnerState.partnerInfo?.displayName.split(' ')[0] ?? 'FT';

    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    final double adaptiveRowHeight;
    final double adaptiveDaysOfWeekHeight;
    final double titleFontSize;
    final double chevronIconSize;

    if (screenHeight < 680 || screenWidth < 360) {
      adaptiveRowHeight = 48.0;
      adaptiveDaysOfWeekHeight = 24.0;
      titleFontSize = 18.0;
      chevronIconSize = 22.0;
    } else if (screenHeight > 880) {
      adaptiveRowHeight = 60.0;
      adaptiveDaysOfWeekHeight = 32.0;
      titleFontSize = 21.0;
      chevronIconSize = 28.0;
    } else {
      adaptiveRowHeight = 56.0;
      adaptiveDaysOfWeekHeight = 28.0;
      titleFontSize = 20.0;
      chevronIconSize = 26.0;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedTabIndex == 0 ? "My Vibe " : "FT Vibe ",
                  style: GoogleFonts.fredoka(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  _selectedTabIndex == 0 ? palette.emoji : "🐰",
                  style: const TextStyle(fontSize: 19),
                ),
              ],
            ),
            const SizedBox(height: 2),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StatsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("🔥", style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  Text(
                    "${streakState.personalStreak} streak",
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  if (partnerState.isPaired) ...[
                    Text(
                      " • 🔥🔥 ${streakState.duoFlames}/50",
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ] else ...[
                    Text(
                      " • Connect FT 🐰",
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _selectedTabIndex == 0
                ? "Switch to Partner Calendar 🐰"
                : "Switch to My Calendar 🌸",
            icon: Icon(
              _selectedTabIndex == 0
                  ? Icons.swap_horiz_rounded
                  : Icons.person_outline_rounded,
              color: colorScheme.primary,
            ),
            onPressed: () {
              setState(() {
                _selectedTabIndex = _selectedTabIndex == 0 ? 1 : 0;
              });
            },
          ),
          IconButton(
            tooltip: "Vibe Analytics 📊",
            icon: Icon(
              Icons.bar_chart_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
          IconButton(
            tooltip: "Settings ⚙️",
            icon: Icon(
              Icons.settings_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                backgroundImage:
                    authState.user?.photoUrl != null && authState.user!.photoUrl!.isNotEmpty
                        ? NetworkImage(authState.user!.photoUrl!)
                        : null,
                child: authState.user?.photoUrl == null || authState.user!.photoUrl!.isEmpty
                    ? (authState.user != null
                        ? Text(
                            authState.user!.displayName.isNotEmpty
                                ? authState.user!.displayName[0].toUpperCase()
                                : "U",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          )
                        : Icon(Icons.person_rounded, size: 18, color: colorScheme.primary))
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            child: Column(
              children: [
                // Read-Only Badge when in Partner Tab
                if (_selectedTabIndex == 1 && partnerState.isPaired) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colorScheme.secondary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Read-Only Calendar • $partnerName's live vibes",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // TAB 1: PARTNER NOT PAIRED YET
                if (_selectedTabIndex == 1 && !partnerState.isPaired) ...[
                  const PartnerPairingCard(),
                ]
                // TAB 0 (USER) OR TAB 1 (PAIRED PARTNER)
                else ...[
                  // Monthly Adaptive Calendar View
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 10.0),
                      child: TableCalendar(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2035, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          startingDayOfWeek: StartingDayOfWeek.sunday,
                          calendarFormat: CalendarFormat.month,
                          rowHeight: adaptiveRowHeight,
                          daysOfWeekHeight: adaptiveDaysOfWeekHeight,
                          headerStyle: HeaderStyle(
                            titleCentered: true,
                            formatButtonVisible: false,
                            headerPadding:
                                const EdgeInsets.only(top: 4.0, bottom: 8.0),
                            leftChevronPadding: const EdgeInsets.all(6.0),
                            rightChevronPadding: const EdgeInsets.all(6.0),
                            leftChevronMargin: EdgeInsets.zero,
                            rightChevronMargin: EdgeInsets.zero,
                            titleTextStyle: GoogleFonts.fredoka(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                            leftChevronIcon: Icon(
                              Icons.chevron_left_rounded,
                              color: colorScheme.primary,
                              size: chevronIconSize,
                            ),
                            rightChevronIcon: Icon(
                              Icons.chevron_right_rounded,
                              color: colorScheme.primary,
                              size: chevronIconSize,
                            ),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: GoogleFonts.fredoka(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                            weekendStyle: GoogleFonts.fredoka(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                          calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          final entry = _selectedTabIndex == 0
                              ? ref
                                  .read(moodProvider.notifier)
                                  .getEntryForDate(day)
                              : partnerNotifier.getPartnerEntryForDate(day);
                          return CalendarDayCell(
                            day: day,
                            emoji: entry?.emoji,
                            isOutside: false,
                          );
                        },
                        selectedBuilder: (context, day, focusedDay) {
                          final entry = _selectedTabIndex == 0
                              ? ref
                                  .read(moodProvider.notifier)
                                  .getEntryForDate(day)
                              : partnerNotifier.getPartnerEntryForDate(day);
                          return CalendarDayCell(
                            day: day,
                            emoji: entry?.emoji,
                            isSelected: true,
                          );
                        },
                        todayBuilder: (context, day, focusedDay) {
                          final entry = _selectedTabIndex == 0
                              ? ref
                                  .read(moodProvider.notifier)
                                  .getEntryForDate(day)
                              : partnerNotifier.getPartnerEntryForDate(day);
                          return CalendarDayCell(
                            day: day,
                            emoji: entry?.emoji,
                            isToday: true,
                            isSelected: isSameDay(_selectedDay, day),
                          );
                        },
                        outsideBuilder: (context, day, focusedDay) {
                          final entry = _selectedTabIndex == 0
                              ? ref
                                  .read(moodProvider.notifier)
                                  .getEntryForDate(day)
                              : partnerNotifier.getPartnerEntryForDate(day);
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

                        if (_selectedTabIndex == 0) {
                          final entry = ref
                              .read(moodProvider.notifier)
                              .getEntryForDate(selectedDay);

                          if (entry == null && !_isFutureDate(selectedDay)) {
                            MoodBottomSheet.show(
                              context,
                              selectedDate: selectedDay,
                              existingEntry: null,
                            );
                          }
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

                // Bottom Section below Calendar based on Active Tab
                if (_selectedTabIndex == 0) ...[
                  // --- USER TAB CONTENT ---
                  if (isFuture) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 14.0),
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
                                    "Future Date 🔮",
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
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (selectedUserEntry != null) ...[
                    LoggedVibeSummaryCard(
                      selectedDate: _selectedDay,
                      entry: selectedUserEntry,
                    ),
                  ] else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14.0, vertical: 12.0),
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
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.6),
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
                ] else ...[
                  // --- FT VIBE TAB CONTENT (PAIRED) ---
                  if (isFuture) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 14.0),
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
                                    "Future Date 🔮",
                                    style: GoogleFonts.fredoka(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    "No entry expected for future days.",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (selectedPartnerEntry != null) ...[
                    LoggedVibeSummaryCard(
                      selectedDate: _selectedDay,
                      entry: selectedPartnerEntry,
                      isReadOnly: true,
                      readOnlyBadgeTitle: "$partnerName's Vibe 🐰 🔒",
                    ),
                  ] else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 14.0),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text("🐰", style: TextStyle(fontSize: 20)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "No vibe logged yet",
                                    style: GoogleFonts.fredoka(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    "$partnerName has not logged a mood for ${DateFormat('MMMM d').format(_selectedDay)}.",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}
}
