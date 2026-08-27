import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/space_provider.dart';
import '../calendar/widgets/space_management_sheet.dart';
import 'widgets/theme_selector.dart';
import 'widgets/notification_settings_card.dart';
import 'widgets/account_management_card.dart';
import 'widgets/danger_zone_card.dart';

/// The main settings screen that orchestrates various settings sections.
class SettingsScreen extends ConsumerWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
            const NotificationSettingsCard(),
            const SizedBox(height: 16),

            // --- SECTION 4: ACCOUNT & CLOUD SYNC ---
            const AccountManagementCard(),
            const SizedBox(height: 16),

            // --- SECTION 5: DANGER ZONE ---
            const DangerZoneCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
