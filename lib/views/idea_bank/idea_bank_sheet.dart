import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/bank_idea.dart';
import '../../providers/idea_provider.dart';
import '../../providers/auth_provider.dart';
import 'widgets/add_idea_sheet.dart';
import 'widgets/random_idea_dialog.dart';

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
          content: const Text("Ajoutez d'abord quelques idées dans la banque ! 💡"),
          action: SnackBarAction(
            label: "Ajouter",
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
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Text("💡", style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Banque d'idées",
                            style: GoogleFonts.fredoka(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "${ideaState.totalCount}",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Piochez dedans quand vous ne savez plus quoi prévoir ✨",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: "Rechercher",
                  icon: Icon(_isSearching ? Icons.search_off_rounded : Icons.search_rounded),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        ideaNotifier.setSearchQuery('');
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search field (if active)
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Rechercher une idée, un resto, une activité...",
                  hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            ideaNotifier.setSearchQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                ),
                onChanged: (val) => ideaNotifier.setSearchQuery(val),
              ),
            ),

          const SizedBox(height: 6),

          // Hero Banner "🎲 Piocher au hasard"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onRandomPick(ideaState),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.secondary.withValues(alpha: 0.25),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Text("🎲", style: TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Panne d'inspiration ?",
                              style: GoogleFonts.fredoka(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              ideaState.selectedCategory != null
                                  ? "Piocher une idée dans ${ideaState.selectedCategory!.labelFr} 🎲"
                                  : "Piocher une idée au hasard parmi les ${ideaState.totalCount} idées 🎲",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Piocher",
                              style: GoogleFonts.fredoka(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.auto_awesome_rounded, size: 14, color: colorScheme.onPrimary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildCategoryFilterChip(
                  context,
                  category: null,
                  label: "✨ Toutes",
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
                      label: "${cat.emoji} ${cat.labelFr}",
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
                  "${filteredIdeas.length} idée${filteredIdeas.length > 1 ? 's' : ''}",
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
                          ideaState.sortBy == 'upvotes' ? "Les plus votées" : "Plus récentes",
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

          const Divider(height: 1),

          // Idea List / Empty State
          Expanded(
            child: filteredIdeas.isEmpty
                ? _buildEmptyState(context, ideaState)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: filteredIdeas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final idea = filteredIdeas[index];
                      final isUpvoted = idea.isUpvotedBy(currentUserId);

                      return _IdeaCard(
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
                  "Ajouter une idée en vrac 💡",
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

  Widget _buildEmptyState(BuildContext context, IdeaState ideaState) {
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
                ? "Aucune idée dans ${ideaState.selectedCategory!.labelFr}"
                : "La banque d'idées est vide !",
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Ajoutez des restos à tester, des spots à visiter ou des activités à faire ensemble pour piocher dedans plus tard !",
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
              "Inspirations rapides :",
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
                _buildStarterChip("Tester un resto de ramen 🍜", IdeaCategory.food),
                _buildStarterChip("Coucher de soleil au belvédère 🌅", IdeaCategory.place),
                _buildStarterChip("Soirée escape game 🕵️", IdeaCategory.activity),
                _buildStarterChip("Soirée jeux de société 🎲", IdeaCategory.activity),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarterChip(String text, IdeaCategory category) {
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

class _IdeaCard extends StatelessWidget {
  final BankIdea idea;
  final bool isUpvoted;
  final VoidCallback onUpvote;
  final VoidCallback onDelete;

  const _IdeaCard({
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
                          idea.category.labelFr,
                          style: GoogleFonts.fredoka(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "• par ${idea.creatorName}",
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
