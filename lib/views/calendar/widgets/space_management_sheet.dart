import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/space_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/shared_space.dart';
import 'join_space_dialog.dart';
import 'create_space_dialog.dart';
import 'invite_card.dart';
import 'member_list_tile.dart';

/// The main bottom sheet for orchestrating shared calendar space management.
class SpaceManagementSheet extends ConsumerStatefulWidget {
  const SpaceManagementSheet({super.key});

  /// Displays the space management bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SpaceManagementSheet(),
    );
  }

  @override
  ConsumerState<SpaceManagementSheet> createState() => _SpaceManagementSheetState();
}

class _SpaceManagementSheetState extends ConsumerState<SpaceManagementSheet> {

  void _showJoinDialog(BuildContext parentContext) async {
    final code = await JoinSpaceDialog.show(parentContext);
    if (code != null && mounted) {
      Navigator.of(context).pop(); // Close sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🎉 Joined shared calendar space $code!"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCreateDialog(BuildContext parentContext) async {
    final spaceData = await CreateSpaceDialog.show(parentContext);
    if (spaceData != null && mounted) {
      Navigator.of(context).pop(); // Close sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✨ Created '${spaceData['name']}'! Code: ${spaceData['code']}"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEditPseudoDialog(BuildContext context, String currentName) {
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
              "Edit your Pseudo",
              style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your friends will see this name in the group and on shared plans.",
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
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx);
                await ref.read(authProvider.notifier).updateDisplayName(newName);
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
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showEditSpaceNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Edit Calendar Name 🗓️",
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Choose a name for this shared calendar space.",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: "Calendar Space Name",
                hintText: "e.g. Our Shared Calendar 🗓️",
                prefixIcon: const Icon(Icons.edit_calendar_rounded, size: 20),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx);
                await ref.read(spaceProvider.notifier).updateSpaceName(newName);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("✨ Calendar name updated to \"$newName\"!"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(BuildContext context, SpaceMember member) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Remove member?", style: GoogleFonts.fredoka(fontWeight: FontWeight.w600)),
        content: Text("Are you sure you want to remove \"${member.displayName}\" from this shared space?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(spaceProvider.notifier).removeMember(member.userId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Member \"${member.displayName}\" removed"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final spaceState = ref.watch(spaceProvider);
    final currentSpace = spaceState.currentSpace;
    final authState = ref.watch(authProvider);

    if (currentSpace == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("No active space selected"),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _showCreateDialog(context),
              child: const Text("Create Space"),
            ),
          ],
        ),
      );
    }

    final membersList = currentSpace.members.values.toList();
    final currentUserEmail = authState.user?.email.toLowerCase().trim() ?? '';
    final currentUserId = authState.user?.id ?? '';
    final isOwnerOfSpace = currentSpace.creatorId == currentUserId ||
        currentSpace.members[currentUserId]?.role == 'owner' ||
        (currentUserEmail.isNotEmpty &&
            currentSpace.members.values.any((m) =>
                m.email.toLowerCase().trim() == currentUserEmail && m.role == 'owner'));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              currentSpace.name,
                              style: GoogleFonts.fredoka(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOwnerOfSpace) ...[
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _showEditSpaceNameDialog(context, currentSpace.name),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.edit_rounded, size: 16, color: colorScheme.primary),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        "${currentSpace.memberCount} member${currentSpace.memberCount > 1 ? 's' : ''}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),

          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InviteCard(spaceCode: currentSpace.code),
                  const SizedBox(height: 24),

                  // Members Directory
                  Row(
                    children: [
                      Text(
                        "Group Members (${membersList.length})",
                        style: GoogleFonts.fredoka(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                            text: "Join my shared calendar '${currentSpace.name}' on Super Planner using code: ${currentSpace.code} 🗓️✨",
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("✉️ Full invitation message copied!"),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text("Share Invite"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: membersList.map((m) {
                          final isMe = m.userId == currentUserId ||
                              (m.email.isNotEmpty &&
                                  currentUserEmail.isNotEmpty &&
                                  m.email.toLowerCase().trim() == currentUserEmail);
                          return MemberListTile(
                            member: m,
                            isMe: isMe,
                            canRemove: isOwnerOfSpace && !isMe,
                            onRemove: isOwnerOfSpace && !isMe
                                ? () => _confirmRemoveMember(context, m)
                                : null,
                            onEditPseudo: isMe
                                ? () => _showEditPseudoDialog(context, m.displayName)
                                : null,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Space Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showJoinDialog(context),
                          icon: const Icon(Icons.add_link_rounded, size: 18),
                          label: const Text("Join Space"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showCreateDialog(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text("New Space"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Leave Space Button
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Leave Calendar Space?"),
                            content: Text("Are you sure you want to leave '${currentSpace.name}'?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.error,
                                  foregroundColor: colorScheme.onError,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text("Leave"),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await ref.read(spaceProvider.notifier).leaveSpace();
                          if (!mounted) return;
                          navigator.pop();
                        }
                      },
                      icon: Icon(Icons.logout_rounded, size: 16, color: colorScheme.error),
                      label: Text("Leave this space", style: TextStyle(color: colorScheme.error, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
  }
}
