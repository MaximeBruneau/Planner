import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/utils/date_utils_helper.dart';

/// Pre-made categories for loose ideas in the Idea Bank
enum IdeaCategory {
  food,
  place,
  activity,
  sex,
  other;

  String get label {
    switch (this) {
      case IdeaCategory.food:
        return 'Food & Drinks';
      case IdeaCategory.place:
        return 'Places & Spots';
      case IdeaCategory.activity:
        return 'Activities & Fun';
      case IdeaCategory.sex:
        return 'Sex & Intimacy';
      case IdeaCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case IdeaCategory.food:
        return '🍔';
      case IdeaCategory.place:
        return '📍';
      case IdeaCategory.activity:
        return '🎯';
      case IdeaCategory.sex:
        return '🌶️';
      case IdeaCategory.other:
        return '💡';
    }
  }

  IconData get icon {
    switch (this) {
      case IdeaCategory.food:
        return Icons.restaurant_rounded;
      case IdeaCategory.place:
        return Icons.location_on_rounded;
      case IdeaCategory.activity:
        return Icons.celebration_rounded;
      case IdeaCategory.sex:
        return Icons.local_fire_department_rounded;
      case IdeaCategory.other:
        return Icons.lightbulb_outline_rounded;
    }
  }

  static IdeaCategory fromString(String? val) {
    if (val == null) return IdeaCategory.other;
    final normalized = val.toLowerCase();
    if (normalized == 'sex' ||
        normalized == 'sexy' ||
        normalized == 'intimate' ||
        normalized == 'intime' ||
        normalized == 'spicy') {
      return IdeaCategory.sex;
    }
    return IdeaCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == normalized,
      orElse: () => IdeaCategory.other,
    );
  }
}

/// Represents a loose idea stored in the collaborative Idea Bank.
class BankIdea {
  final String id;
  final String spaceId;
  final String title;
  final IdeaCategory category;
  final String? note;
  final String creatorId;
  final String creatorName;
  final String? creatorPhotoUrl;
  final List<String> upvoterIds;
  final String? lastModifiedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;

  BankIdea({
    required this.id,
    required this.spaceId,
    required this.title,
    this.category = IdeaCategory.other,
    this.note,
    required this.creatorId,
    required this.creatorName,
    this.creatorPhotoUrl,
    List<String>? upvoterIds,
    this.lastModifiedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deleted = false,
  })  : upvoterIds = upvoterIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int get upvoteCount => upvoterIds.length;
  bool isUpvotedBy(String userId) => upvoterIds.contains(userId);

  BankIdea copyWith({
    String? id,
    String? spaceId,
    String? title,
    IdeaCategory? category,
    String? note,
    String? creatorId,
    String? creatorName,
    String? creatorPhotoUrl,
    List<String>? upvoterIds,
    String? lastModifiedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deleted,
  }) {
    return BankIdea(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      title: title ?? this.title,
      category: category ?? this.category,
      note: note ?? this.note,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorPhotoUrl: creatorPhotoUrl ?? this.creatorPhotoUrl,
      upvoterIds: upvoterIds ?? List<String>.from(this.upvoterIds),
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'spaceId': spaceId,
      'title': title,
      'category': category.name,
      'note': note,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorPhotoUrl': creatorPhotoUrl,
      'upvoterIds': upvoterIds,
      'lastModifiedBy': lastModifiedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deleted': deleted,
    };
  }

  factory BankIdea.fromMap(Map<String, dynamic> map) {
    final rawUpvoters = map['upvoterIds'] as List?;
    final upvoters = <String>[];
    if (rawUpvoters != null) {
      for (final u in rawUpvoters) {
        upvoters.add(u.toString());
      }
    }

    return BankIdea(
      id: map['id'] as String? ?? '',
      spaceId: map['spaceId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      category: IdeaCategory.fromString(map['category'] as String?),
      note: map['note'] as String?,
      creatorId: map['creatorId'] as String? ?? '',
      creatorName: map['creatorName'] as String? ?? 'Member',
      creatorPhotoUrl: map['creatorPhotoUrl'] as String?,
      upvoterIds: upvoters,
      lastModifiedBy: map['lastModifiedBy'] as String?,
      createdAt: DateUtilsHelper.parseDateTime(map['createdAt']),
      updatedAt: DateUtilsHelper.parseDateTime(map['updatedAt']),
      deleted: map['deleted'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory BankIdea.fromJson(String source) =>
      BankIdea.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
