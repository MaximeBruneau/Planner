import 'package:flutter_test/flutter_test.dart';
import 'package:my_dairy/core/services/widget_sync_service.dart';
import 'package:my_dairy/core/utils/date_utils_helper.dart';
import 'package:my_dairy/models/mood_entry.dart';
import 'package:my_dairy/models/partner_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WidgetSyncService Tests', () {
    test('WidgetSyncService constants are properly configured', () {
      expect(WidgetSyncService.appGroupId, equals('group.com.vibecalendar.myDairy'));
      expect(WidgetSyncService.androidWidgetName, equals('DuoVibeWidgetProvider'));
      expect(WidgetSyncService.iOSWidgetName, equals('DuoVibeWidget'));
    });

    test('syncPartnerMoodWidget executes gracefully when unpaired', () async {
      await WidgetSyncService.syncPartnerMoodWidget(
        partner: null,
        partnerEntries: {},
        duoStreak: 0,
      );
      // No exceptions thrown
    });

    test('syncPartnerMoodWidget executes gracefully with partner logged today', () async {
      final now = DateTime.now();
      final todayStr = DateUtilsHelper.formatYmd(now);

      final partner = PartnerInfo(
        uid: 'partner_test',
        displayName: 'Camille 🌸',
        email: 'camille@example.com',
        pairedAt: now.subtract(const Duration(days: 2)),
      );

      final entries = {
        todayStr: MoodEntry(date: todayStr, emoji: '🥳', note: 'Feeling great!'),
      };

      await WidgetSyncService.syncPartnerMoodWidget(
        partner: partner,
        partnerEntries: entries,
        duoStreak: 3,
      );
      // No exceptions thrown
    });

    test('syncPartnerMoodWidget executes gracefully with partner unlogged today', () async {
      final now = DateTime.now();
      final partner = PartnerInfo(
        uid: 'partner_test',
        displayName: 'Alex',
        email: 'alex@example.com',
        pairedAt: now.subtract(const Duration(days: 2)),
      );

      // No entries for today
      await WidgetSyncService.syncPartnerMoodWidget(
        partner: partner,
        partnerEntries: {},
        duoStreak: 0,
      );
      // No exceptions thrown
    });
  });
}
