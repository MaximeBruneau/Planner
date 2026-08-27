import 'dart:convert';
import '../core/utils/date_utils_helper.dart';

enum NotificationType {
  add,
  update,
  done,
  undone,
  upvote,
  delete,
  join,
  ideaAdd,
  ideaUpvote,
}

class ActivityNotification {
  final String id;
  final String spaceId;
  final String title;
  final String date; // yyyy-MM-dd
  final String authorName;
  final String? authorPhotoUrl;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;

  const ActivityNotification({
    required this.id,
    required this.spaceId,
    required this.title,
    required this.date,
    required this.authorName,
    this.authorPhotoUrl,
    this.type = NotificationType.add,
    required this.createdAt,
    this.isRead = false,
  });

  String get iconEmoji {
    switch (type) {
      case NotificationType.add:
        return '✨';
      case NotificationType.update:
        return '✏️';
      case NotificationType.done:
        return '✅';
      case NotificationType.undone:
        return '🔄';
      case NotificationType.upvote:
        return '👍';
      case NotificationType.delete:
        return '🗑️';
      case NotificationType.join:
        return '👋';
      case NotificationType.ideaAdd:
        return '💡';
      case NotificationType.ideaUpvote:
        return '⭐';
    }
  }

  String get formattedTimeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateUtilsHelper.formatShortDate(createdAt);
    }
  }

  ActivityNotification copyWith({
    String? id,
    String? spaceId,
    String? title,
    String? date,
    String? authorName,
    String? authorPhotoUrl,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return ActivityNotification(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      title: title ?? this.title,
      date: date ?? this.date,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'spaceId': spaceId,
      'title': title,
      'date': date,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory ActivityNotification.fromMap(Map<String, dynamic> map) {
    NotificationType parsedType = NotificationType.add;
    final typeStr = map['type'] as String?;
    if (typeStr != null) {
      parsedType = NotificationType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => NotificationType.add,
      );
    }

    return ActivityNotification(
      id: map['id'] as String? ?? '',
      spaceId: map['spaceId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      date: map['date'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Member',
      authorPhotoUrl: map['authorPhotoUrl'] as String?,
      type: parsedType,
      createdAt: DateUtilsHelper.parseDateTime(map['createdAt']),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory ActivityNotification.fromJson(String source) =>
      ActivityNotification.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
