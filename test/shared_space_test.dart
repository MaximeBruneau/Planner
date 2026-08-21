import 'package:flutter_test/flutter_test.dart';
import 'package:super_planner/models/shared_space.dart';

void main() {
  group('SharedSpace & SpaceMember Model Tests', () {
    test('SharedSpace serialization and deserialization', () {
      final member1 = SpaceMember(
        userId: 'u1',
        displayName: 'Camille',
        email: 'camille@example.com',
        role: 'owner',
      );

      final member2 = SpaceMember(
        userId: 'u2',
        displayName: 'Leo',
        email: 'leo@example.com',
        role: 'member',
      );

      final space = SharedSpace(
        id: 'space_001',
        name: 'Weekend Squad 🍕',
        code: 'SUPER-4892',
        creatorId: 'u1',
        memberIds: ['u1', 'u2'],
        members: {'u1': member1, 'u2': member2},
        lastActivityNotice: 'Camille added Saturday Brunch',
      );

      final map = space.toMap();
      final restored = SharedSpace.fromMap(map);

      expect(restored.id, equals('space_001'));
      expect(restored.name, equals('Weekend Squad 🍕'));
      expect(restored.code, equals('SUPER-4892'));
      expect(restored.creatorId, equals('u1'));
      expect(restored.memberCount, equals(2));
      expect(restored.isMember('u1'), isTrue);
      expect(restored.isMember('u2'), isTrue);
      expect(restored.isMember('u3'), isFalse);
      expect(restored.isOwner('u1'), isTrue);
      expect(restored.isOwner('u2'), isFalse);
      expect(restored.members['u1']?.displayName, equals('Camille'));
      expect(restored.members['u2']?.displayName, equals('Leo'));
    });
  });
}
