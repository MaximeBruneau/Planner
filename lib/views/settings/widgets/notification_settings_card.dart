import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/settings_provider.dart';

/// A card widget that allows users to configure their notification preferences.
class NotificationSettingsCard extends ConsumerWidget {
  /// Creates a [NotificationSettingsCard].
  const NotificationSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Notifications & Alerts 🔔",
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Stay updated when group members propose new ideas or change plans.",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),

            // Group Activity Notifications Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                "Group Activity Notifications",
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text("Notify when someone proposes or modifies a plan"),
              value: settings.groupActivityNotifications,
              activeTrackColor: colorScheme.primary,
              onChanged: (val) {
                ref.read(settingsProvider.notifier).toggleGroupActivityNotifications(val);
              },
            ),
            const Divider(height: 16),

            // Event Reminder Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                "Daily Planning Reminder",
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text("Gentle daily reminder to check upcoming plans"),
              value: settings.notificationsEnabled,
              activeTrackColor: colorScheme.primary,
              onChanged: (val) {
                ref.read(settingsProvider.notifier).toggleNotifications(val);
              },
            ),

            if (settings.notificationsEnabled) ...[
              const Divider(height: 16),
              InkWell(
                onTap: () async {
                  final timeParts = settings.notificationTime.split(':');
                  final initialHour = int.tryParse(timeParts[0]) ?? 21;
                  final initialMinute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;

                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
                  );

                  if (pickedTime != null) {
                    final formatted =
                        "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                    await ref.read(settingsProvider.notifier).updateNotificationTime(formatted);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Reminder Time",
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          settings.notificationTime,
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
