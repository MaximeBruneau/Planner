import 'dart:convert';

class AppSettings {
  final int themeIndex;
  final String themeId;
  final String notificationTime; // e.g. "21:00"
  final bool notificationsEnabled;
  final bool groupActivityNotifications; // Notify on new group ideas, modifications, checklists

  AppSettings({
    this.themeIndex = 0,
    String? themeId,
    this.notificationTime = "21:00",
    this.notificationsEnabled = true,
    this.groupActivityNotifications = true,
  }) : themeId = themeId ?? 'pastel_pink';

  AppSettings copyWith({
    int? themeIndex,
    String? themeId,
    String? notificationTime,
    bool? notificationsEnabled,
    bool? groupActivityNotifications,
  }) {
    return AppSettings(
      themeIndex: themeIndex ?? this.themeIndex,
      themeId: themeId ?? this.themeId,
      notificationTime: notificationTime ?? this.notificationTime,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      groupActivityNotifications:
          groupActivityNotifications ?? this.groupActivityNotifications,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeIndex': themeIndex,
      'themeId': themeId,
      'notificationTime': notificationTime,
      'notificationsEnabled': notificationsEnabled,
      'groupActivityNotifications': groupActivityNotifications,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    final id = map['themeId'] as String? ?? 'pastel_pink';
    final idx = (map['themeIndex'] as num?)?.toInt() ?? 0;

    return AppSettings(
      themeIndex: idx,
      themeId: id,
      notificationTime: map['notificationTime'] as String? ?? "21:00",
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      groupActivityNotifications:
          map['groupActivityNotifications'] as bool? ?? true,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppSettings.fromJson(String source) =>
      AppSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
