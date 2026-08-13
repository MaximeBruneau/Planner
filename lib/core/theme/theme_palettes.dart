import 'package:flutter/material.dart';

class ThemePalette {
  final String name;
  final String emoji;
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
  final bool isDark;

  const ThemePalette({
    required this.name,
    required this.emoji,
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
    this.isDark = false,
  });
}

class AppPalettes {
  static const List<ThemePalette> list = [
    // 0: Pastel Pink
    ThemePalette(
      name: 'Pastel Pink',
      emoji: '🌸',
      primary: Color(0xFF6E2E38),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFF9D6D9),
      onPrimaryContainer: Color(0xFF3B1218),
      secondary: Color(0xFFE88D96),
      surface: Color(0xFFFFF6F7),
      onSurface: Color(0xFF2C181A),
      background: Color(0xFFFFF0F2),
      cardColor: Color(0xFFFFF9FA),
      selectedCellColor: Color(0xFFF5BFC5),
    ),
    // 1: Starry Night
    ThemePalette(
      name: 'Starry Night',
      emoji: '🌌',
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
      isDark: true,
    ),
    // 2: Matcha Green
    ThemePalette(
      name: 'Matcha Green',
      emoji: '🌿',
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
    ),
    // 3: Soft Lavender
    ThemePalette(
      name: 'Soft Lavender',
      emoji: '🪻',
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
    ),
    // 4: Warm Sunset
    ThemePalette(
      name: 'Warm Sunset',
      emoji: '🌅',
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
    ),
    // 5: Cozy Coffee
    ThemePalette(
      name: 'Cozy Coffee',
      emoji: '☕',
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
    ),
    // 6: Ocean Breeze
    ThemePalette(
      name: 'Ocean Breeze',
      emoji: '🌊',
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
    ),
    // 7: Neon Cyberpunk
    ThemePalette(
      name: 'Neon Cyberpunk',
      emoji: '⚡',
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
      isDark: true,
    ),
    // 8: Minimal Light
    ThemePalette(
      name: 'Minimal Light',
      emoji: '⚪',
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
    ),
    // 9: Minimal Dark
    ThemePalette(
      name: 'Minimal Dark',
      emoji: '🖤',
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
      isDark: true,
    ),
  ];
}
