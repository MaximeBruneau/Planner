import 'package:flutter_test/flutter_test.dart';
import 'package:super_planner/models/day_unavailability.dart';

void main() {
  group('DayUnavailability Model Tests', () {
    test('DayUnavailability serialization and deserialization', () {
      final unavail = DayUnavailability(
        id: 'space_1_2026-08-31_u1',
        spaceId: 'space_1',
        date: '2026-08-31',
        userId: 'u1',
        userName: 'Dangerous 老外',
        userPhotoUrl: 'https://example.com/avatar.png',
      );

      final map = unavail.toMap();
      final restored = DayUnavailability.fromMap(map);

      expect(restored.id, equals('space_1_2026-08-31_u1'));
      expect(restored.spaceId, equals('space_1'));
      expect(restored.date, equals('2026-08-31'));
      expect(restored.userId, equals('u1'));
      expect(restored.userName, equals('Dangerous 老外'));
      expect(restored.userPhotoUrl, equals('https://example.com/avatar.png'));
    });

    test('DayUnavailability copyWith works properly', () {
      final unavail = DayUnavailability(
        id: 'space_1_2026-08-31_u1',
        spaceId: 'space_1',
        date: '2026-08-31',
        userId: 'u1',
        userName: 'Dangerous 老外',
      );

      final updated = unavail.copyWith(userName: 'Franny');
      expect(updated.userName, equals('Franny'));
      expect(updated.id, equals('space_1_2026-08-31_u1'));
    });

    test('DayUnavailability equality and JSON serialization', () {
      final unavail = DayUnavailability(
        id: 'space_1_2026-08-31_u1',
        spaceId: 'space_1',
        date: '2026-08-31',
        userId: 'u1',
        userName: 'Dangerous 老外',
      );

      final jsonStr = unavail.toJson();
      final fromJson = DayUnavailability.fromJson(jsonStr);

      expect(fromJson, equals(unavail));
      expect(fromJson.hashCode, equals(unavail.hashCode));
    });
  });
}
