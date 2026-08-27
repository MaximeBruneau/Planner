import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/auth_provider.dart';

/// A card widget displaying user account information and cloud sync status.
/// Also provides a button for the user to sign out.
class AccountManagementCard extends ConsumerWidget {
  /// Creates an [AccountManagementCard].
  const AccountManagementCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);

    return Card(
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
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
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
            ],
          ],
        ),
      ),
    );
  }
}
