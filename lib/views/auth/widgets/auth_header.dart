import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The header section of the authentication screen containing the logo,
/// title, and subtitle.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      children: [
        // App Brand Icon
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.asset(
            'assets/app_icon.png',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),

        // App Title & Tagline
        Text(
          "Super Planner 🗓️",
          style: GoogleFonts.fredoka(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Collaborative shared calendar for groups, friends, and couples ✨",
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
