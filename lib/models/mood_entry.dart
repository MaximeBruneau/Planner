import 'dart:convert';
import '../core/utils/date_utils_helper.dart';

class MoodEntry {
  final String date; // Format: yyyy-MM-dd
  final String emoji;
  final String note;
  final String? userId;
  final DateTime updatedAt;
  final bool deleted;
  final String syncStatus; // 'synced' | 'pending'

  MoodEntry({
    required this.date,
    required this.emoji,
    this.note = '',
    this.userId,
    DateTime? updatedAt,
    this.deleted = false,
    this.syncStatus = 'synced',
  }) : updatedAt = updatedAt ?? DateTime.now();

  MoodEntry copyWith({
    String? date,
    String? emoji,
    String? note,
    String? userId,
    DateTime? updatedAt,
    bool? deleted,
    String? syncStatus,
  }) {
    return MoodEntry(
      date: date ?? this.date,
      emoji: emoji ?? this.emoji,
      note: note ?? this.note,
      userId: userId ?? this.userId,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'emoji': emoji,
      'note': note,
      'userId': userId,
      'updatedAt': updatedAt.toIso8601String(),
      'deleted': deleted,
      'syncStatus': syncStatus,
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      date: map['date'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '😊',
      note: map['note'] as String? ?? '',
      userId: map['userId'] as String?,
      updatedAt: DateUtilsHelper.parseDateTime(map['updatedAt']),
      deleted: map['deleted'] as bool? ?? false,
      syncStatus: map['syncStatus'] as String? ?? 'synced',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory MoodEntry.fromJson(String source) =>
      MoodEntry.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'MoodEntry(date: $date, emoji: $emoji, note: $note, userId: $userId, updatedAt: $updatedAt, deleted: $deleted, syncStatus: $syncStatus)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MoodEntry &&
        other.date == date &&
        other.emoji == emoji &&
        other.note == note &&
        other.userId == userId &&
        other.deleted == deleted &&
        other.syncStatus == syncStatus;
  }

  @override
  int get hashCode =>
      date.hashCode ^
      emoji.hashCode ^
      note.hashCode ^
      (userId?.hashCode ?? 0) ^
      deleted.hashCode ^
      syncStatus.hashCode;
}
