import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/bank_idea.dart';
import '../../providers/idea_provider.dart';
import '../../providers/auth_provider.dart';
import 'widgets/add_idea_sheet.dart';
import 'widgets/random_idea_dialog.dart';
import 'widgets/idea_card.dart';
import 'widgets/idea_bank_header.dart';
import 'widgets/category_filter_chips.dart';
import 'widgets/idea_bank_empty_state.dart';

/// Main orchestrator bottom sheet for the Idea Bank
class IdeaBankSheet extends ConsumerStatefulWidget {
  const IdeaBankSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const IdeaBankSheet(),
    );
  }

  @override
  ConsumerState<IdeaBankSheet> createState() => _IdeaBankSheetState();
}

class _IdeaBankSheetState extends ConsumerState<IdeaBankSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onRandomPick(IdeaState ideaState) {
    final idea = ref.read(ideaProvider.notifier).pickRandomIdea();
    if (idea != null) {
      RandomIdeaDialog.show(
        context,
        initialIdea: idea,
        category: ideaState.selectedCategory,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Add some ideas to the bank first! 💡"),
          action: SnackBarAction(
            label: "Add",
            onPressed: () => AddIdeaSheet.show(context),
          ),
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
    final ideaState = ref.watch(ideaProvider);
    final ideaNotifier = ref.read(ideaProvider.notifier);

    final filteredIdeas = ideaState.filteredIdeas;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
        maxWidth: 640,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          IdeaBankHeader(
            ideaState: ideaState,
            isSearching: _isSearching,
            onToggleSearch: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ideaNotifier.setSearchQuery('');
                }
              });
            },
            onClearSearch: () {
              _searchController.clear();
              ideaNotifier.setSearchQuery('');
            },
            onSearchChanged: (val) => ideaNotifier.setSearchQuery(val),
            searchController: _searchController,
            onRandomPick: () => _onRandomPick(ideaState),
          ),

          const SizedBox(height: 10),

          CategoryFilterChips(ideaState: ideaState),

          const Divider(height: 1),

          // Idea List / Empty State
          Expanded(
            child: filteredIdeas.isEmpty
                ? IdeaBankEmptyState(ideaState: ideaState)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: filteredIdeas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final idea = filteredIdeas[index];
                      final isUpvoted = idea.isUpvotedBy(currentUserId);

                      return IdeaCard(
                        idea: idea,
                        isUpvoted: isUpvoted,
                        onUpvote: () => ideaNotifier.toggleUpvote(idea),
                        onDelete: () => ideaNotifier.deleteIdea(idea),
                      );
                    },
                  ),
          ),

          // Pinned Bottom Add Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  AddIdeaSheet.show(
                    context,
                    initialCategory: ideaState.selectedCategory ?? IdeaCategory.food,
                  );
                },
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                label: Text(
                  "Add a random idea 💡",
                  style: GoogleFonts.fredoka(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
