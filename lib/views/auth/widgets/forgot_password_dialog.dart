import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/auth_provider.dart';

/// A dialog widget that allows users to request a password reset email.
class ForgotPasswordDialog extends ConsumerStatefulWidget {
  /// The initial email address to pre-fill in the dialog.
  final String initialEmail;

  const ForgotPasswordDialog({
    super.key,
    required this.initialEmail,
  });

  /// Displays the [ForgotPasswordDialog].
  static void show(BuildContext context, String initialEmail) {
    showDialog(
      context: context,
      builder: (ctx) => ForgotPasswordDialog(initialEmail: initialEmail),
    );
  }

  @override
  ConsumerState<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<ForgotPasswordDialog> {
  late final TextEditingController _resetEmailController;

  @override
  void initState() {
    super.initState();
    _resetEmailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _resetEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(Icons.lock_reset_rounded, color: colorScheme.primary, size: 24),
          const SizedBox(width: 8),
          Text(
            "Reset Password 🔑",
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 20),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enter your email address to receive a secure password reset link.",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _resetEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: "Email Address",
              hintText: "you@example.com",
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            final email = _resetEmailController.text.trim();
            if (email.isEmpty || !email.contains('@')) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Please enter a valid email address."),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            final messenger = ScaffoldMessenger.of(context);
            Navigator.pop(context);
            final success = await ref.read(authProvider.notifier).sendPasswordReset(email);
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? "Password reset email sent to $email! ✉️"
                      : "Could not send reset email. Please verify your address.",
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: const Text("Send Link"),
        ),
      ],
    );
  }
}
