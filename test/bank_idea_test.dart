import 'package:flutter_test/flutter_test.dart';
import 'package:super_planner/models/bank_idea.dart';

void main() {
  group('BankIdea & IdeaCategory Model Tests', () {
    test('IdeaCategory parsing and properties', () {
      expect(IdeaCategory.fromString('food'), equals(IdeaCategory.food));
      expect(IdeaCategory.fromString('FOOD'), equals(IdeaCategory.food));
      expect(IdeaCategory.fromString('place'), equals(IdeaCategory.place));
      expect(IdeaCategory.fromString('activity'), equals(IdeaCategory.activity));
      expect(IdeaCategory.fromString('sex'), equals(IdeaCategory.sex));
      expect(IdeaCategory.fromString('sexy'), equals(IdeaCategory.sex));
      expect(IdeaCategory.fromString('intimate'), equals(IdeaCategory.sex));
      expect(IdeaCategory.fromString('other'), equals(IdeaCategory.other));
      expect(IdeaCategory.fromString('unknown_val'), equals(IdeaCategory.other));
      expect(IdeaCategory.fromString(null), equals(IdeaCategory.other));

      expect(IdeaCategory.food.emoji, equals('🍔'));
      expect(IdeaCategory.place.emoji, equals('📍'));
      expect(IdeaCategory.activity.emoji, equals('🎯'));
      expect(IdeaCategory.sex.emoji, equals('🌶️'));
      expect(IdeaCategory.other.emoji, equals('💡'));

      expect(IdeaCategory.food.labelFr, contains('Food'));
      expect(IdeaCategory.place.labelFr, contains('Lieux'));
      expect(IdeaCategory.activity.labelFr, contains('Activités'));
      expect(IdeaCategory.sex.labelFr, contains('Sex'));
    });

    test('BankIdea serialization to/from Map and JSON', () {
      final idea = BankIdea(
        id: 'idea_101',
        spaceId: 'space_999',
        title: 'Tester le nouveau resto de ramen',
        category: IdeaCategory.food,
        note: 'Près de la gare, conseillé par Julien',
        creatorId: 'user_1',
        creatorName: 'Alex',
        upvoterIds: ['user_1', 'user_2'],
      );

      final map = idea.toMap();
      expect(map['id'], equals('idea_101'));
      expect(map['category'], equals('food'));
      expect(map['note'], equals('Près de la gare, conseillé par Julien'));
      expect(map['upvoterIds'], equals(['user_1', 'user_2']));

      final restored = BankIdea.fromMap(map);
      expect(restored.id, equals('idea_101'));
      expect(restored.spaceId, equals('space_999'));
      expect(restored.title, equals('Tester le nouveau resto de ramen'));
      expect(restored.category, equals(IdeaCategory.food));
      expect(restored.note, equals('Près de la gare, conseillé par Julien'));
      expect(restored.creatorId, equals('user_1'));
      expect(restored.creatorName, equals('Alex'));
      expect(restored.upvoteCount, equals(2));
      expect(restored.isUpvotedBy('user_1'), isTrue);
      expect(restored.isUpvotedBy('user_2'), isTrue);
      expect(restored.isUpvotedBy('user_3'), isFalse);

      final jsonStr = idea.toJson();
      final fromJson = BankIdea.fromJson(jsonStr);
      expect(fromJson.title, equals(idea.title));
      expect(fromJson.category, equals(idea.category));
    });

    test('BankIdea resilient deserialization with missing/null fields', () {
      final incompleteMap = {
        'id': 'idea_partial',
        'title': 'Spot coucher de soleil',
      };

      final idea = BankIdea.fromMap(incompleteMap);
      expect(idea.id, equals('idea_partial'));
      expect(idea.title, equals('Spot coucher de soleil'));
      expect(idea.category, equals(IdeaCategory.other));
      expect(idea.note, isNull);
      expect(idea.upvoteCount, equals(0));
      expect(idea.deleted, isFalse);
    });

    test('BankIdea copyWith and upvoting', () {
      final idea = BankIdea(
        id: 'idea_202',
        spaceId: 'space_999',
        title: 'Balade en forêt',
        category: IdeaCategory.activity,
        creatorId: 'u1',
        creatorName: 'Sarah',
        upvoterIds: ['u1'],
      );

      expect(idea.upvoteCount, equals(1));
      expect(idea.isUpvotedBy('u1'), isTrue);

      final withNewVote = idea.copyWith(
        upvoterIds: [...idea.upvoterIds, 'u2'],
        category: IdeaCategory.place,
      );

      expect(withNewVote.upvoteCount, equals(2));
      expect(withNewVote.isUpvotedBy('u2'), isTrue);
      expect(withNewVote.category, equals(IdeaCategory.place));
      expect(withNewVote.title, equals('Balade en forêt'));
    });
  });
}
