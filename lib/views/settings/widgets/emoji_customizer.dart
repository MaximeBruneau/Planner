import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/default_emojis.dart';
import '../../../models/emoji_pack.dart';
import '../../../providers/settings_provider.dart';
import '../../common/dynamic_paywall_sheet.dart';
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
    final isAllUnlocked = settings.hasActivePremium;
    final unlockedPacksCount = isAllUnlocked
        ? EmojiPacks.list.length
        : settings.unlockedEmojiPacks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Customize Your Active Deck (10 Emojis) 🌿",
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
                color: isAllUnlocked
                    ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                    : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isAllUnlocked
                    ? "🌟 All Unlocked"
                    : "$unlockedPacksCount / ${EmojiPacks.list.length} Packs",
                style: GoogleFonts.fredoka(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isAllUnlocked
                      ? const Color(0xFF2E7D32)
                      : colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Your daily calendar deck holds 10 quick-pick emojis. Tap any slot (1-10) to choose from the 20 Free Starter vibes or your unlocked packs.",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),

        // Couple Streak Milestone Banner (if not yet all unlocked)
        if (!isAllUnlocked) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF0F5), Color(0xFFFFE8D6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFFF758F).withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF758F).withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Text("🔥", style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "30 Duo Flames Milestone Reward",
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4A1521),
                        ),
                      ),
                      Text(
                        "Reach 30 flames together to unlock the exclusive 'Duo & Love' pack, or get all packs with Premium.",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF7A3344),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    DynamicPaywallSheet.show(
                      context,
                      title: "Unlock All Themed Emoji Packs ✨",
                      subtitle:
                          "Enjoy unlimited access to all themed packs with DuoVibe Premium.",
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    backgroundColor: const Color(0xFFE85D75),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Premium",
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 2x5 Grid of 10 Active Deck Emoji Slots
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
            final emoji = index < vibeEmojis.length
                ? vibeEmojis[index]
                : (index < DefaultEmojis.list.length
                    ? DefaultEmojis.list[index]
                    : '😊');
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
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Slot Number in Top-Left Corner
                      Positioned(
                        top: 4,
                        left: 6,
                        child: Text(
                          "#${index + 1}",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      // The Emoji Icon
                      Text(
                        emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 14),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openEmojiPackSelector(context, null),
                icon: const Text("🛍️", style: TextStyle(fontSize: 16)),
                label: Text(
                  "Browse Emoji Packs",
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () async {
                await ref.read(settingsProvider.notifier).updateCustomEmojis(
                      List<String>.from(DefaultEmojis.list.take(10)),
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          "Active deck reset to the 10 starter vibes 🌸"),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                "Reset",
                style: GoogleFonts.fredoka(fontSize: 13),
              ),
            ),
          ],
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom > 0
        ? MediaQuery.of(context).viewInsets.bottom
        : MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.90,
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
                        ? "Choose Emoji for Slot #${targetSlotIndex + 1} 🌸"
                        : "Emoji Packs Store 🛍️",
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    "Pick from the 20 Free Starter vibes or your unlocked packs.",
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
          const SizedBox(height: 10),

          // Scrollable Content
          Expanded(
            child: ListView(
              children: [
                // Themed Emoji Packs List (Free Starter pack with 20 emojis, Themed packs with 10 emojis each)
                ...EmojiPacks.list.map((pack) {
                  final isUnlocked = settings.isEmojiPackUnlocked(pack.id);
                  final isDuoLove = pack.id == 'duo_love';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
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
                                  Row(
                                    children: [
                                      Text(
                                        pack.name,
                                        style: GoogleFonts.fredoka(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      if (isDuoLove && !isUnlocked) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF758F)
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            "🔥 30 Flames",
                                            style: GoogleFonts.fredoka(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFE85D75),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
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
                                  color: const Color(0xFF2E7D32)
                                      .withValues(alpha: 0.12),
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

                        // Pack Emojis Grid (20 for starter, 10 for themed packs)
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
                                        .updateEmoji(
                                          targetSlotIndex,
                                          emojiChar,
                                        );
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
                                              : Colors.grey
                                                  .withValues(alpha: 0.7),
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
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
