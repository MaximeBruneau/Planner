import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/partner_provider.dart';
import '../common/dynamic_paywall_sheet.dart';
import 'widgets/emoji_customizer.dart';
import 'widgets/theme_selector.dart';


class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);
    final isPremium = settings.hasActivePremium;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings & Preferences ⚙️",
          style: GoogleFonts.fredoka(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 0: DuoVibe Premium Status / Upgrade Banner
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPremium
                      ? [
                          const Color(0xFFFFD54F),
                          const Color(0xFFFFA000),
                        ]
                      : [
                          colorScheme.primaryContainer,
                          colorScheme.secondaryContainer,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: isPremium
                        ? Colors.amber.withValues(alpha: 0.3)
                        : colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        isPremium ? "👑" : "✨",
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPremium
                              ? (settings.isDuoPass
                                  ? "DuoVibe Pass Duo Active 🐰"
                                  : (settings.premiumGrantedByPartner
                                      ? "DuoVibe Premium (Gifted by Duo) 💖"
                                      : "DuoVibe Premium Active 👑"))
                              : "DuoVibe Premium ✨",
                          style: GoogleFonts.fredoka(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isPremium ? Colors.brown.shade900 : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPremium
                              ? "All 13+ themes, 60+ emojis & full keyboard unlocked."
                              : "Unlock all themes, emojis & couple features.",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isPremium
                                ? Colors.brown.shade800.withValues(alpha: 0.8)
                                : colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isPremium)
                    ElevatedButton(
                      onPressed: () {
                        DynamicPaywallSheet.show(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: const Size(0, 38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "Upgrade",
                        style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),

            // Section 1: Customize Emojis
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18.0),
                child: EmojiCustomizer(),
              ),
            ),
            const SizedBox(height: 18),

            // Section 2: Select Theme
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ThemeSelector(),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            final restored = await ref
                                .read(settingsProvider.notifier)
                                .restorePurchases(userId: authState.user?.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Purchases restored! (${restored['themes']?.length ?? 1} themes available) 🌸",
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.restore_rounded, size: 18),
                          label: const Text("Restaurer"),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () async {
                            await ref
                                .read(settingsProvider.notifier)
                                .resetPurchasesToFree(userId: authState.user?.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    "🔒 Réinitialisé en version gratuite ! Tous les thèmes et packs payants sont reverrouillés pour tester.",
                                  ),
                                  backgroundColor: const Color(0xFFE85D75),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.lock_reset_rounded, size: 18, color: Color(0xFFE85D75)),
                          label: const Text(
                            "Reverrouiller (Test Sandbox)",
                            style: TextStyle(color: Color(0xFFE85D75)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Section 3: Notification Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Notifications & Rappels 🔔",
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Reçois un doux rappel chaque jour si tu n'as pas encore enregistré ton humeur.",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Rappel quotidien",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text("Uniquement si l'humeur du jour n'est pas saisie"),
                      value: settings.notificationsEnabled,
                      activeTrackColor: colorScheme.primary,
                      onChanged: (val) {
                        ref
                            .read(settingsProvider.notifier)
                            .toggleNotifications(val);
                      },
                    ),
                    if (settings.notificationsEnabled) ...[
                      const Divider(height: 20),
                      InkWell(
                        onTap: () async {
                          final timeParts = settings.notificationTime.split(':');
                          final initialHour = int.tryParse(timeParts[0]) ?? 21;
                          final initialMinute = timeParts.length > 1
                              ? (int.tryParse(timeParts[1]) ?? 0)
                              : 0;

                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: initialHour,
                              minute: initialMinute,
                            ),
                            builder: (ctx, child) {
                              return MediaQuery(
                                data: MediaQuery.of(ctx).copyWith(
                                  alwaysUse24HourFormat: true,
                                ),
                                child: child!,
                              );
                            },
                          );

                          if (pickedTime != null) {
                            final formatted =
                                "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                            await ref
                                .read(settingsProvider.notifier)
                                .updateNotificationTime(formatted);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "⏰ Reminder time set to $formatted",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 4.0,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.access_time_rounded,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Reminder Time",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      "Choose your preferred reminder hour",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      settings.notificationTime,
                                      style: GoogleFonts.fredoka(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 15,
                                      color: colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Section 4: Account & Cloud Sync
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Account & Cloud Sync ☁️",
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "Live Synced",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your vibe calendar is continuously backed up to your account in real-time.",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (authState.isSignedIn) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundImage: authState.user?.photoUrl != null
                                ? NetworkImage(authState.user!.photoUrl!)
                                : null,
                            child: authState.user?.photoUrl == null
                                ? Text(
                                    (authState.user?.displayName.isNotEmpty ==
                                            true)
                                        ? authState.user!.displayName[0]
                                            .toUpperCase()
                                        : "👤",
                                    style: const TextStyle(fontSize: 18),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authState.user?.displayName ?? "User",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  authState.user?.email ?? "",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  title: Text(
                                    "Sign Out?",
                                    style: GoogleFonts.fredoka(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                    ),
                                  ),
                                  content: const Text(
                                    "Are you sure you want to sign out? Your entries are safely stored in the cloud and will be restored when you sign in again.",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        Navigator.pop(context);
                                        ref
                                            .read(authProvider.notifier)
                                            .signOut();
                                      },
                                      child: const Text("Sign Out"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text("Sign Out"),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  title: Text(
                                    "Delete Account & Data?",
                                    style: GoogleFonts.fredoka(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.error,
                                      fontSize: 20,
                                    ),
                                  ),
                                  content: const Text(
                                    "This action is permanent. All your mood history, duo links, and account data will be completely deleted.",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        Navigator.pop(ctx);
                                        Navigator.pop(context);
                                        await ref
                                            .read(authProvider.notifier)
                                            .deleteAccountAndData();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.error,
                                        foregroundColor: colorScheme.onError,
                                      ),
                                      child: const Text("Delete Account"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text(
                              "Delete Account",
                              style: TextStyle(
                                color: colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Section 5: Duo Sharing 🐰
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Duo Sharing 🐰",
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Share your calendar in read-only mode securely with your partner.",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer(
                      builder: (context, ref, child) {
                        final partnerState = ref.watch(partnerProvider);
                        if (partnerState.isPaired) {
                          final partner = partnerState.partnerInfo!;
                          return Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        colorScheme.secondaryContainer,
                                    backgroundImage: partner.photoUrl != null
                                        ? NetworkImage(partner.photoUrl!)
                                        : null,
                                    child: partner.photoUrl == null
                                        ? const Text("🐰")
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Connected with ${partner.displayName} 🐰",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          partner.email,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Disconnect Calendars?"),
                                      content: Text(
                                        "Are you sure you want to disconnect from ${partner.displayName}? You will no longer be able to view each other's calendars and duo flames will reset.",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            Navigator.pop(ctx);
                                            await ref
                                                .read(partnerProvider.notifier)
                                                .unpair(authState.user);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "Liaison avec ${partner.displayName} déconnectée.",
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: colorScheme.error,
                                            foregroundColor:
                                                colorScheme.onError,
                                          ),
                                          child: const Text("Disconnect"),
                                        ),

                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.link_off_rounded,
                                    size: 18),
                                label: const Text("Disconnect Partner"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.error,
                                  side: BorderSide(
                                    color: colorScheme.error
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "No partner connected yet.",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.add_link_rounded,
                                    size: 18),
                                label: const Text("Connect on Home 🌸"),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Section 6: Account Security & Data Privacy (GDPR / Store Compliant)
            Card(
              color: colorScheme.errorContainer.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.security_rounded,
                          color: colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Account & Data Privacy 🔒",
                          style: GoogleFonts.fredoka(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "In accordance with Store guidelines and GDPR, you have the right to permanently erase your account, all cloud data, calendar entries, and partner links.",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showDeleteAccountDialog(context, ref);
                        },
                        icon: Icon(
                          Icons.delete_forever_rounded,
                          color: colorScheme.error,
                          size: 18,
                        ),
                        label: Text(
                          "Delete Account & Data",
                          style: GoogleFonts.fredoka(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: colorScheme.error.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Section 7: Legal & Privacy Notice
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    Text(
                      "DuoVibe • 100% Private & Synchronized\nCrafted with care 🌸",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            // Show simple terms modal or snackbar
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Terms of Service • DuoVibe 🌸"),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Text(
                            "Terms of Service",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          "  •  ",
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Privacy Policy • DuoVibe 🔒"),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Text(
                            "Privacy Policy",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Delete Account & Data?",
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "This action is 100% IRREVERSIBLE. It will immediately and permanently:",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "• Delete all your calendar entries & notes.\n• Delete your cloud backup & profile.\n• Disconnect and dissolve your duo partner link.\n• Reset all streaks and Duo Flames.",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Are you completely sure you want to proceed?",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog

              final messenger = ScaffoldMessenger.of(context);
              final success = await ref
                  .read(authProvider.notifier)
                  .deleteAccountAndData();

              if (context.mounted) {
                if (success) {
                  Navigator.of(context).pop(); // Exit settings screen
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text(
                        "Your account and all associated data have been permanently deleted.",
                      ),
                      backgroundColor: colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("Error during deletion. Please try again."),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text("Delete Permanently"),
          ),
        ],
      ),
    );
  }
}
