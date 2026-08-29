import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/shared_space.dart';

/// A tile displaying a single member in the shared space.
class MemberListTile extends StatelessWidget {
  final SpaceMember member;
  final bool isMe;
  final bool canRemove;
  final VoidCallback? onRemove;
  final VoidCallback? onEditPseudo;

  const MemberListTile({
    super.key,
    required this.member,
    required this.isMe,
    this.canRemove = false,
    this.onRemove,
    this.onEditPseudo,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: member.photoUrl != null && member.photoUrl!.isNotEmpty
                ? NetworkImage(member.photoUrl!)
                : null,
            child: member.photoUrl == null || member.photoUrl!.isEmpty
                ? Text(
                    member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : "👤",
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
                    Flexible(
                      child: Text(
                        member.displayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                      if (onEditPseudo != null) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: onEditPseudo,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(Icons.edit_rounded, size: 14, color: colorScheme.primary),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
                if (member.email.isNotEmpty)
                  Text(
                    member.email,
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
              color: member.role == 'owner'
                  ? colorScheme.tertiaryContainer.withValues(alpha: 0.2)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              member.role == 'owner' ? "Admin 👑" : "Member",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: member.role == 'owner' ? colorScheme.tertiary : colorScheme.onSurface,
              ),
            ),
          ),
          if (canRemove && onRemove != null) ...[
            const SizedBox(width: 4),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: Icon(Icons.remove_circle_outline_rounded, size: 18, color: colorScheme.error.withValues(alpha: 0.8)),
              tooltip: "Remove from space",
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }
}
