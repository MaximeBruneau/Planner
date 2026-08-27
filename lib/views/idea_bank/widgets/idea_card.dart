import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/bank_idea.dart';

/// The card widget for a single idea with upvote/delete actions
class IdeaCard extends StatelessWidget {
  final BankIdea idea;
  final bool isUpvoted;
  final VoidCallback onUpvote;
  final VoidCallback onDelete;

  const IdeaCard({
    super.key,
    required this.idea,
    required this.isUpvoted,
    required this.onUpvote,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isUpvoted
              ? colorScheme.primary.withValues(alpha: 0.35)
              : colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Icon Badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                idea.category.emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          idea.category.label,
                          style: GoogleFonts.fredoka(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "• by ${idea.creatorName}",
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Title
                  Text(
                    idea.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      height: 1.25,
                    ),
                  ),

                  // Note (if any)
                  if (idea.note != null && idea.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      idea.note!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Upvote Button 👍
            InkWell(
              onTap: onUpvote,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: isUpvoted
                      ? colorScheme.primary
                      : colorScheme.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.thumb_up_rounded,
                      size: 13,
                      color: isUpvoted ? colorScheme.onPrimary : colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${idea.upvoteCount}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isUpvoted ? colorScheme.onPrimary : colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Delete Button
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.35),
              ),
              padding: const EdgeInsets.only(left: 4),
              constraints: const BoxConstraints(),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
