import 'package:flutter_test/flutter_test.dart';
import 'package:super_planner/models/plan_activity.dart';

void main() {
  group('PlanActivity Simple Model Tests', () {
    test('PlanActivity serialization and deserialization', () {
      final activity = PlanActivity(
        id: 'p1',
        spaceId: 'space_123',
        date: '2026-08-22',
        title: 'Saturday Hike & Picnic',
        isDone: false,
        creatorId: 'u1',
        creatorName: 'Alex',
        upvoterIds: ['u1', 'u2'],
      );

      final map = activity.toMap();
      final restored = PlanActivity.fromMap(map);

      expect(restored.id, equals('p1'));
      expect(restored.spaceId, equals('space_123'));
      expect(restored.date, equals('2026-08-22'));
      expect(restored.title, equals('Saturday Hike & Picnic'));
      expect(restored.isDone, isFalse);
      expect(restored.upvoteCount, equals(2));
      expect(restored.isUpvotedBy('u1'), isTrue);
      expect(restored.isUpvotedBy('u3'), isFalse);
    });

    test('PlanActivity upvote toggle logic', () {
      final activity = PlanActivity(
        id: 'p1',
        spaceId: 'space_123',
        date: '2026-08-22',
        title: 'Beach Volleyball',
        creatorId: 'u1',
        creatorName: 'Alex',
        upvoterIds: ['u1'],
      );

      expect(activity.upvoteCount, equals(1));
      expect(activity.isUpvotedBy('u1'), isTrue);
      expect(activity.isUpvotedBy('u2'), isFalse);

      final withNewVote = activity.copyWith(upvoterIds: [...activity.upvoterIds, 'u2']);
      expect(withNewVote.upvoteCount, equals(2));
      expect(withNewVote.isUpvotedBy('u2'), isTrue);
    });

    test('PlanActivity toggle done state', () {
      final activity = PlanActivity(
        id: 'p1',
        spaceId: 'space_123',
        date: '2026-08-22',
        title: 'Book tennis court',
        creatorId: 'u1',
        creatorName: 'Alex',
        isDone: false,
      );

      expect(activity.isDone, isFalse);
      final completed = activity.copyWith(isDone: true);
      expect(completed.isDone, isTrue);
    });
  });
}
