import 'package:flutter/material.dart';

class ThemePalette {
  final String id;
  final String name;
  final String emoji;
  final bool isDark;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color surface;
  final Color onSurface;
  final Color background;
  final Color cardColor;
  final Color selectedCellColor;

  const ThemePalette({
    required this.id,
    required this.name,
    required this.emoji,
    this.isDark = false,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.surface,
    required this.onSurface,
    required this.background,
    required this.cardColor,
    required this.selectedCellColor,
  });
}

class AppPalettes {
  // 0: Pastel Pink 🌸
  static const ThemePalette pastelPink = ThemePalette(
    id: 'pastel_pink',
    name: 'Pastel Pink',
    emoji: '🌸',
    isDark: false,
    primary: Color(0xFFE85D75),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFFDE8EC),
    onPrimaryContainer: Color(0xFF5C1423),
    secondary: Color(0xFFF4978E),
    surface: Color(0xFFFFF9FA),
    onSurface: Color(0xFF2C181A),
    background: Color(0xFFFFF0F2),
    cardColor: Color(0xFFFFFFFF),
    selectedCellColor: Color(0xFFFBC4CB),
  );

  // 1: Light Blue 🐟
  static const ThemePalette lightBlue = ThemePalette(
    id: 'light_blue',
    name: 'Light Blue',
    emoji: '🐟',
    isDark: false,
    primary: Color(0xFF0284C7),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFE0F2FE),
    onPrimaryContainer: Color(0xFF0369A1),
    secondary: Color(0xFF38BDF8),
    surface: Color(0xFFF0F9FF),
    onSurface: Color(0xFF0C4A6E),
    background: Color(0xFFE0F2FE),
    cardColor: Color(0xFFFFFFFF),
    selectedCellColor: Color(0xFFBAE6FD),
  );

  // 2: Deep Ocean 🐠
  static const ThemePalette deepOcean = ThemePalette(
    id: 'deep_ocean',
    name: 'Deep Ocean',
    emoji: '🐠',
    isDark: false,
    primary: Color(0xFF1D4ED8),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFDBEAFE),
    onPrimaryContainer: Color(0xFF1E3A8A),
    secondary: Color(0xFF3B82F6),
    surface: Color(0xFFEFF6FF),
    onSurface: Color(0xFF1E293B),
    background: Color(0xFFDBEAFE),
    cardColor: Color(0xFFFFFFFF),
    selectedCellColor: Color(0xFFBFDBFE),
  );

  // 3: Aqua Lagoon 🐡
  static const ThemePalette aquaLagoon = ThemePalette(
    id: 'aqua_lagoon',
    name: 'Aqua Lagoon',
    emoji: '🐡',
    isDark: false,
    primary: Color(0xFF0891B2),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFCFFAFE),
    onPrimaryContainer: Color(0xFF155E75),
    secondary: Color(0xFF06B6D4),
    surface: Color(0xFFECFEFF),
    onSurface: Color(0xFF083344),
    background: Color(0xFFCFFAFE),
    cardColor: Color(0xFFFFFFFF),
    selectedCellColor: Color(0xFFA5F3FC),
  );

  // 4: Starry Night 🌌
  static const ThemePalette starryNight = ThemePalette(
    id: 'starry_night',
    name: 'Starry Night',
    emoji: '🌌',
    isDark: true,
    primary: Color(0xFFF59E0B),
    onPrimary: Color(0xFF0F172A),
    primaryContainer: Color(0xFF334155),
    onPrimaryContainer: Color(0xFFFDE047),
    secondary: Color(0xFF6366F1),
    surface: Color(0xFF1E293B),
    onSurface: Color(0xFFF8FAFC),
    background: Color(0xFF0F172A),
    cardColor: Color(0xFF1E293B),
    selectedCellColor: Color(0xFF475569),
  );

  // 5: Matcha Green 🌿
  static const ThemePalette matchaGreen = ThemePalette(
    id: 'matcha_green',
    name: 'Matcha Green',
    emoji: '🌿',
    isDark: false,
    primary: Color(0xFF3D5A40),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFD4E0D4),
    onPrimaryContainer: Color(0xFF1B301E),
    secondary: Color(0xFF588157),
    surface: Color(0xFFF4F6F0),
    onSurface: Color(0xFF19261B),
    background: Color(0xFFEAECE4),
    cardColor: Color(0xFFF7F8F4),
    selectedCellColor: Color(0xFFA3B18A),
  );

  // 6: Soft Lavender 🪻
  static const ThemePalette softLavender = ThemePalette(
    id: 'soft_lavender',
    name: 'Soft Lavender',
    emoji: '🪻',
    isDark: false,
    primary: Color(0xFF581C87),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFEDE9FE),
    onPrimaryContainer: Color(0xFF2E1065),
    secondary: Color(0xFFA78BFA),
    surface: Color(0xFFFAF8FF),
    onSurface: Color(0xFF21153B),
    background: Color(0xFFF3F0F9),
    cardColor: Color(0xFFFFFFFF),
    selectedCellColor: Color(0xFFDDD6FE),
  );

  // 7: Warm Sunset 🌅
  static const ThemePalette warmSunset = ThemePalette(
    id: 'warm_sunset',
    name: 'Warm Sunset',
    emoji: '🌅',
    isDark: false,
    primary: Color(0xFFC2410C),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFFFEDD5),
    onPrimaryContainer: Color(0xFF431407),
    secondary: Color(0xFFF97316),
    surface: Color(0xFFFFF7ED),
    onSurface: Color(0xFF2C1609),
    background: Color(0xFFFFF1E6),
    cardColor: Color(0xFFFFFFFF),
    selectedCellColor: Color(0xFFFED7AA),
  );

  // 8: Cozy Coffee ☕
  static const ThemePalette cozyCoffee = ThemePalette(
    id: 'cozy_coffee',
    name: 'Cozy Coffee',
    emoji: '☕',
    isDark: false,
    primary: Color(0xFF451A03),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFFEF3C7),
    onPrimaryContainer: Color(0xFF271305),
    secondary: Color(0xFF92400E),
    surface: Color(0xFFFAF7F2),
    onSurface: Color(0xFF281C14),
    background: Color(0xFFF3EDE4),
    cardColor: Color(0xFFFDFBF7),
    selectedCellColor: Color(0xFFDEB887),
  );

  // 9: Ocean Breeze 🌊
  static const ThemePalette oceanBreeze = ThemePalette(
    id: 'ocean_breeze',
    name: 'Ocean Breeze',
    emoji: '🌊',
    isDark: false,
    primary: Color(0xFF0F766E),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFCCFBF1),
    onPrimaryContainer: Color(0xFF042F2C),
    secondary: Color(0xFF14B8A6),
    surface: Color(0xFFF0FDFA),
    onSurface: Color(0xFF112A28),
    background: Color(0xFFE6F4F1),
    cardColor: Color(0xFFF8FEFD),
    selectedCellColor: Color(0xFF99F6E4),
  );

  // 10: Neon Cyberpunk ⚡
  static const ThemePalette neonCyberpunk = ThemePalette(
    id: 'neon_cyberpunk',
    name: 'Neon Cyberpunk',
    emoji: '⚡',
    isDark: true,
    primary: Color(0xFFEC4899),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF8B5CF6),
    onPrimaryContainer: Colors.white,
    secondary: Color(0xFF06B6D4),
    surface: Color(0xFF18181B),
    onSurface: Color(0xFFFAFAFA),
    background: Color(0xFF09090B),
    cardColor: Color(0xFF27272A),
    selectedCellColor: Color(0xFF3F3F46),
  );

  // 11: Minimal Light ⚪
  static const ThemePalette minimalLight = ThemePalette(
    id: 'minimal_light',
    name: 'Minimal Light',
    emoji: '⚪',
    isDark: false,
    primary: Color(0xFF1E293B),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFE2E8F0),
    onPrimaryContainer: Color(0xFF0F172A),
    secondary: Color(0xFF64748B),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF0F172A),
    background: Color(0xFFF8FAFC),
    cardColor: Color(0xFFFFFFFF),
    selectedCellColor: Color(0xFFCBD5E1),
  );

  // 12: Minimal Dark 🖤
  static const ThemePalette minimalDark = ThemePalette(
    id: 'minimal_dark',
    name: 'Minimal Dark',
    emoji: '🖤',
    isDark: true,
    primary: Color(0xFFF8FAFC),
    onPrimary: Color(0xFF020617),
    primaryContainer: Color(0xFF1E293B),
    onPrimaryContainer: Color(0xFFF8FAFC),
    secondary: Color(0xFF94A3B8),
    surface: Color(0xFF1E293B),
    onSurface: Color(0xFFF8FAFC),
    background: Color(0xFF0F172A),
    cardColor: Color(0xFF1E293B),
    selectedCellColor: Color(0xFF334155),
  );

  static const List<ThemePalette> list = [
    pastelPink,      // 0: 🌸
    lightBlue,       // 1: 🐟
    deepOcean,       // 2: 🐠
    aquaLagoon,      // 3: 🐡
    starryNight,     // 4: 🌌
    matchaGreen,     // 5: 🌿
    softLavender,    // 6: 🪻
    warmSunset,      // 7: 🌅
    cozyCoffee,      // 8: ☕
    oceanBreeze,     // 9: 🌊
    neonCyberpunk,   // 10: ⚡
    minimalLight,    // 11: ⚪
    minimalDark,     // 12: 🖤
  ];

  static ThemePalette getById(String id) {
    return list.firstWhere(
      (palette) => palette.id == id,
      orElse: () => pastelPink,
    );
  }

  static ThemePalette getByIndex(int index) {
    if (index >= 0 && index < list.length) {
      return list[index];
    }
    return pastelPink;
  }

  static int getIndexById(String id) {
    final idx = list.indexWhere((p) => p.id == id);
    return idx >= 0 ? idx : 0;
  }
}
