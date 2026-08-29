import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/shared_space.dart';
import '../../settings/settings_screen.dart';
import '../widgets/space_management_sheet.dart';
import '../widgets/activity_notifications_sheet.dart';
import '../../idea_bank/idea_bank_sheet.dart';

/// App bar for the main calendar screen with navigation and group controls.
class CalendarAppBar extends StatelessWidget implements PreferredSizeWidget {
  final SharedSpace? currentSpace;
  final int unreadNotificationsCount;
  final VoidCallback onTodayPressed;
  final VoidCallback onNotificationsPressed;
  final ValueChanged<DateTime> onDateSelectedFromNotifications;

  const CalendarAppBar({
    super.key,
    required this.currentSpace,
    required this.unreadNotificationsCount,
    required this.onTodayPressed,
    required this.onNotificationsPressed,
    required this.onDateSelectedFromNotifications,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      titleSpacing: 10,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: InkWell(
        onTap: () {
          FocusScope.of(context).unfocus();
          SpaceManagementSheet.show(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: colorScheme.primary),
                ],
              ),
              if (currentSpace != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        currentSpace!.code,
                        style: GoogleFonts.fredoka(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        "• ${currentSpace!.memberCount} ${currentSpace!.memberCount > 1 ? 'members' : 'member'}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        // Idea Bank 💡 Action (no count badge)
        IconButton(
          tooltip: "Idea Bank 💡",
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const Icon(Icons.lightbulb_outline_rounded, size: 21),
          onPressed: () {
            FocusScope.of(context).unfocus();
            IdeaBankSheet.show(context);
          },
        ),
        // Activity Notifications Feed
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: "Activity & Updates",
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(Icons.notifications_outlined, size: 21),
              onPressed: () {
                FocusScope.of(context).unfocus();
                onNotificationsPressed();
                ActivityNotificationsSheet.show(
                  context,
                  onDateSelected: onDateSelectedFromNotifications,
                );
              },
            ),
            if (unreadNotificationsCount > 0)
              Positioned(
                top: 4,
                right: 4,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 15,
                      minHeight: 15,
                    ),
                    child: Text(
                      '${unreadNotificationsCount > 9 ? '9+' : unreadNotificationsCount}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onError,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Jump to Today
        IconButton(
          tooltip: "Today",
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const Icon(Icons.today_rounded, size: 21),
          onPressed: () {
            FocusScope.of(context).unfocus();
            onTodayPressed();
          },
        ),
        // Settings
        IconButton(
          tooltip: "Settings",
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const Icon(Icons.settings_rounded, size: 21),
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}
