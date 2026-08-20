import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/purchases_service.dart';
import '../../core/theme/theme_palettes.dart';
import '../../models/emoji_pack.dart';
import '../../providers/auth_provider.dart';
import '../../providers/partner_provider.dart';
import '../../providers/settings_provider.dart';
import 'fake_store_payment_sheet.dart';

class DynamicPaywallSheet extends ConsumerStatefulWidget {
  final String? title;
  final String? subtitle;
  final ThemePalette? targetTheme;
  final EmojiPack? targetEmojiPack;
  final String? featureName;

  const DynamicPaywallSheet({
    super.key,
    this.title,
    this.subtitle,
    this.targetTheme,
    this.targetEmojiPack,
    this.featureName,
  });

  static Future<void> show(
    BuildContext context, {
    String? title,
    String? subtitle,
    ThemePalette? targetTheme,
    EmojiPack? targetEmojiPack,
    String? featureName,
  }) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DynamicPaywallSheet(
        title: title,
        subtitle: subtitle,
        targetTheme: targetTheme,
        targetEmojiPack: targetEmojiPack,
        featureName: featureName,
      ),
    );
  }

  @override
  ConsumerState<DynamicPaywallSheet> createState() =>
      _DynamicPaywallSheetState();
}

class _DynamicPaywallSheetState extends ConsumerState<DynamicPaywallSheet> {
  SubscriptionTier _selectedTier = SubscriptionTier.yearlyWithTrial;
  bool _isLoading = false;

  String _computeTitle() {
    if (widget.title != null) return widget.title!;
    if (widget.targetTheme != null) {
      return "Unlock ${widget.targetTheme!.name} ✨";
    }
    if (widget.targetEmojiPack != null) {
      return "Unlock the ${widget.targetEmojiPack!.name} Pack 🛍️";
    }
    if (widget.featureName != null) {
      return "Unlock ${widget.featureName} ✨";
    }
    return "Upgrade to DuoVibe Premium ✨";
  }

  String _computeSubtitle() {
    if (widget.subtitle != null) return widget.subtitle!;
    if (widget.targetTheme != null) {
      return "Enjoy this vibrant theme and all future designs with unlimited access.";
    }
    if (widget.targetEmojiPack != null) {
      return "Express every nuance of your daily life together with zero restrictions.";
    }
    return "Share emotions without limits with the complete premium experience for both of you.";
  }

  Future<void> _handleSubscriptionPurchase() async {
    String productName;
    String priceFormatted;
    String billingPeriod;
    String productEmoji;

    switch (_selectedTier) {
      case SubscriptionTier.yearlyWithTrial:
        productName = "DuoVibe Premium Annual";
        priceFormatted = "\$19.99";
        billingPeriod = "Annual subscription (7-day free trial)";
        productEmoji = "⭐";
        break;
      case SubscriptionTier.duoPass:
        productName = "Duo Pass Annual (2 Accounts)";
        priceFormatted = "\$29.99";
        billingPeriod = "Annual subscription shared for both accounts";
        productEmoji = "🐰";
        break;
      case SubscriptionTier.monthly:
        productName = "DuoVibe Premium Monthly";
        priceFormatted = "\$2.99";
        billingPeriod = "Monthly subscription (cancel anytime)";
        productEmoji = "🌸";
        break;
    }

    final paymentConfirmed = await FakeStorePaymentSheet.show(
      context,
      productName: productName,
      priceFormatted: priceFormatted,
      billingPeriod: billingPeriod,
      productEmoji: productEmoji,
    );

    if (!paymentConfirmed) return;

    setState(() => _isLoading = true);
    final user = ref.read(authProvider).user;
    final partner = ref.read(partnerProvider).partnerInfo;

    final success = await ref
        .read(settingsProvider.notifier)
        .purchaseSubscription(
          tier: _selectedTier,
          userId: user?.id,
          partnerId: partner?.uid,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        // If purchased while trying to apply a theme, apply it now
        if (widget.targetTheme != null) {
          await ref
              .read(settingsProvider.notifier)
              .updateThemeById(widget.targetTheme!.id);
        }

        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedTier == SubscriptionTier.duoPass
                  ? "🎉 Duo Pass Activated! You and your partner are now Premium!"
                  : "🌟 Welcome to DuoVibe Premium! Everything is unlocked!",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    }
  }

  Future<void> _handleSingleItemPurchase() async {
    String productName = "Premium Item";
    String priceFormatted = "\$1.99";
    String billingPeriod = "Lifetime one-time purchase";
    String productEmoji = "✨";

    if (widget.targetTheme != null) {
      productName = "${widget.targetTheme!.name} Theme";
      priceFormatted = "\$1.99";
      billingPeriod = "Lifetime one-time purchase";
      productEmoji = widget.targetTheme!.emoji;
    } else if (widget.targetEmojiPack != null) {
      productName = "${widget.targetEmojiPack!.name} Pack";
      priceFormatted = "\$0.99";
      billingPeriod = "Lifetime one-time purchase";
      productEmoji = widget.targetEmojiPack!.emoji;
    } else {
      productName = "All Emojis & Custom Keyboard Bundle";
      priceFormatted = "\$2.99";
      billingPeriod = "Lifetime one-time purchase";
      productEmoji = "🛍️";
    }

    final paymentConfirmed = await FakeStorePaymentSheet.show(
      context,
      productName: productName,
      priceFormatted: priceFormatted,
      billingPeriod: billingPeriod,
      productEmoji: productEmoji,
    );

    if (!paymentConfirmed) return;

    setState(() => _isLoading = true);
    final user = ref.read(authProvider).user;

    bool success = false;

    if (widget.targetTheme != null) {
      success = await ref
          .read(settingsProvider.notifier)
          .purchaseAndApplyTheme(widget.targetTheme!.id, userId: user?.id);
    } else if (widget.targetEmojiPack != null) {
      success = await ref
          .read(settingsProvider.notifier)
          .purchaseEmojiPack(widget.targetEmojiPack!.id, userId: user?.id);
    } else {
      success = await ref
          .read(settingsProvider.notifier)
          .purchaseAllEmojiPacks(userId: user?.id);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🎉 $productName unlocked successfully!",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);
    final user = ref.read(authProvider).user;
    final partner = ref.read(partnerProvider).partnerInfo;

    final result = await ref
        .read(settingsProvider.notifier)
        .restorePurchases(userId: user?.id, partnerId: partner?.uid);

    if (mounted) {
      setState(() => _isLoading = false);
      final isPremium = ref.read(settingsProvider).hasActivePremium;

      if (widget.targetTheme != null &&
          ref.read(settingsProvider).isThemeUnlocked(widget.targetTheme!.id)) {
        await ref
            .read(settingsProvider.notifier)
            .updateThemeById(widget.targetTheme!.id);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else if (isPremium) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPremium
                ? "✨ DuoVibe Premium subscription and purchases restored!"
                : "Restore completed (${result['themes']?.length ?? 1} themes available).",
            style: GoogleFonts.plusJakartaSans(),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;

    final dynamicTitle = _computeTitle();
    final dynamicSubtitle = _computeSubtitle();

    final hasSingleItemOption = widget.targetTheme != null ||
        widget.targetEmojiPack != null ||
        (widget.featureName != null &&
            widget.featureName!.toLowerCase().contains("emoji")) ||
        (widget.title != null &&
            widget.title!.toLowerCase().contains("emoji"));
    final singleItemLabel = widget.targetTheme != null
        ? "Buy only this theme (\$1.99 lifetime)"
        : (widget.targetEmojiPack != null
            ? "Buy only this pack (\$0.99 lifetime)"
            : "Unlock All Emojis & Keyboard Bundle (\$2.99 lifetime)");

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.92,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar: Drag Handle & Close Button
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: "Close",
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Crown / Sparkle Spotlight Avatar
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.targetTheme?.emoji ??
                        (widget.targetEmojiPack?.emoji ?? "✨"),
                    style: const TextStyle(fontSize: 34),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Title & Subtitle
            Text(
              dynamicTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dynamicSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.4,
                color: colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 18),

            // 3 Major Value Pillars Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  _buildBenefitRow(
                    icon: "🌟",
                    title: "Unlimited Access to ALL Emojis",
                    subtitle: "Full native keyboard picker + all current & future packs",
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitRow(
                    icon: "🎨",
                    title: "All 13+ Themes Unlocked",
                    subtitle: "Unlimited light, dark, and vibrant aesthetic palettes",
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitRow(
                    icon: "📲",
                    title: "Home Screen Widgets",
                    subtitle: "Track your partner's live mood at a glance on your home screen",
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Subscription Options (3 cards)
            // 1. Yearly Star Offer (7-Day Trial)
            _buildSubscriptionOptionCard(
              tier: SubscriptionTier.yearlyWithTrial,
              badgeText: "⭐ BEST VALUE • 7 DAYS FREE",
              title: "Annual (7-day free trial included)",
              priceSubtitle: "\$19.99 / year (~ \$1.66 / mo)",
              isPopular: true,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 10),

            // 2. Duo Pass Yearly
            _buildSubscriptionOptionCard(
              tier: SubscriptionTier.duoPass,
              badgeText: "🐰 DUO PASS • FOR BOTH OF YOU",
              title: "Annual Duo Pass",
              priceSubtitle: "\$29.99 / year (Unlocks both accounts)",
              isPopular: false,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 10),

            // 3. Monthly Plan
            _buildSubscriptionOptionCard(
              tier: SubscriptionTier.monthly,
              badgeText: "⚡ FLEXIBLE",
              title: "Monthly",
              priceSubtitle: "\$2.99 / month (Cancel anytime)",
              isPopular: false,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 18),

            // Primary Subscription Action Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubscriptionPurchase,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : Text(
                        _selectedTier == SubscriptionTier.yearlyWithTrial
                            ? "Start 7-Day Free Trial ✨"
                            : (_selectedTier == SubscriptionTier.duoPass
                                ? "Unlock Duo Pass (\$29.99) 🐰"
                                : "Subscribe for \$2.99 / month 🌸"),
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            // Optional Single Unit Purchase Option (Discreet)
            if (hasSingleItemOption) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _isLoading ? null : _handleSingleItemPurchase,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  singleItemLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Reassurance & Store Compliance
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : _handleRestore,
                  child: Text(
                    "Restore Purchases",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              "Auto-renewable subscription. Cancel anytime in your store account settings at least 24 hours before the end of the current period.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow({
    required String icon,
    required String title,
    required String subtitle,
    required ColorScheme colorScheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionOptionCard({
    required SubscriptionTier tier,
    required String badgeText,
    required String title,
    required String priceSubtitle,
    required bool isPopular,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedTier == tier;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedTier = tier;
          });
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.15),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.4),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPopular
                            ? const Color(0xFFE85D75)
                            : colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.fredoka(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPopular ? Colors.white : colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: GoogleFonts.fredoka(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      priceSubtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
