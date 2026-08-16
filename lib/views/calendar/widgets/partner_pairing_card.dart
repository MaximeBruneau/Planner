import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/partner_provider.dart';

class PartnerPairingCard extends ConsumerStatefulWidget {
  const PartnerPairingCard({super.key});

  @override
  ConsumerState<PartnerPairingCard> createState() => _PartnerPairingCardState();
}

class _PartnerPairingCardState extends ConsumerState<PartnerPairingCard> {
  final TextEditingController _codeController = TextEditingController();
  bool _isEnteringCode = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Code $code copied to clipboard! 📋"),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);
    final partnerState = ref.watch(partnerProvider);
    final partnerNotifier = ref.read(partnerProvider.notifier);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  "🐰",
                  style: TextStyle(fontSize: 30),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Share with your FT 🐰",
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 6),
            Text(
              "Follow each other's mood in read-only mode.\n100% private & secure between you two 🔒",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),

            if (partnerState.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        partnerState.errorMessage!,
                        style: TextStyle(fontSize: 12, color: colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (authState.user == null) ...[
              Text(
                "You must be signed in with Google to share your calendar.",
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.error, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
                icon: const Icon(Icons.login),
                label: const Text("Sign in with Google"),
              ),
            ] else ...[
              // Generated Code Display
              if (partnerState.generatedCode != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Your invitation code:",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        partnerState.generatedCode!,
                        style: GoogleFonts.fredoka(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _copyToClipboard(partnerState.generatedCode!),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text("Copy Code"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Redeem / Enter Code Section
              if (_isEnteringCode) ...[
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: "Enter your FT's code",

                    hintText: "e.g. VIBE-4892",
                    prefixIcon: const Icon(Icons.key_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isEnteringCode = false;
                            _codeController.clear();
                          });
                        },
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: partnerState.isLoading
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final success = await partnerNotifier.redeemCode(
                                  _codeController.text,
                                  authState.user!,
                                );
                                if (success && mounted) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text("Calendars connected successfully! 🐰"),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        child: partnerState.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Submit 🐰"),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: partnerState.isLoading
                            ? null
                            : () => partnerNotifier.generateCode(authState.user!),
                        icon: const Icon(Icons.qr_code_rounded, size: 18),
                        label: const Text("Create Code"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isEnteringCode = true;
                          });
                        },
                        icon: const Icon(Icons.add_link_rounded, size: 18),
                        label: const Text("Enter Code"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
