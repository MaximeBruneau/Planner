import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/notification_service.dart';
import 'widgets/emoji_customizer.dart';
import 'widgets/theme_selector.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings & Vibe Emojis ⚙️",
          style: GoogleFonts.fredoka(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Customize Emojis
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18.0),
                child: EmojiCustomizer(),
              ),
            ),
            const SizedBox(height: 20),

            // Section 2: Select Theme
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18.0),
                child: ThemeSelector(),
              ),
            ),
            const SizedBox(height: 20),

            // Section 3: Notification Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Nightly Reminder 🔔",
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Receive a cute reminder at 9:00 PM (21:00) if you haven't logged today's vibe yet.",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Enable 9:00 PM Reminder",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text("Only fires if today is unlogged"),
                      value: settings.notificationsEnabled,
                      activeTrackColor: colorScheme.primary,
                      onChanged: (val) {
                        ref
                            .read(settingsProvider.notifier)
                            .toggleNotifications(val);
                      },
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await NotificationService().showTestNotification();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Test reminder sent! 🌸 Check your notification shade."),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.notifications_active_outlined, size: 18),
                      label: const Text("Send Test Notification 🌸"),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Section 4: Cloud Sync & Backup
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Google Cloud Backup ☁️",
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sign in with Google to automatically backup your entries to the cloud and restore on any device.",
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
                            backgroundImage: authState.user?.photoURL != null
                                ? NetworkImage(authState.user!.photoURL!)
                                : null,
                            child: authState.user?.photoURL == null
                                ? const Icon(Icons.person_rounded)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authState.user?.displayName ?? "Logged User",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  authState.user?.email ?? "",
                                  style: TextStyle(
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
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: authState.isLoading
                                ? null
                                : () => ref
                                    .read(authProvider.notifier)
                                    .triggerSync(),
                            icon: authState.isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.sync_rounded, size: 18),
                            label: const Text("Sync Now 🔄"),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () =>
                                ref.read(authProvider.notifier).signOut(),
                            child: const Text("Sign Out"),
                          ),
                        ],
                      )
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: authState.isLoading
                            ? null
                            : () => ref
                                .read(authProvider.notifier)
                                .signInWithGoogle(),
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                        label: Text(
                          authState.isLoading
                              ? "Signing In..."
                              : "Sign in with Google",
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
