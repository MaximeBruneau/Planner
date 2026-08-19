import 'package:flutter/material.dart';
import '../../../core/theme/theme_palettes.dart';
import '../../common/dynamic_paywall_sheet.dart';

class PaywallBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required ThemePalette palette,
  }) {
    return DynamicPaywallSheet.show(
      context,
      targetTheme: palette,
    );
  }
}
