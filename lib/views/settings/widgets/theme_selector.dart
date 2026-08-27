import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme_palettes.dart';
import '../../../providers/settings_provider.dart';

class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final currentThemeId = settings.themeId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Color Palette & Themes 🎨",
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
                "All 13 Free ✨",
                style: GoogleFonts.fredoka(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "Personalize your Super Planner experience with any of these aesthetic themes.",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.3,
          ),
          itemCount: AppPalettes.list.length,
          itemBuilder: (context, index) {
            final palette = AppPalettes.list[index];
            final isSelected = currentThemeId == palette.id;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ref.read(settingsProvider.notifier).updateThemeById(palette.id);
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: palette.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.12),
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: palette.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            palette.emoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              palette.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.fredoka(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: palette.onSurface,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: palette.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: palette.cardColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorScheme.outlineVariant,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: colorScheme.primary,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
