import 'package:flutter/material.dart';
import '../../../models/emoji_pack.dart';
import '../../common/dynamic_paywall_sheet.dart';

class EmojiPackPaywallBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required EmojiPack targetPack,
  }) {
    return DynamicPaywallSheet.show(
      context,
      targetEmojiPack: targetPack,
    );
  }
}
