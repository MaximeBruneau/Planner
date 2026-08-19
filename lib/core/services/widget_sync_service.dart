import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../../models/mood_entry.dart';
import '../../models/partner_info.dart';
import '../utils/date_utils_helper.dart';

class WidgetSyncService {
  static const String appGroupId = 'group.com.vibecalendar.myDairy';
  static const String androidWidgetName = 'DuoVibeWidgetProvider';
  static const String iOSWidgetName = 'DuoVibeWidget';

  static bool _initialized = false;

  /// Initialize HomeWidget with iOS App Group
  static Future<void> init() async {
    if (_initialized || kIsWeb) return;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      _initialized = true;
    } catch (e) {
      debugPrint('HomeWidget initialization notice: $e');
    }
  }

  /// Sync partner mood data to Home Screen Widget for Android & iOS
  static Future<void> syncPartnerMoodWidget({
    required PartnerInfo? partner,
    required Map<String, MoodEntry> partnerEntries,
    int duoStreak = 0,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    try {
      final todayStr = DateUtilsHelper.formatYmd(DateTime.now());

      if (partner == null) {
        // Unpaired state
        await HomeWidget.saveWidgetData<bool>('is_paired', false);
        await HomeWidget.saveWidgetData<String>('partner_name', 'Partenaire');
        await HomeWidget.saveWidgetData<String>('partner_emoji', '');
        await HomeWidget.saveWidgetData<int>('duo_streak', 0);
      } else {
        final partnerFirstName = partner.displayName.isNotEmpty
            ? partner.displayName.split(' ')[0]
            : 'Partenaire';

        // Check if partner logged today and entry is on/after pairing date
        final todayEntry = partnerEntries[todayStr];
        String todayEmoji = '';
        if (todayEntry != null && !todayEntry.deleted) {
          final pairingDay = DateTime(
            partner.pairedAt.year,
            partner.pairedAt.month,
            partner.pairedAt.day,
          );
          final today = DateTime.now();
          final todayDateOnly = DateTime(today.year, today.month, today.day);

          if (!todayDateOnly.isBefore(pairingDay)) {
            todayEmoji = todayEntry.emoji;
          }
        }

        await HomeWidget.saveWidgetData<bool>('is_paired', true);
        await HomeWidget.saveWidgetData<String>('partner_name', partnerFirstName);
        await HomeWidget.saveWidgetData<String>('partner_emoji', todayEmoji);
        await HomeWidget.saveWidgetData<int>('duo_streak', duoStreak);
      }

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: iOSWidgetName,
      );
      debugPrint('Home Screen Widget synchronized successfully.');
    } catch (e) {
      debugPrint('Error updating home screen widget: $e');
    }
  }
}
