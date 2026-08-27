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
  final int totalIdeasCount;
  final int unreadNotificationsCount;
  final VoidCallback onTodayPressed;
  final ValueChanged<DateTime> onDateSelectedFromNotifications;

  const CalendarAppBar({
    super.key,
    required this.currentSpace,
    required this.totalIdeasCount,
    required this.unreadNotificationsCount,
    required this.onTodayPressed,
    required this.onDateSelectedFromNotifications,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
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
                        currentSpace!.code,
                        style: GoogleFonts.fredoka(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "• ${currentSpace!.memberCount} member${currentSpace!.memberCount > 1 ? 's' : ''}",
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
        // Idea Bank 💡 Action
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: "Idea Bank 💡",
              icon: const Icon(Icons.lightbulb_outline_rounded),
              onPressed: () => IdeaBankSheet.show(context),
            ),
            if (totalIdeasCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${totalIdeasCount > 99 ? '99+' : totalIdeasCount}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Activity Notifications Feed
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: "Activity & Updates",
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                ActivityNotificationsSheet.show(
                  context,
                  onDateSelected: onDateSelectedFromNotifications,
                );
              },
            ),
            if (unreadNotificationsCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${unreadNotificationsCount > 9 ? '9+' : unreadNotificationsCount}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onError,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Jump to Today
        IconButton(
          tooltip: "Today",
          icon: const Icon(Icons.today_rounded),
          onPressed: onTodayPressed,
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
        const SizedBox(width: 4),
      ],
    );
  }
}
