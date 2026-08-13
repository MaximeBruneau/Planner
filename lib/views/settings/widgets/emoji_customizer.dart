import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../../providers/settings_provider.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Customize Your 10 Vibe Emojis 🌿",
          style: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Tap any emoji slot below to choose your favorite emoji for your daily palette.",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),

        // 2x5 Grid of Emoji Slots matching mockup
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
                onTap: () => _openEmojiPicker(context, index),
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
      ],
    );
  }

  void _openEmojiPicker(BuildContext context, int slotIndex) {
    setState(() {
      _editingSlotIndex = slotIndex;
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: 400,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select Emoji for Slot #${slotIndex + 1}",
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    )
                  ],
                ),
              ),
              Expanded(
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateEmoji(slotIndex, emoji.emoji);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Slot #${slotIndex + 1} updated to ${emoji.emoji} 🌿"),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  config: Config(
                    height: 300,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                      columns: 7,
                      emojiSizeMax: 28,
                      backgroundColor: colorScheme.surface,
                    ),
                    categoryViewConfig: CategoryViewConfig(
                      backgroundColor: colorScheme.surface,
                      indicatorColor: colorScheme.primary,
                      iconColorSelected: colorScheme.primary,
                      iconColor: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
