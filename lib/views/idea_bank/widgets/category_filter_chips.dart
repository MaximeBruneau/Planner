import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/bank_idea.dart';
import '../../../providers/idea_provider.dart';

/// The horizontal list of category filter chips + sort toggle
class CategoryFilterChips extends ConsumerWidget {
  final IdeaState ideaState;

  const CategoryFilterChips({
    super.key,
    required this.ideaState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ideaNotifier = ref.read(ideaProvider.notifier);
    final filteredIdeas = ideaState.filteredIdeas;

    return Column(
      children: [
        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildCategoryFilterChip(
                context,
                category: null,
                label: "✨ All",
                count: ideaState.totalCount,
                isSelected: ideaState.selectedCategory == null,
                onTap: () => ideaNotifier.setSelectedCategory(null),
              ),
              ...IdeaCategory.values.map((cat) {
                final count = ideaState.countForCategory(cat);
                final isSelected = ideaState.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _buildCategoryFilterChip(
                    context,
                    category: cat,
                    label: "${cat.emoji} ${cat.label}",
                    count: count,
                    isSelected: isSelected,
                    onTap: () => ideaNotifier.setSelectedCategory(cat),
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Sorting indicator bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Text(
                "${filteredIdeas.length} idea${filteredIdeas.length != 1 ? 's' : ''}",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  final nextSort = ideaState.sortBy == 'upvotes' ? 'recent' : 'upvotes';
                  ideaNotifier.setSortBy(nextSort);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        ideaState.sortBy == 'upvotes'
                            ? Icons.thumb_up_rounded
                            : Icons.schedule_rounded,
                        size: 13,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ideaState.sortBy == 'upvotes' ? "Most voted" : "Most recent",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.swap_vert_rounded, size: 14, color: colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterChip(
    BuildContext context, {
    required IdeaCategory? category,
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.onPrimary.withValues(alpha: 0.25)
                      : colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$count",
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
