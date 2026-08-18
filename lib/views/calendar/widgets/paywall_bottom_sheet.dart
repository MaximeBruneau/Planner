import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme_palettes.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';

class PaywallBottomSheet extends ConsumerStatefulWidget {
  final ThemePalette palette;

  const PaywallBottomSheet({
    super.key,
    required this.palette,
  });

  static Future<void> show(
    BuildContext context, {
    required ThemePalette palette,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaywallBottomSheet(palette: palette),
    );
  }

  @override
  ConsumerState<PaywallBottomSheet> createState() => _PaywallBottomSheetState();
}

class _PaywallBottomSheetState extends ConsumerState<PaywallBottomSheet> {
  bool _isLoading = false;

  Future<void> _buySingleTheme() async {
    setState(() => _isLoading = true);
    final user = ref.read(authProvider).user;
    final success = await ref
        .read(settingsProvider.notifier)
        .purchaseAndApplyTheme(widget.palette.id, userId: user?.id);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🎉 ${widget.palette.name} theme unlocked and applied!",
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    }
  }

  Future<void> _buyAllThemes() async {
    setState(() => _isLoading = true);
    final user = ref.read(authProvider).user;
    final success = await ref
        .read(settingsProvider.notifier)
        .purchaseAllThemesPack(userId: user?.id);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        await ref
            .read(settingsProvider.notifier)
            .updateThemeById(widget.palette.id);
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "🌟 All 12 Themes unlocked forever! Enjoy your vibrant vibes.",
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    final user = ref.read(authProvider).user;
    await ref
        .read(settingsProvider.notifier)
        .restorePurchases(userId: user?.id);

    if (mounted) {
      setState(() => _isLoading = false);
      final isUnlocked =
          ref.read(settingsProvider).isThemeUnlocked(widget.palette.id);
      if (isUnlocked) {
        await ref
            .read(settingsProvider.notifier)
            .updateThemeById(widget.palette.id);
        if (!mounted) return;
        Navigator.of(context).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUnlocked
                ? "Purchases restored! ${widget.palette.name} is now active."
                : "Purchases restored successfully.",
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final targetPalette = widget.palette;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -6),
          )
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Theme Emoji Avatar & Lock Icon
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: targetPalette.background,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: targetPalette.primary,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: targetPalette.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    targetPalette.emoji,
                    style: const TextStyle(fontSize: 34),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title & Subtitle
            Text(
              "Unlock ${targetPalette.name}",
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Experience a beautifully handcrafted aesthetic with custom calendar cells and vibrant accents.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Color Swatches Preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: targetPalette.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: targetPalette.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSwatch("Primary", targetPalette.primary),
                  _buildSwatch("Secondary", targetPalette.secondary),
                  _buildSwatch("Card", targetPalette.cardColor),
                  _buildSwatch("Selected", targetPalette.selectedCellColor),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Free with Duo Flames Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Text("🔥", style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Free with 50 Duo Flames 🐰",
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Reach 50 consecutive days of duo vibes with your FT to unlock a random paid theme for free!",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else ...[
              // Option 1: Buy this theme
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _buySingleTheme,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Unlock ${targetPalette.name} • \$0.99",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Option 2: All Themes Pack
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _buyAllThemes,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colorScheme.primary, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("⭐ "),
                      Text(
                        "All 12 Themes Pack • \$3.99",
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Restore Purchases
              TextButton(
                onPressed: _restorePurchases,
                child: Text(
                  "Restore Purchases",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSwatch(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12, width: 1),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
