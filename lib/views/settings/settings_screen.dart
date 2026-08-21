import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/space_provider.dart';
import '../calendar/widgets/space_management_sheet.dart';
import 'widgets/theme_selector.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);
    final spaceState = ref.watch(spaceProvider);
    final currentSpace = spaceState.currentSpace;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings & Preferences ⚙️",
          style: GoogleFonts.fredoka(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: ACTIVE SHARED SPACE SUMMARY ---
            if (currentSpace != null) ...[
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(child: Text("🗓️", style: TextStyle(fontSize: 22))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentSpace.name,
                                  style: GoogleFonts.fredoka(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  "Code: ${currentSpace.code} • ${currentSpace.memberCount} member${currentSpace.memberCount > 1 ? 's' : ''}",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => SpaceManagementSheet.show(context),
                          icon: const Icon(Icons.group_outlined, size: 18),
                          label: const Text("Manage Group & Invite Code 🔑"),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // --- SECTION 2: THEMES SELECTOR ---
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18.0),
                child: ThemeSelector(),
              ),
            ),
            const SizedBox(height: 16),

            // --- SECTION 3: NOTIFICATIONS & REMINDERS ---
            Card(
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
            ),
            const SizedBox(height: 16),

            // --- SECTION 4: ACCOUNT & CLOUD SYNC ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Account & Cloud Sync ☁️",
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "Live Synced",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your shared calendar is continuously synced across all devices.",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (authState.isSignedIn) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundImage: authState.user?.photoUrl != null && authState.user!.photoUrl!.isNotEmpty
                                ? NetworkImage(authState.user!.photoUrl!)
                                : null,
                            child: authState.user?.photoUrl == null || authState.user!.photoUrl!.isEmpty
                                ? Text(
                                    (authState.user?.displayName.isNotEmpty == true)
                                        ? authState.user!.displayName[0].toUpperCase()
                                        : "👤",
                                    style: const TextStyle(fontSize: 18),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authState.user?.displayName ?? "User",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                if (authState.user?.email.isNotEmpty == true)
                                  Text(
                                    authState.user!.email,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text("Sign Out?", style: GoogleFonts.fredoka(fontWeight: FontWeight.w600)),
                                  content: const Text("Are you sure you want to sign out? Your calendars are safely stored in the cloud."),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        Navigator.pop(context);
                                        ref.read(authProvider.notifier).signOut();
                                      },
                                      child: const Text("Sign Out"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text("Sign Out"),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(
                                    "Delete Account & Data?",
                                    style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, color: colorScheme.error),
                                  ),
                                  content: const Text(
                                    "This action is permanent. All your spaces and profile data will be permanently deleted.",
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                                    ElevatedButton(
                                      onPressed: () async {
                                        Navigator.pop(ctx);
                                        Navigator.pop(context);
                                        await ref.read(authProvider.notifier).deleteAccountAndData();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.error,
                                        foregroundColor: colorScheme.onError,
                                      ),
                                      child: const Text("Delete Account"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text(
                              "Delete Account",
                              style: TextStyle(color: colorScheme.error, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
