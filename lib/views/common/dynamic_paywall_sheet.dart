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
      return "Débloque ${widget.targetTheme!.name} ✨";
    }
    if (widget.targetEmojiPack != null) {
      return "Débloque le pack ${widget.targetEmojiPack!.name} 🛍️";
    }
    if (widget.featureName != null) {
      return "Débloque ${widget.featureName} ✨";
    }
    return "Passe à DuoVibe Premium ✨";
  }

  String _computeSubtitle() {
    if (widget.subtitle != null) return widget.subtitle!;
    if (widget.targetTheme != null) {
      return "Profite de ce thème vibrant et de tous les futurs designs en illimité.";
    }
    if (widget.targetEmojiPack != null) {
      return "Exprime chaque nuance de ton quotidien à deux sans aucune restriction.";
    }
    return "Partagez vos émotions sans limites avec la version complète pour vous deux.";
  }

  Future<void> _handleSubscriptionPurchase() async {
    String productName;
    String priceFormatted;
    String billingPeriod;
    String productEmoji;

    switch (_selectedTier) {
      case SubscriptionTier.yearlyWithTrial:
        productName = "DuoVibe Premium Annuel";
        priceFormatted = "19,99 €";
        billingPeriod = "Abonnement annuel (7 jours d'essai gratuit)";
        productEmoji = "⭐";
        break;
      case SubscriptionTier.duoPass:
        productName = "Pass Duo Annuel (2 Comptes)";
        priceFormatted = "29,99 €";
        billingPeriod = "Abonnement annuel partagé à deux";
        productEmoji = "🐰";
        break;
      case SubscriptionTier.monthly:
        productName = "DuoVibe Premium Mensuel";
        priceFormatted = "2,99 €";
        billingPeriod = "Abonnement mensuel sans engagement";
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
                  ? "🎉 Pass Duo Activé ! Vous et votre partenaire êtes Premium !"
                  : "🌟 Bienvenue dans DuoVibe Premium ! Tout est débloqué !",
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
    String productName = "Élément Premium";
    String priceFormatted = "1,99 €";
    String billingPeriod = "Achat unique à vie";
    String productEmoji = "✨";

    if (widget.targetTheme != null) {
      productName = "Thème ${widget.targetTheme!.name}";
      priceFormatted = "1,99 €";
      billingPeriod = "Achat unique à vie";
      productEmoji = widget.targetTheme!.emoji;
    } else if (widget.targetEmojiPack != null) {
      productName = "Pack ${widget.targetEmojiPack!.name}";
      priceFormatted = "0,99 €";
      billingPeriod = "Achat unique à vie";
      productEmoji = widget.targetEmojiPack!.emoji;
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
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🎉 $productName débloqué avec succès !",
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
                ? "✨ Achats et abonnement DuoVibe Premium restaurés !"
                : "Restauration terminée (${result['themes']?.length ?? 1} thèmes disponibles).",
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

    final hasSingleItemOption =
        widget.targetTheme != null || widget.targetEmojiPack != null;
    final singleItemLabel = widget.targetTheme != null
        ? "Acheter uniquement ce thème (1,99 € à vie)"
        : (widget.targetEmojiPack != null
            ? "Acheter uniquement ce pack (0,99 € à vie)"
            : "");

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
                    tooltip: "Fermer",
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
                    title: "Accès Illimité à TOUS les émojis",
                    subtitle: "Sélecteur clavier natif complet + tous les packs actuels & futurs",
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitRow(
                    icon: "🎨",
                    title: "Tous les 13+ Thèmes Débloqués",
                    subtitle: "Palettes claires, sombres et cyberpunk illimitées",
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitRow(
                    icon: "📲",
                    title: "Widgets Écran d'Accueil",
                    subtitle: "Suivez l'humeur en direct de votre partenaire en un coup d'œil",
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
              badgeText: "⭐ OFFRE STAR • 7 JOURS GRATUITS",
              title: "Annuel (Essai 7 jours inclus)",
              priceSubtitle: "19,99 € / an (soit ~1,66 € / mois)",
              isPopular: true,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 10),

            // 2. Duo Pass Yearly
            _buildSubscriptionOptionCard(
              tier: SubscriptionTier.duoPass,
              badgeText: "🐰 PASS DUO • POUR VOUS 2",
              title: "Pass Duo Annuel",
              priceSubtitle: "29,99 € / an (Débloque les 2 comptes)",
              isPopular: false,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 10),

            // 3. Monthly Plan
            _buildSubscriptionOptionCard(
              tier: SubscriptionTier.monthly,
              badgeText: "⚡ SANS ENGAGEMENT",
              title: "Mensuel",
              priceSubtitle: "2,99 € / mois (Annulable quand vous voulez)",
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
                            ? "Démarrer l'essai gratuit de 7 jours ✨"
                            : (_selectedTier == SubscriptionTier.duoPass
                                ? "Débloquer le Pass Duo (29,99 €) 🐰"
                                : "Souscrire pour 2,99 € / mois 🌸"),
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
                    "Restaurer les achats",
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
              "Abonnement renouvelable automatiquement. Annulable à tout moment depuis les réglages de votre compte store au moins 24h avant la fin de la période.",
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
