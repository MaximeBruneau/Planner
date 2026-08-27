import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/auth_provider.dart';

/// A button that initiates the Google sign-in process.
class GoogleSignInButton extends ConsumerWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);
    
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: authState.isLoading
            ? null
            : () => ref.read(authProvider.notifier).signInWithGoogle(),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 1,
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.g_mobiledata_rounded, 
                size: 26, 
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Continue with Google",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
