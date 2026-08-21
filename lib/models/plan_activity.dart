import 'dart:convert';
import '../core/utils/date_utils_helper.dart';

/// Clean, simple plan / idea item for a date in Super Planner
class PlanActivity {
  final String id;
  final String spaceId;
  final String date; // Format: yyyy-MM-dd
  final String title;
  final String? time;
  final bool isDone;
  final String creatorId;
  final String creatorName;
  final String? creatorPhotoUrl;
  final List<String> upvoterIds;
  final String? lastModifiedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;

  PlanActivity({
    required this.id,
    required this.spaceId,
    required this.date,
    required this.title,
    this.time,
    this.isDone = false,
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

  PlanActivity copyWith({
    String? id,
    String? spaceId,
    String? date,
    String? title,
    String? time,
    bool? isDone,
    String? creatorId,
    String? creatorName,
    String? creatorPhotoUrl,
    List<String>? upvoterIds,
    String? lastModifiedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deleted,
  }) {
    return PlanActivity(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      date: date ?? this.date,
      title: title ?? this.title,
      time: time ?? this.time,
      isDone: isDone ?? this.isDone,
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
      'date': date,
      'title': title,
      'time': time,
      'isDone': isDone,
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

  factory PlanActivity.fromMap(Map<String, dynamic> map) {
    // Resilient upvoters
    final rawUpvoters = map['upvoterIds'] as List?;
    final upvoters = <String>[];
    if (rawUpvoters != null) {
      for (final u in rawUpvoters) {
        upvoters.add(u.toString());
      }
    }

    return PlanActivity(
      id: map['id'] as String? ?? '',
      spaceId: map['spaceId'] as String? ?? '',
      date: map['date'] as String? ?? '',
      title: map['title'] as String? ?? '',
      time: map['time'] as String?,
      isDone: map['isDone'] as bool? ?? (map['status'] == 'completed'),
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

  factory PlanActivity.fromJson(String source) =>
      PlanActivity.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
