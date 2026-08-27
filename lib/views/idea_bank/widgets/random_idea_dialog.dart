import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/bank_idea.dart';
import '../../../providers/idea_provider.dart';
import '../../../providers/auth_provider.dart';

class RandomIdeaDialog extends ConsumerStatefulWidget {
  final BankIdea initialIdea;
  final IdeaCategory? initialCategory;

  const RandomIdeaDialog({
    super.key,
    required this.initialIdea,
    this.initialCategory,
  });

  static Future<void> show(
    BuildContext context, {
    required BankIdea initialIdea,
    IdeaCategory? category,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => RandomIdeaDialog(
        initialIdea: initialIdea,
        initialCategory: category,
      ),
    );
  }

  @override
  ConsumerState<RandomIdeaDialog> createState() => _RandomIdeaDialogState();
}

class _RandomIdeaDialogState extends ConsumerState<RandomIdeaDialog>
    with SingleTickerProviderStateMixin {
  late BankIdea _currentIdea;
  late IdeaCategory? _currentCategory;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentIdea = widget.initialIdea;
    _currentCategory = widget.initialCategory;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _pickAnother() {
    final next = ref.read(ideaProvider.notifier).pickRandomIdea(category: _currentCategory);
    if (next != null) {
      _animController.reset();
      setState(() {
        _currentIdea = next;
      });
      _animController.forward();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No other idea found in this category ! 💡"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id ?? '';

    // Watch current idea in store in case upvote changes
    final ideas = ref.watch(ideaProvider).ideas;
    final freshIdea = ideas.firstWhere(
      (i) => i.id == _currentIdea.id,
      orElse: () => _currentIdea,
    );
    final isUpvoted = freshIdea.isUpvotedBy(currentUserId);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dice Header Badge
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text('🎲', style: TextStyle(fontSize: 30)),
              ),
              const SizedBox(height: 12),

              Text(
                "How about we do this?",
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Idea picked randomly from the bank 💡",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),

              // Filter category chips within dialog (optional switch)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCategoryFilterChip(null, "✨ All"),
                    ...IdeaCategory.values.map(
                      (cat) => _buildCategoryFilterChip(cat, "${cat.emoji} ${cat.label}"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Highlight Idea Card with Animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Tag & Upvote
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(freshIdea.category.emoji, style: const TextStyle(fontSize: 13)),
                                const SizedBox(width: 5),
                                Text(
                                  freshIdea.category.label,
                                  style: GoogleFonts.fredoka(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Upvote button
                          InkWell(
                            onTap: () {
                              ref.read(ideaProvider.notifier).toggleUpvote(freshIdea);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                    "${freshIdea.upvoteCount}",
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
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        freshIdea.title,
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          height: 1.3,
                        ),
                      ),

                      // Note if available
                      if (freshIdea.note != null && freshIdea.note!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.notes_rounded,
                                size: 14,
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  freshIdea.note!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),

                      // Author
                      Text(
                        "Suggested by ${freshIdea.creatorName}",
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Close"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _pickAnother,
                      icon: const Text("🎲", style: TextStyle(fontSize: 16)),
                      label: Text(
                        "Pick another",
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterChip(IdeaCategory? cat, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _currentCategory == cat;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        selectedColor: colorScheme.primary,
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        onSelected: (selected) {
          setState(() {
            _currentCategory = selected ? cat : null;
          });
          _pickAnother();
        },
      ),
    );
  }
}
