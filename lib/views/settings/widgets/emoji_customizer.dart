import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/emoji_pack.dart';
import '../../../providers/settings_provider.dart';
import 'emoji_pack_paywall_bottom_sheet.dart';

class EmojiCustomizer extends ConsumerStatefulWidget {
  const EmojiCustomizer({super.key});

  @override
  ConsumerState<EmojiCustomizer> createState() => _EmojiCustomizerState();
}

class _EmojiCustomizerState extends ConsumerState<EmojiCustomizer> {
  int? _editingSlotIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final vibeEmojis = settings.customEmojis;
    final unlockedPacksCount = settings.unlockedEmojiPacks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Customize Your 10 Vibe Emojis 🌿",
                style: GoogleFonts.fredoka(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$unlockedPacksCount / ${EmojiPacks.list.length} Packs",
                style: GoogleFonts.fredoka(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Tap any emoji slot to replace it with emojis from your unlocked packs or explore new premium packs 🛍️.",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),

        // 2x5 Grid of Emoji Slots
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemCount: 10,
          itemBuilder: (context, index) {
            final emoji = index < vibeEmojis.length ? vibeEmojis[index] : '😊';
            final isEditing = _editingSlotIndex == index;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openEmojiPackSelector(context, index),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isEditing
                        ? colorScheme.primaryContainer
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isEditing
                          ? colorScheme.primary
                          : colorScheme.primary.withValues(alpha: 0.2),
                      width: isEditing ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 14),

        // Button to Open Emoji Store Directly
        OutlinedButton.icon(
          onPressed: () => _openEmojiPackSelector(context, null),
          icon: const Text("🛍️", style: TextStyle(fontSize: 16)),
          label: Text(
            "Browse & Unlock Emoji Packs",
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  void _openEmojiPackSelector(BuildContext context, int? slotIndex) {
    setState(() {
      _editingSlotIndex = slotIndex;
    });

    final targetSlot = slotIndex ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _EmojiPacksSelectorSheet(
          targetSlotIndex: targetSlot,
          isSlotSpecific: slotIndex != null,
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _editingSlotIndex = null;
        });
      }
    });
  }
}

class _EmojiPacksSelectorSheet extends ConsumerWidget {
  final int targetSlotIndex;
  final bool isSlotSpecific;

  const _EmojiPacksSelectorSheet({
    required this.targetSlotIndex,
    required this.isSlotSpecific,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSlotSpecific
                        ? "Choose Emoji (Slot #${targetSlotIndex + 1}) 🌸"
                        : "Emoji Packs Store 🛍️",
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    "Tap any emoji to assign it to your active slots.",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Packs List
          Expanded(
            child: ListView.separated(
              itemCount: EmojiPacks.list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final pack = EmojiPacks.list[index];
                final isUnlocked = settings.isEmojiPackUnlocked(pack.id);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isUnlocked
                          ? colorScheme.primary.withValues(alpha: 0.2)
                          : colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pack Header
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(pack.emoji,
                                  style: const TextStyle(fontSize: 18)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pack.name,
                                  style: GoogleFonts.fredoka(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  pack.description,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isUnlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF2E7D32).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      size: 13, color: Color(0xFF2E7D32)),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Unlocked",
                                    style: GoogleFonts.fredoka(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            InkWell(
                              onTap: () {
                                EmojiPackPaywallBottomSheet.show(
                                  context,
                                  targetPack: pack,
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.lock_rounded,
                                        size: 12, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      pack.price,
                                      style: GoogleFonts.fredoka(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Pack 10 Emojis Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: pack.emojis.length,
                        itemBuilder: (context, emojiIdx) {
                          final emojiChar = pack.emojis[emojiIdx];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (isUnlocked) {
                                  ref
                                      .read(settingsProvider.notifier)
                                      .updateEmoji(targetSlotIndex, emojiChar);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Slot #${targetSlotIndex + 1} updated to $emojiChar ✨",
                                        style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  EmojiPackPaywallBottomSheet.show(
                                    context,
                                    targetPack: pack,
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.outline
                                        .withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text(
                                      emojiChar,
                                      style: TextStyle(
                                        fontSize: 22,
                                        color: isUnlocked
                                            ? null
                                            : Colors.grey.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    if (!isUnlocked)
                                      Positioned(
                                        right: 2,
                                        bottom: 2,
                                        child: Icon(
                                          Icons.lock_rounded,
                                          size: 10,
                                          color: colorScheme.primary
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
