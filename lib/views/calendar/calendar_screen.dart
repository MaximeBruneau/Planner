import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/plan_provider.dart';
import '../../providers/space_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/theme_palettes.dart';
import '../settings/settings_screen.dart';
import 'widgets/calendar_day_cell.dart';
import 'widgets/space_management_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  final TextEditingController _itemInputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;
  }

  @override
  void dispose() {
    _itemInputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _submitItem() {
    final text = _itemInputController.text.trim();
    if (text.isEmpty) return;

    ref.read(planProvider.notifier).addItem(
          text: text,
          date: _selectedDay,
        );

    _itemInputController.clear();
    _inputFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id ?? '';
    final spaceState = ref.watch(spaceProvider);
    final planState = ref.watch(planProvider);
    final planNotifier = ref.read(planProvider.notifier);

    final palette = AppPalettes.getById(settings.themeId);
    final currentSpace = spaceState.currentSpace;

    // Plans/ideas for selected day
    final dayItems = planNotifier.getActivitiesForDate(_selectedDay);

    final screenSize = MediaQuery.sizeOf(context);
    final screenHeight = screenSize.height;

    final double adaptiveRowHeight = screenHeight > 850 ? 54.0 : (screenHeight < 680 ? 44.0 : 48.0);
    final double adaptiveDaysOfWeekHeight = screenHeight > 850 ? 26.0 : 22.0;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: InkWell(
          onTap: () => SpaceManagementSheet.show(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        currentSpace?.name ?? "Super Planner 🗓️",
                        style: GoogleFonts.fredoka(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: colorScheme.primary),
                  ],
                ),
                if (currentSpace != null) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          currentSpace.code,
                          style: GoogleFonts.fredoka(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "• ${currentSpace.memberCount} member${currentSpace.memberCount > 1 ? 's' : ''}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          // Jump to Today
          IconButton(
            tooltip: "Today",
            icon: const Icon(Icons.today_rounded),
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _focusedDay = now;
                _selectedDay = now;
              });
            },
          ),
          // Invite / Group Share
          IconButton(
            tooltip: "Group & Invite Code",
            icon: const Icon(Icons.group_outlined),
            onPressed: () => SpaceManagementSheet.show(context),
          ),
          // Settings
          IconButton(
            tooltip: "Settings",
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            children: [
              // In-app live notification banner (e.g. "Alex added an idea for Saturday")
              if (planState.lastInAppNotice != null) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text("🔔", style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          planState.lastInAppNotice!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => planNotifier.clearNotice(),
                      ),
                    ],
                  ),
                ),
              ],

              // Expanded Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Monthly Calendar Card
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TableCalendar(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2035, 12, 31),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            startingDayOfWeek: StartingDayOfWeek.monday,
                            calendarFormat: CalendarFormat.month,
                            rowHeight: adaptiveRowHeight,
                            daysOfWeekHeight: adaptiveDaysOfWeekHeight,
                            headerStyle: HeaderStyle(
                              titleCentered: true,
                              formatButtonVisible: false,
                              headerPadding: const EdgeInsets.symmetric(vertical: 4.0),
                              titleTextStyle: GoogleFonts.fredoka(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              leftChevronIcon: Icon(
                                Icons.chevron_left_rounded,
                                color: colorScheme.primary,
                                size: 24,
                              ),
                              rightChevronIcon: Icon(
                                Icons.chevron_right_rounded,
                                color: colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            daysOfWeekStyle: DaysOfWeekStyle(
                              weekdayStyle: GoogleFonts.fredoka(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              weekendStyle: GoogleFonts.fredoka(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary.withValues(alpha: 0.8),
                              ),
                            ),
                            calendarBuilders: CalendarBuilders(
                              defaultBuilder: (context, day, focusedDay) {
                                final count = planNotifier.getCountForDate(day);
                                return CalendarDayCell(
                                  day: day,
                                  count: count,
                                );
                              },
                              selectedBuilder: (context, day, focusedDay) {
                                final count = planNotifier.getCountForDate(day);
                                return CalendarDayCell(
                                  day: day,
                                  count: count,
                                  isSelected: true,
                                );
                              },
                              todayBuilder: (context, day, focusedDay) {
                                final count = planNotifier.getCountForDate(day);
                                return CalendarDayCell(
                                  day: day,
                                  count: count,
                                  isToday: true,
                                  isSelected: isSameDay(_selectedDay, day),
                                );
                              },
                              outsideBuilder: (context, day, focusedDay) {
                                return CalendarDayCell(
                                  day: day,
                                  isOutside: true,
                                );
                              },
                            ),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            onPageChanged: (focusedDay) {
                              setState(() {
                                _focusedDay = focusedDay;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Selected Day Header (1 Date = 1 List)
                      Row(
                        children: [
                          Text(
                            DateFormat('EEEE, MMMM d').format(_selectedDay),
                            style: GoogleFonts.fredoka(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          if (dayItems.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${dayItems.length} item${dayItems.length > 1 ? 's' : ''}",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Inline Add Input Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Text("💡", style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _itemInputController,
                                focusNode: _inputFocusNode,
                                decoration: InputDecoration(
                                  hintText: "Add an idea or plan for ${DateFormat('EEEE').format(_selectedDay)}...",
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onSubmitted: (_) => _submitItem(),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _submitItem,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text("Post"),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // The 1 List for this Selected Date
                      if (dayItems.isEmpty) ...[
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                            child: Center(
                              child: Column(
                                children: [
                                  Text(palette.emoji, style: const TextStyle(fontSize: 32)),
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
                                    "Type above to add the first plan for ${DateFormat('MMMM d').format(_selectedDay)}!",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dayItems.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = dayItems[index];
                            final isUpvoted = item.isUpvotedBy(currentUserId);

                            return Card(
                              elevation: item.isDone ? 0 : 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isUpvoted
                                      ? colorScheme.primary.withValues(alpha: 0.35)
                                      : colorScheme.outline.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                child: Row(
                                  children: [
                                    // Checkbox to toggle done
                                    IconButton(
                                      icon: Icon(
                                        item.isDone
                                            ? Icons.check_circle_rounded
                                            : Icons.radio_button_unchecked_rounded,
                                        color: item.isDone
                                            ? colorScheme.primary
                                            : colorScheme.onSurface.withValues(alpha: 0.45),
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        planNotifier.toggleDone(item);
                                      },
                                    ),

                                    // Item Title & Author
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              decoration: item.isDone ? TextDecoration.lineThrough : null,
                                              color: item.isDone
                                                  ? colorScheme.onSurface.withValues(alpha: 0.45)
                                                  : colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "Added by ${item.creatorName}",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: colorScheme.onSurface.withValues(alpha: 0.45),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Upvote Button 👍
                                    InkWell(
                                      onTap: () {
                                        planNotifier.toggleUpvote(item);
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isUpvoted
                                              ? colorScheme.primary
                                              : colorScheme.primaryContainer.withValues(alpha: 0.45),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.thumb_up_rounded,
                                              size: 13,
                                              color: isUpvoted ? colorScheme.onPrimary : colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${item.upvoteCount}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isUpvoted ? colorScheme.onPrimary : colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Delete Button
                                    IconButton(
                                      icon: Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                                      ),
                                      onPressed: () {
                                        planNotifier.deleteActivity(item);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
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
