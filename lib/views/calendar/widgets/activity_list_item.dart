import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/plan_activity.dart';

/// A card widget displaying a single activity/plan item.
/// Supports toggling completion status, upvoting, and deletion.
class ActivityListItem extends StatelessWidget {
  /// The activity item to display
  final PlanActivity item;
  
  /// The ID of the currently logged-in user
  final String currentUserId;
  
  /// Callback when the done checkbox is tapped
  final VoidCallback onToggleDone;
  
  /// Callback when the upvote button is tapped
  final VoidCallback onToggleUpvote;
  
  /// Callback when the delete button is tapped
  final VoidCallback onDelete;

  const ActivityListItem({
    super.key,
    required this.item,
    required this.currentUserId,
    required this.onToggleDone,
    required this.onToggleUpvote,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUpvoted = item.isUpvotedBy(currentUserId);

    return Card(
      elevation: item.isDone ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isUpvoted
              ? colorScheme.primary.withValues(alpha: 0.35)
              : colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            // Checkbox to toggle done
            IconButton(
              icon: Icon(
                item.isDone
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: item.isDone
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.45),
                size: 22,
              ),
              onPressed: onToggleDone,
            ),

            // Item Title & Author
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: item.isDone ? TextDecoration.lineThrough : null,
                      color: item.isDone
                          ? colorScheme.onSurface.withValues(alpha: 0.45)
                          : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Added by ${item.creatorName}",
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),

            // Upvote Button 👍
            InkWell(
              onTap: onToggleUpvote,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      "${item.upvoteCount}",
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
                size: 18,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
