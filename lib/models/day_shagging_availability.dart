import 'dart:convert';
import '../core/utils/date_utils_helper.dart';

/// Represents a member's marked "shaging tool available" status for a specific date in a shared space.
class DayShaggingAvailability {
  /// Unique identifier formatted as `${spaceId}_${date}_${userId}`
  final String id;

  /// The ID of the space this tool availability belongs to
  final String spaceId;

  /// The date formatted as `YYYY-MM-DD`
  final String date;

  /// The ID of the user who made the tool available
  final String userId;

  /// The display name / pseudo of the user
  final String userName;

  /// Optional avatar URL of the user
  final String? userPhotoUrl;

  /// Timestamp when this tool availability was recorded
  final DateTime createdAt;

  DayShaggingAvailability({
    required this.id,
    required this.spaceId,
    required this.date,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a copy of this [DayShaggingAvailability] with updated fields.
  DayShaggingAvailability copyWith({
    String? id,
    String? spaceId,
    String? date,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    DateTime? createdAt,
  }) {
    return DayShaggingAvailability(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Serialize this instance to a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'spaceId': spaceId,
      'date': date,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Deserialize a map into a [DayShaggingAvailability] instance.
  factory DayShaggingAvailability.fromMap(Map<String, dynamic> map) {
    return DayShaggingAvailability(
      id: map['id'] as String? ?? '',
      spaceId: map['spaceId'] as String? ?? '',
      date: map['date'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Member',
      userPhotoUrl: map['userPhotoUrl'] as String?,
      createdAt: DateUtilsHelper.parseDateTime(map['createdAt']),
    );
  }

  /// Serialize to JSON string.
  String toJson() => jsonEncode(toMap());

  /// Deserialize from JSON string.
  factory DayShaggingAvailability.fromJson(String source) =>
      DayShaggingAvailability.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DayShaggingAvailability && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
