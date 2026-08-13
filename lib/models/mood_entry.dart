import 'dart:convert';

class MoodEntry {
  final String date; // Format: yyyy-MM-dd
  final String emoji;
  final String note;
  final DateTime updatedAt;

  MoodEntry({
    required this.date,
    required this.emoji,
    this.note = '',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  MoodEntry copyWith({
    String? date,
    String? emoji,
    String? note,
    DateTime? updatedAt,
  }) {
    return MoodEntry(
      date: date ?? this.date,
      emoji: emoji ?? this.emoji,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'emoji': emoji,
      'note': note,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      date: map['date'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '😊',
      note: map['note'] as String? ?? '',
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory MoodEntry.fromJson(String source) =>
      MoodEntry.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'MoodEntry(date: $date, emoji: $emoji, note: $note, updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MoodEntry &&
        other.date == date &&
        other.emoji == emoji &&
        other.note == note &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode =>
      date.hashCode ^ emoji.hashCode ^ note.hashCode ^ updatedAt.hashCode;
}
