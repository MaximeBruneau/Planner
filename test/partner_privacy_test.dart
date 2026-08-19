import 'package:flutter_test/flutter_test.dart';
import 'package:my_dairy/core/services/partner_service.dart';
import 'package:my_dairy/core/services/storage_service.dart';
import 'package:my_dairy/models/mood_entry.dart';
import 'package:my_dairy/models/partner_info.dart';
import 'package:my_dairy/providers/partner_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late PartnerService partnerService;
  late PartnerNotifier partnerNotifier;

  final pairingDate = DateTime(2026, 8, 15);
  final testPartner = PartnerInfo(
    uid: 'partner_123',
    displayName: 'Sweetheart',
    email: 'partner@example.com',
    pairedAt: pairingDate,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = StorageService();
    await storageService.init();
    partnerService = PartnerService(storageService);
    partnerNotifier = PartnerNotifier(partnerService, storageService);
  });

  group('Partner History Privacy Tests (Pre-Pairing Protection)', () {
    test('getPartnerEntryForDate returns null for dates prior to pairedAt', () {
      // Simulate partner entries existing before and after pairing date
      final entries = {
        '2026-08-10': MoodEntry(date: '2026-08-10', emoji: '😢', note: 'Old private note'),
        '2026-08-14': MoodEntry(date: '2026-08-14', emoji: '😴'),
        '2026-08-15': MoodEntry(date: '2026-08-15', emoji: '🥰', note: 'Day of pairing!'),
        '2026-08-16': MoodEntry(date: '2026-08-16', emoji: '✨'),
      };

      partnerNotifier.state = partnerNotifier.state.copyWith(
        partnerInfo: testPartner,
        partnerEntries: entries,
      );

      // Prior to pairing date -> Must return null
      expect(
        partnerNotifier.getPartnerEntryForDate(DateTime(2026, 8, 10)),
        isNull,
      );
      expect(
        partnerNotifier.getPartnerEntryForDate(DateTime(2026, 8, 14)),
        isNull,
      );

      // On or after pairing date -> Visible
      expect(
        partnerNotifier.getPartnerEntryForDate(DateTime(2026, 8, 15)),
        isNotNull,
      );
      expect(
        partnerNotifier.getPartnerEntryForDate(DateTime(2026, 8, 15))?.emoji,
        equals('🥰'),
      );
      expect(
        partnerNotifier.getPartnerEntryForDate(DateTime(2026, 8, 16))?.emoji,
        equals('✨'),
      );
    });

    test('unpair cleans provider state and local storage', () async {
      partnerNotifier.state = partnerNotifier.state.copyWith(
        partnerInfo: testPartner,
        partnerEntries: {
          '2026-08-15': MoodEntry(date: '2026-08-15', emoji: '🥰'),
        },
      );
      await storageService.savePartner(testPartner);

      expect(partnerNotifier.state.isPaired, isTrue);

      await partnerNotifier.unpair(null);

      expect(partnerNotifier.state.isPaired, isFalse);
      expect(partnerNotifier.state.partnerInfo, isNull);
      expect(partnerNotifier.state.partnerEntries, isEmpty);
      expect(storageService.getSavedPartner(), isNull);
      expect(storageService.getPartnerEntries(), isEmpty);
    });
  });
}

