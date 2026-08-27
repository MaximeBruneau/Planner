import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/bank_idea.dart';
import '../../../providers/idea_provider.dart';
import 'add_idea_sheet.dart';

/// The empty state illustration when no ideas match
class IdeaBankEmptyState extends ConsumerWidget {
  final IdeaState ideaState;

  const IdeaBankEmptyState({
    super.key,
    required this.ideaState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Text(
                ideaState.selectedCategory?.emoji ?? "💡",
                style: const TextStyle(fontSize: 38),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              ideaState.selectedCategory != null
                ? "No ideas in ${ideaState.selectedCategory!.label}"
                : "The idea bank is empty!",
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Add restaurants to try, spots to visit, or activities to do together to pick from later!",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Starter inspiration buttons
            Text(
              "Quick inspirations:",
              style: GoogleFonts.fredoka(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildStarterChip(ref, "Try a ramen restaurant 🍜", IdeaCategory.food),
                _buildStarterChip(ref, "Sunset at the viewpoint 🌅", IdeaCategory.place),
                _buildStarterChip(ref, "Escape game night 🕵️", IdeaCategory.activity),
                _buildStarterChip(ref, "Board game night 🎲", IdeaCategory.activity),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                AddIdeaSheet.show(
                  context,
                  initialCategory: ideaState.selectedCategory ?? IdeaCategory.food,
                );
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text("Add custom idea 💡"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarterChip(WidgetRef ref, String text, IdeaCategory category) {
    return ActionChip(
      avatar: Text(category.emoji, style: const TextStyle(fontSize: 13)),
      label: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
      onPressed: () {
        ref.read(ideaProvider.notifier).addIdea(
              title: text,
              category: category,
            );
      },
    );
  }
}
