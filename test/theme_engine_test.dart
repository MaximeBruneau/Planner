import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_dairy/core/theme/app_theme.dart';
import 'package:my_dairy/core/theme/theme_palettes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Theme Palettes & Engine Tests', () {
    test('AppPalettes list contains exactly 14 themes', () {
      expect(AppPalettes.list.length, equals(14));
    });

    test('Pastel Pink is free by default and default theme', () {
      final pastel = AppPalettes.getById('pastel_pink');
      expect(pastel.id, equals('pastel_pink'));
      expect(pastel.isFreeByDefault, isTrue);
      expect(pastel.emoji, equals('🌸'));
    });

    test('All other 13 themes are paid/unlockable', () {
      final paidThemes = AppPalettes.paidThemeIds;
      expect(paidThemes.length, equals(13));
      for (final id in paidThemes) {
        final palette = AppPalettes.getById(id);
        expect(palette.isFreeByDefault, isFalse);
      }
      expect(AppPalettes.getById('christmas_magic').name, equals('Christmas Magic'));
      expect(AppPalettes.getById('christmas_magic').emoji, equals('🎄'));
    });

    test('Specific dark themes are correctly flagged', () {
      expect(AppPalettes.getById('starry_night').isDark, isTrue);
      expect(AppPalettes.getById('neon_cyberpunk').isDark, isTrue);
      expect(AppPalettes.getById('minimal_dark').isDark, isTrue);
      expect(AppPalettes.getById('light_blue').isDark, isFalse);
      expect(AppPalettes.getById('pastel_pink').isDark, isFalse);
    });

    test('Fallback to Pastel Pink on unknown theme ID or index out of bounds', () {
      final fallbackId = AppPalettes.getById('unknown_theme_123');
      expect(fallbackId.id, equals('pastel_pink'));

      final fallbackIndex = AppPalettes.getByIndex(999);
      expect(fallbackIndex.id, equals('pastel_pink'));
    });

    test('AppTheme generates valid ThemeData with Material 3 for all 13 themes', () {
      for (final palette in AppPalettes.list) {
        final themeData = AppTheme.getThemeById(palette.id);
        expect(themeData.useMaterial3, isTrue);
        expect(themeData.scaffoldBackgroundColor, equals(palette.background));
        expect(themeData.cardColor, equals(palette.cardColor));
        expect(themeData.colorScheme.primary, equals(palette.primary));
        expect(themeData.brightness,
            palette.isDark ? Brightness.dark : Brightness.light);
      }
    });
  });
}
