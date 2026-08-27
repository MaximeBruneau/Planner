import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/space_provider.dart';

/// A card widget containing destructive actions like deleting the account.
class DangerZoneCard extends ConsumerWidget {
  /// Creates a [DangerZoneCard].
  const DangerZoneCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);

    if (!authState.isSignedIn) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Danger Zone ⚠️",
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Irreversible actions for your account and spaces.",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(
                            "Leave Space?",
                            style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, color: colorScheme.error),
                          ),
                          content: const Text(
                            "Are you sure you want to leave this space? You will need an invite code to join again.",
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await ref.read(spaceProvider.notifier).leaveSpace();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.error,
                                foregroundColor: colorScheme.onError,
                              ),
                              child: const Text("Leave Space"),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                    label: const Text("Leave Space"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
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
                    icon: const Icon(Icons.delete_forever_rounded, size: 18),
                    label: const Text("Delete"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
