import 'dart:convert';
import '../core/constants/default_emojis.dart';

class AppSettings {
  final int themeIndex;
  final List<String> customEmojis;
  final String notificationTime; // e.g. "21:00"
  final bool notificationsEnabled;

  AppSettings({
    this.themeIndex = 0,
    List<String>? customEmojis,
    this.notificationTime = "21:00",
    this.notificationsEnabled = true,
  }) : customEmojis = customEmojis ?? List<String>.from(DefaultEmojis.list);

  AppSettings copyWith({
    int? themeIndex,
    List<String>? customEmojis,
    String? notificationTime,
    bool? notificationsEnabled,
  }) {
    return AppSettings(
      themeIndex: themeIndex ?? this.themeIndex,
      customEmojis: customEmojis ?? List<String>.from(this.customEmojis),
      notificationTime: notificationTime ?? this.notificationTime,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeIndex': themeIndex,
      'customEmojis': customEmojis,
      'notificationTime': notificationTime,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    final rawEmojis = map['customEmojis'] as List?;
    final emojis = rawEmojis != null
        ? List<String>.from(rawEmojis)
        : List<String>.from(DefaultEmojis.list);

    return AppSettings(
      themeIndex: (map['themeIndex'] as num?)?.toInt() ?? 0,
      customEmojis: emojis,
      notificationTime: map['notificationTime'] as String? ?? "21:00",
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppSettings.fromJson(String source) =>
      AppSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
