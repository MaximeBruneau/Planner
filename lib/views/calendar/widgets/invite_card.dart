import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// A card displaying the space invite code with a copy button.
class InviteCard extends StatelessWidget {
  final String spaceCode;

  const InviteCard({
    super.key,
    required this.spaceCode,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text("🔑", style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                "Shared Calendar Invite Code",
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Share this code with friends, family, or your partner so they can join and plan together!",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  spaceCode,
                  style: GoogleFonts.fredoka(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    letterSpacing: 1.5,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: spaceCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("📋 Code $spaceCode copied to clipboard!"),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text("Copy"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
