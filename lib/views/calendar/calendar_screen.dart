import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/plan_provider.dart';
import '../../providers/space_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/idea_provider.dart';
import '../../core/theme/theme_palettes.dart';
import 'widgets/calendar_app_bar.dart';
import 'widgets/in_app_notice_banner.dart';
import 'widgets/calendar_month_card.dart';
import 'widgets/activity_notifications_sheet.dart';
import 'widgets/activity_list_item.dart';
import 'widgets/add_activity_input.dart';
import 'widgets/selected_day_header.dart';
import 'widgets/empty_day_card.dart';
import '../idea_bank/idea_bank_sheet.dart';
import '../idea_bank/widgets/random_idea_dialog.dart';

/// Main calendar screen that orchestrates the month view, day activities, and group features.
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

  void _pickRandomIdea() {
    final idea = ref.read(ideaProvider.notifier).pickRandomIdea();
    if (idea != null) {
      RandomIdeaDialog.show(context, initialIdea: idea);
    } else {
      IdeaBankSheet.show(context);
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _focusedDay = date;
      _selectedDay = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id ?? '';
    final spaceState = ref.watch(spaceProvider);
    final planState = ref.watch(planProvider);
    final planNotifier = ref.read(planProvider.notifier);
    final ideaState = ref.watch(ideaProvider);

    final palette = AppPalettes.getById(settings.themeId);
    final currentSpace = spaceState.currentSpace;
    final dayItems = planNotifier.getActivitiesForDate(_selectedDay);

    final screenSize = MediaQuery.sizeOf(context);
    final screenHeight = screenSize.height;
    final double adaptiveRowHeight =
        screenHeight > 850 ? 54.0 : (screenHeight < 680 ? 44.0 : 48.0);
    final double adaptiveDaysOfWeekHeight = screenHeight > 850 ? 26.0 : 22.0;

    return Scaffold(
      appBar: CalendarAppBar(
        currentSpace: currentSpace,
        totalIdeasCount: ideaState.totalCount,
        unreadNotificationsCount: planState.unreadNotificationsCount,
        onTodayPressed: () => _onDateSelected(DateTime.now()),
        onDateSelectedFromNotifications: _onDateSelected,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            children: [
              // In-app live notification banner (auto-dismisses after 2s)
              InAppNoticeBanner(
                notice: planState.lastInAppNotice,
                onTap: () {
                  ActivityNotificationsSheet.show(
                    context,
                    onDateSelected: _onDateSelected,
                  );
                },
                onClose: () => planNotifier.clearNotice(),
              ),

              // Expanded Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Monthly Calendar Card
                      CalendarMonthCard(
                        focusedDay: _focusedDay,
                        selectedDay: _selectedDay,
                        adaptiveRowHeight: adaptiveRowHeight,
                        adaptiveDaysOfWeekHeight: adaptiveDaysOfWeekHeight,
                        getCountForDate: (day) => planNotifier.getCountForDate(day),
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
                      const SizedBox(height: 14),

                      // Selected Day Header (1 Date = 1 List)
                      SelectedDayHeader(
                        selectedDay: _selectedDay,
                        itemCount: dayItems.length,
                      ),
                      const SizedBox(height: 10),

                      // Inline Add Input Card
                      AddActivityInput(
                        selectedDay: _selectedDay,
                        controller: _itemInputController,
                        focusNode: _inputFocusNode,
                        onSubmit: _submitItem,
                        onRandomIdeaTap: _pickRandomIdea,
                      ),
                      const SizedBox(height: 14),

                      // The 1 List for this Selected Date
                      if (dayItems.isEmpty)
                        EmptyDayCard(
                          selectedDay: _selectedDay,
                          themeEmoji: palette.emoji,
                          onRandomIdeaTap: _pickRandomIdea,
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dayItems.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = dayItems[index];

                            return ActivityListItem(
                              item: item,
                              currentUserId: currentUserId,
                              onToggleDone: () => planNotifier.toggleDone(item),
                              onToggleUpvote: () =>
                                  planNotifier.toggleUpvote(item),
                              onDelete: () => planNotifier.deleteActivity(item),
                            );
                          },
                        ),
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
