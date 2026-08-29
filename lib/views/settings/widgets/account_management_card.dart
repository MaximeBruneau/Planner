import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/space_provider.dart';

/// A card widget displaying user profile, pseudo customization, and account management.
class AccountManagementCard extends ConsumerWidget {
  /// Creates an [AccountManagementCard].
  const AccountManagementCard({super.key});

  void _showEditPseudoDialog(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text("✏️", style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              "Choose your Pseudo",
              style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "This name will be displayed to your friends on activities, ideas, upvotes, and member lists.",
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: "Your Pseudo / Nickname",
                hintText: "e.g. Alex, Sam 🍕, Captain",
                prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              FocusScope.of(ctx).unfocus();
              Navigator.pop(ctx);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              FocusScope.of(ctx).unfocus();
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx);
                final success = await ref.read(authProvider.notifier).updateDisplayName(newName);
                if (success) {
                  await ref.read(spaceProvider.notifier).updateMyMemberName(newName);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("✨ Pseudo updated to \"$newName\"!"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final currentDisplayName = user?.displayName.isNotEmpty == true ? user!.displayName : "Planner User";

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
                  "Account & Profile 👤",
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
              "Your nickname is visible to all members of your shared spaces.",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),

            // Profile info tile with clickable edit pseudo
            InkWell(
              onTap: () => _showEditPseudoDialog(context, ref, currentDisplayName),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user?.photoUrl == null || user!.photoUrl!.isEmpty
                          ? Text(
                              currentDisplayName.isNotEmpty
                                  ? currentDisplayName[0].toUpperCase()
                                  : "👤",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  currentDisplayName,
                                  style: GoogleFonts.fredoka(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email.isNotEmpty == true
                                ? user!.email
                                : "Tap to customize your pseudo",
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Actions row: Edit Pseudo & Sign Out
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditPseudoDialog(context, ref, currentDisplayName),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text("Edit Pseudo"),
                    style: ElevatedButton.styleFrom(
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                if (authState.isSignedIn) ...[
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text("Sign Out"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
