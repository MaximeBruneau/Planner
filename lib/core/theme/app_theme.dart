import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_palettes.dart';

/// Builds [ThemeData] from the app's custom [ThemePalette] definitions.
///
/// Uses Material 3 with Google Fonts (Fredoka for titles, Plus Jakarta Sans for body).
class AppTheme {
  /// Returns a [ThemeData] for the palette matching [id].
  static ThemeData getThemeById(String id) {
    final palette = AppPalettes.getById(id);
    return _buildTheme(palette);
  }

  /// Returns a [ThemeData] for the palette at [index].
  static ThemeData getTheme(int index) {
    final palette = AppPalettes.getByIndex(index);
    return _buildTheme(palette);
  }

  static ThemeData _buildTheme(ThemePalette palette) {
    final colorScheme = ColorScheme(
      brightness: palette.isDark ? Brightness.dark : Brightness.light,
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      primaryContainer: palette.primaryContainer,
      onPrimaryContainer: palette.onPrimaryContainer,
      secondary: palette.secondary,
      onSecondary: Colors.white,
      surface: palette.surface,
      onSurface: palette.onSurface,
      error: palette.isDark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A),
      onError: palette.isDark ? const Color(0xFF690005) : Colors.white,
    );

    final baseTextTheme = palette.isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    final customTextTheme =
        GoogleFonts.plusJakartaSansTextTheme(baseTextTheme).copyWith(
      titleLarge: GoogleFonts.fredoka(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: palette.onSurface,
      ),
      titleMedium: GoogleFonts.fredoka(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: palette.onSurface,
      ),
      titleSmall: GoogleFonts.fredoka(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: palette.onSurface,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: palette.onSurface,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: palette.onSurface.withValues(alpha: 0.8),
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: palette.onSurface.withValues(alpha: 0.6),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      cardColor: palette.cardColor,
      textTheme: customTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: palette.onSurface),
        titleTextStyle: GoogleFonts.fredoka(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: palette.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: palette.primary.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: palette.primaryContainer.withValues(alpha: 0.2),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: const Size(64, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.fredoka(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          side: BorderSide(color: palette.primary.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: const Size(64, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.fredoka(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: palette.primary.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: palette.primary.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: palette.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}
