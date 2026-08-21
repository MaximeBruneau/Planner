import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/space_provider.dart';
import '../../../providers/auth_provider.dart';

class SpaceManagementSheet extends ConsumerStatefulWidget {
  const SpaceManagementSheet({super.key});

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
  final _joinCodeController = TextEditingController();
  final _createNameController = TextEditingController();

  @override
  void dispose() {
    _joinCodeController.dispose();
    _createNameController.dispose();
    super.dispose();
  }

  void _showJoinDialog(BuildContext parentContext) {
    String? localError;
    bool isSubmitting = false;

    showDialog(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Text("🔗", style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  "Join Calendar",
                  style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 20),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Enter the invite code (e.g. SUPER-4892) shared by your group.",
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _joinCodeController,
                  textCapitalization: TextCapitalization.characters,
                  enabled: !isSubmitting,
                  decoration: InputDecoration(
                    labelText: "Invite Code",
                    hintText: "SUPER-1234",
                    prefixIcon: const Icon(Icons.vpn_key_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                if (localError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            localError!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final code = _joinCodeController.text.trim();
                        if (code.isEmpty) return;

                        setDialogState(() {
                          isSubmitting = true;
                          localError = null;
                        });

                        final success = await ref.read(spaceProvider.notifier).joinSpace(code);

                        if (!mounted || !parentContext.mounted) return;

                        if (success) {
                          if (ctx.mounted) Navigator.pop(ctx); // Close dialog
                          Navigator.of(context).pop(); // Close sheet
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("🎉 Joined shared calendar space $code!"),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          final err = ref.read(spaceProvider).errorMessage ?? "Could not join space.";
                          setDialogState(() {
                            isSubmitting = false;
                            localError = err;
                          });
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Join Space"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext parentContext) {
    bool isSubmitting = false;

    showDialog(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Text("✨", style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  "New Shared Calendar",
                  style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 20),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Give your shared calendar space a name (e.g. Weekend Squad 🍕, Paris Trip ✈️, Family 🏡)",
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _createNameController,
                  enabled: !isSubmitting,
                  decoration: InputDecoration(
                    labelText: "Space Name",
                    hintText: "e.g. Weekend Squad 🍕",
                    prefixIcon: const Icon(Icons.group_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final name = _createNameController.text.trim();
                        setDialogState(() => isSubmitting = true);

                        final space = await ref.read(spaceProvider.notifier).createSpace(
                              name: name.isNotEmpty ? name : 'Our Shared Calendar 🗓️',
                            );
                        if (!mounted || !parentContext.mounted) return;

                        if (space != null) {
                          if (ctx.mounted) Navigator.pop(ctx); // Close dialog
                          Navigator.of(context).pop(); // Close sheet
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("✨ Created '${space.name}'! Code: ${space.code}"),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          setDialogState(() => isSubmitting = false);
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Create Space"),
              ),
            ],
          );
        },
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
                      Text(
                        currentSpace.name,
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        "${currentSpace.memberCount} member${currentSpace.memberCount > 1 ? 's' : ''} sharing this calendar",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
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
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- INVITE CODE CARD ---
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.secondaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text("🔑", style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Text(
                              "Shared Calendar Invite Code",
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Share this code with friends, family, or your partner so they can join and plan together!",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Code display & Copy Button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                currentSpace.code,
                                style: GoogleFonts.fredoka(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: currentSpace.code));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("📋 Code ${currentSpace.code} copied to clipboard!"),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text("Copy"),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  minimumSize: const Size(0, 36),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- MEMBERS DIRECTORY ---
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
                          final isMe = m.userId == authState.user?.id;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: colorScheme.primaryContainer,
                                  backgroundImage: m.photoUrl != null && m.photoUrl!.isNotEmpty
                                      ? NetworkImage(m.photoUrl!)
                                      : null,
                                  child: m.photoUrl == null || m.photoUrl!.isEmpty
                                      ? Text(
                                          m.displayName.isNotEmpty ? m.displayName[0].toUpperCase() : "👤",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.primary,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            m.displayName,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (isMe) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                "You",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (m.email.isNotEmpty)
                                        Text(
                                          m.email,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: m.role == 'owner'
                                        ? Colors.amber.withValues(alpha: 0.2)
                                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    m.role == 'owner' ? "Admin 👑" : "Member",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: m.role == 'owner' ? Colors.orange.shade800 : colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- SPACE ACTIONS ---
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
                                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
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
        ],
      ),
    );
  }
}
