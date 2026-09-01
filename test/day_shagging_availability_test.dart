import 'package:flutter_test/flutter_test.dart';
import 'package:super_planner/models/day_shagging_availability.dart';

void main() {
  group('DayShaggingAvailability Model Tests', () {
    test('Serialization and deserialization', () {
      final item = DayShaggingAvailability(
        id: 'space_1_2026-09-01_u1',
        spaceId: 'space_1',
        date: '2026-09-01',
        userId: 'u1',
        userName: 'Dangerous 老外',
        userPhotoUrl: 'https://example.com/avatar.png',
      );

      final map = item.toMap();
      final restored = DayShaggingAvailability.fromMap(map);

      expect(restored.id, equals('space_1_2026-09-01_u1'));
      expect(restored.spaceId, equals('space_1'));
      expect(restored.date, equals('2026-09-01'));
      expect(restored.userId, equals('u1'));
      expect(restored.userName, equals('Dangerous 老外'));
      expect(restored.userPhotoUrl, equals('https://example.com/avatar.png'));
    });

    test('copyWith works properly', () {
      final item = DayShaggingAvailability(
        id: 'space_1_2026-09-01_u1',
        spaceId: 'space_1',
        date: '2026-09-01',
        userId: 'u1',
        userName: 'Dangerous 老外',
      );

      final updated = item.copyWith(userName: 'Franny');
      expect(updated.userName, equals('Franny'));
      expect(updated.id, equals('space_1_2026-09-01_u1'));
    });

    test('equality and JSON serialization', () {
      final item = DayShaggingAvailability(
        id: 'space_1_2026-09-01_u1',
        spaceId: 'space_1',
        date: '2026-09-01',
        userId: 'u1',
        userName: 'Dangerous 老外',
      );

      final jsonStr = item.toJson();
      final fromJson = DayShaggingAvailability.fromJson(jsonStr);

      expect(fromJson, equals(item));
      expect(fromJson.hashCode, equals(item.hashCode));
    });
  });
}
