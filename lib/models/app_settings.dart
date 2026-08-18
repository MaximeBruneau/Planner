import 'dart:convert';
import '../core/constants/default_emojis.dart';
import 'emoji_pack.dart';

class AppSettings {
  final int themeIndex;
  final String themeId;
  final List<String> unlockedThemes;
  final List<String> unlockedEmojiPacks;
  final List<String> customEmojis;
  final String notificationTime; // e.g. "21:00"
  final bool notificationsEnabled;
  final Map<String, bool> claimedFlameMilestones;

  AppSettings({
    this.themeIndex = 0,
    String? themeId,
    List<String>? unlockedThemes,
    List<String>? unlockedEmojiPacks,
    List<String>? customEmojis,
    this.notificationTime = "21:00",
    this.notificationsEnabled = true,
    Map<String, bool>? claimedFlameMilestones,
  })  : themeId = themeId ?? 'pastel_pink',
        unlockedThemes = unlockedThemes ?? ['pastel_pink'],
        unlockedEmojiPacks =
            unlockedEmojiPacks ?? [EmojiPacks.defaultPackId],
        customEmojis = customEmojis ?? List<String>.from(DefaultEmojis.list),
        claimedFlameMilestones = claimedFlameMilestones ?? {};

  AppSettings copyWith({
    int? themeIndex,
    String? themeId,
    List<String>? unlockedThemes,
    List<String>? unlockedEmojiPacks,
    List<String>? customEmojis,
    String? notificationTime,
    bool? notificationsEnabled,
    Map<String, bool>? claimedFlameMilestones,
  }) {
    return AppSettings(
      themeIndex: themeIndex ?? this.themeIndex,
      themeId: themeId ?? this.themeId,
      unlockedThemes: unlockedThemes ?? List<String>.from(this.unlockedThemes),
      unlockedEmojiPacks:
          unlockedEmojiPacks ?? List<String>.from(this.unlockedEmojiPacks),
      customEmojis: customEmojis ?? List<String>.from(this.customEmojis),
      notificationTime: notificationTime ?? this.notificationTime,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      claimedFlameMilestones: claimedFlameMilestones ??
          Map<String, bool>.from(this.claimedFlameMilestones),
    );
  }

  bool isThemeUnlocked(String id) {
    if (id == 'pastel_pink') return true;
    return unlockedThemes.contains(id);
  }

  bool isEmojiPackUnlocked(String id) {
    if (id == EmojiPacks.defaultPackId) return true;
    return unlockedEmojiPacks.contains(id);
  }

  bool isEmojiUnlocked(String emoji) {
    final pack = EmojiPacks.getPackForEmoji(emoji);
    if (pack == null || pack.isFree) return true;
    return isEmojiPackUnlocked(pack.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'themeIndex': themeIndex,
      'themeId': themeId,
      'unlockedThemes': unlockedThemes,
      'unlockedEmojiPacks': unlockedEmojiPacks,
      'customEmojis': customEmojis,
      'notificationTime': notificationTime,
      'notificationsEnabled': notificationsEnabled,
      'claimedFlameMilestones': claimedFlameMilestones,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    final rawEmojis = map['customEmojis'] as List?;
    final emojis = rawEmojis != null
        ? List<String>.from(rawEmojis.map((e) => e.toString()))
        : List<String>.from(DefaultEmojis.list);

    final rawThemes = map['unlockedThemes'] as List?;
    final themes = rawThemes != null
        ? List<String>.from(rawThemes.map((e) => e.toString()))
        : <String>['pastel_pink'];

    final rawEmojiPacks = map['unlockedEmojiPacks'] as List?;
    final emojiPacks = rawEmojiPacks != null
        ? List<String>.from(rawEmojiPacks.map((e) => e.toString()))
        : <String>[EmojiPacks.defaultPackId];

    final rawMilestones = map['claimedFlameMilestones'] as Map?;
    final milestones = <String, bool>{};
    if (rawMilestones != null) {
      rawMilestones.forEach((key, value) {
        milestones[key.toString()] = value == true;
      });
    }

    final id = map['themeId'] as String? ?? 'pastel_pink';
    final idx = (map['themeIndex'] as num?)?.toInt() ?? 0;

    return AppSettings(
      themeIndex: idx,
      themeId: id,
      unlockedThemes: themes,
      unlockedEmojiPacks: emojiPacks,
      customEmojis: emojis,
      notificationTime: map['notificationTime'] as String? ?? "21:00",
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      claimedFlameMilestones: milestones,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppSettings.fromJson(String source) =>
      AppSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
