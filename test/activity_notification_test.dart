import 'package:flutter_test/flutter_test.dart';
import 'package:super_planner/models/activity_notification.dart';

void main() {
  group('ActivityNotification Model Tests', () {
    test('Serialization and deserialization', () {
      final notif = ActivityNotification(
        id: 'notif_123',
        spaceId: 'space_abc',
        title: 'Alex added "Saturday BBQ" for 2026-08-25',
        date: '2026-08-25',
        authorName: 'Alex',
        authorPhotoUrl: 'https://example.com/alex.jpg',
        type: NotificationType.add,
        createdAt: DateTime(2026, 8, 24, 15, 30),
        isRead: false,
      );

      final map = notif.toMap();
      final fromMap = ActivityNotification.fromMap(map);

      expect(fromMap.id, equals('notif_123'));
      expect(fromMap.spaceId, equals('space_abc'));
      expect(fromMap.title, equals('Alex added "Saturday BBQ" for 2026-08-25'));
      expect(fromMap.date, equals('2026-08-25'));
      expect(fromMap.authorName, equals('Alex'));
      expect(fromMap.authorPhotoUrl, equals('https://example.com/alex.jpg'));
      expect(fromMap.type, equals(NotificationType.add));
      expect(fromMap.isRead, isFalse);
      expect(fromMap.iconEmoji, equals('✨'));
    });

    test('All NotificationType emoji icons are correct', () {
      final base = ActivityNotification(
        id: '1',
        spaceId: 's',
        title: 't',
        date: '2026-08-25',
        authorName: 'a',
        createdAt: DateTime.now(),
      );

      expect(base.copyWith(type: NotificationType.add).iconEmoji, equals('✨'));
      expect(base.copyWith(type: NotificationType.update).iconEmoji, equals('✏️'));
      expect(base.copyWith(type: NotificationType.done).iconEmoji, equals('✅'));
      expect(base.copyWith(type: NotificationType.undone).iconEmoji, equals('🔄'));
      expect(base.copyWith(type: NotificationType.upvote).iconEmoji, equals('👍'));
      expect(base.copyWith(type: NotificationType.delete).iconEmoji, equals('🗑️'));
      expect(base.copyWith(type: NotificationType.join).iconEmoji, equals('👋'));
      expect(base.copyWith(type: NotificationType.ideaAdd).iconEmoji, equals('💡'));
      expect(base.copyWith(type: NotificationType.ideaUpvote).iconEmoji, equals('⭐'));
    });

    test('formattedTimeAgo handles relative timings', () {
      final now = DateTime.now();

      final justNow = ActivityNotification(
        id: '1',
        spaceId: 's',
        title: 't',
        date: '2026-08-25',
        authorName: 'a',
        createdAt: now.subtract(const Duration(seconds: 15)),
      );
      expect(justNow.formattedTimeAgo, equals('Just now'));

      final minsAgo = ActivityNotification(
        id: '2',
        spaceId: 's',
        title: 't',
        date: '2026-08-25',
        authorName: 'a',
        createdAt: now.subtract(const Duration(minutes: 5)),
      );
      expect(minsAgo.formattedTimeAgo, equals('5m ago'));

      final hoursAgo = ActivityNotification(
        id: '3',
        spaceId: 's',
        title: 't',
        date: '2026-08-25',
        authorName: 'a',
        createdAt: now.subtract(const Duration(hours: 3)),
      );
      expect(hoursAgo.formattedTimeAgo, equals('3h ago'));
    });
  });
}
