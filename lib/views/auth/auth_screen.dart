import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import 'widgets/auth_header.dart';
import 'widgets/google_sign_in_button.dart';
import 'widgets/auth_form.dart';

/// The main authentication screen.
class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AuthHeader(),
                  const SizedBox(height: 28),

                  const GoogleSignInButton(),
                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "or with email",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  const AuthForm(),
                  const SizedBox(height: 16),

                  // Quick Demo / Guest Mode Button
                  TextButton.icon(
                    onPressed: () {
                      ref.read(authProvider.notifier).startAsGuest();
                    },
                    icon: const Icon(Icons.flash_on_rounded, size: 18),
                    label: const Text("Continue as Guest / Try Offline"),
                  ),
                  const SizedBox(height: 12),

                  // Privacy Note
                  Text(
                    "Share your calendar with friends, family, and couples with zero hassle ☁️🔒",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
