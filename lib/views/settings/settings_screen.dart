import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/partner_provider.dart';
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
            // Section 1: Customize Emojis
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18.0),
                child: EmojiCustomizer(),
              ),
            ),
            const SizedBox(height: 18),

            // Section 2: Select Theme
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ThemeSelector(),
                    const SizedBox(height: 14),
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          final restored = await ref
                              .read(settingsProvider.notifier)
                              .restorePurchases(userId: authState.user?.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Purchases restored! (${restored.length} themes available) 🌸",
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.restore_rounded, size: 18),
                        label: const Text("Restore Purchased Themes"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

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
                              content: const Text(
                                "Test reminder sent! 🌸 Check your notification shade.",
                              ),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        size: 18,
                      ),
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
            const SizedBox(height: 18),

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
                            backgroundImage: authState.user?.photoUrl != null
                                ? NetworkImage(authState.user!.photoUrl!)
                                : null,
                            child: authState.user?.photoUrl == null
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
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            onPressed: authState.isLoading
                                ? null
                                : () async {
                                    final user = await ref
                                        .read(authProvider.notifier)
                                        .signInWithGoogle();
                                    if (context.mounted) {
                                      if (user != null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Welcome, ${user.displayName}! 🌸 Google backup connected.",
                                            ),
                                            duration:
                                                const Duration(seconds: 3),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              kIsWeb
                                                  ? "Google Sign-In canceled or blocked. Please ensure popups are allowed."
                                                  : "Google Sign-In could not be completed.",
                                            ),
                                            duration:
                                                const Duration(seconds: 4),
                                            behavior: SnackBarBehavior.floating,
                                            action: SnackBarAction(
                                              label: "Set Profile",
                                              onPressed: () =>
                                                  _showProfileDialog(context, ref),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            icon:
                                const Icon(Icons.g_mobiledata_rounded, size: 24),
                            label: Text(
                              authState.isLoading
                                  ? "Signing In..."
                                  : "Sign in with Google",
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: authState.isLoading
                                ? null
                                : () => _showProfileDialog(context, ref),
                            icon: const Icon(Icons.person_add_alt_1_rounded,
                                size: 18),
                            label: const Text("Custom Profile 👤"),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Section 5: Friend Sharing 🐰
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "FT Sharing 🐰",
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Share your calendar in read-only mode securely with your FT.",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer(
                      builder: (context, ref, child) {
                        final partnerState = ref.watch(partnerProvider);
                        if (partnerState.isPaired) {
                          final partner = partnerState.partnerInfo!;
                          return Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        colorScheme.secondaryContainer,
                                    backgroundImage: partner.photoUrl != null
                                        ? NetworkImage(partner.photoUrl!)
                                        : null,
                                    child: partner.photoUrl == null
                                        ? const Text("🐰")
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Connected with ${partner.displayName} 🐰",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          partner.email,
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
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Disconnect Calendars?"),
                                      content: Text(
                                        "Are you sure you want to disconnect from ${partner.displayName}? You will no longer be able to view each other's calendars and duo flames will reset.",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            ref
                                                .read(partnerProvider.notifier)
                                                .unpair(authState.user);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: colorScheme.error,
                                            foregroundColor:
                                                colorScheme.onError,
                                          ),
                                          child: const Text("Disconnect"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.link_off_rounded,
                                    size: 18),
                                label: const Text("Disconnect Partner"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.error,
                                  side: BorderSide(
                                    color: colorScheme.error
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "No FT connected yet.",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.add_link_rounded,
                                    size: 18),
                                label: const Text("Connect on Home 🌸"),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Section 6: Legal & Privacy Notice
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "My Vibe • 100% Local-First & Private\nCrafted with care 🌸",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Personalize Your Profile 🌸",
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Enter your name and email to personalize your calendar experience.",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Your Name / Nickname",
                  hintText: "e.g. Best Friend 🌸",
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  hintText: "e.g. friend@example.com",
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    if (name.isEmpty && email.isEmpty) {
                      Navigator.pop(ctx);
                      return;
                    }
                    ref.read(authProvider.notifier).setUserProfile(
                          displayName: name.isNotEmpty ? name : 'Friend 🌸',
                          email: email.isNotEmpty
                              ? email
                              : 'friend@vibecalendar.app',
                        );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Profile saved for ${name.isNotEmpty ? name : 'Friend'}! 🌸",
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text("Save Profile ✨"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
