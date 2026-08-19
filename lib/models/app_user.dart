import 'dart:convert';
import '../core/utils/date_utils_helper.dart';
import 'emoji_pack.dart';

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? partnerId;
  final List<String> unlockedThemes;
  final List<String> unlockedEmojiPacks;
  final Map<String, bool> claimedFlameMilestones;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.partnerId,
    List<String>? unlockedThemes,
    List<String>? unlockedEmojiPacks,
    Map<String, bool>? claimedFlameMilestones,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : unlockedThemes = unlockedThemes ?? ['pastel_pink'],
        unlockedEmojiPacks =
            unlockedEmojiPacks ?? [EmojiPacks.defaultPackId],
        claimedFlameMilestones = claimedFlameMilestones ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? partnerId,
    bool clearPartner = false,
    List<String>? unlockedThemes,
    List<String>? unlockedEmojiPacks,
    Map<String, bool>? claimedFlameMilestones,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      partnerId: clearPartner ? null : (partnerId ?? this.partnerId),
      unlockedThemes: unlockedThemes ?? List<String>.from(this.unlockedThemes),
      unlockedEmojiPacks:
          unlockedEmojiPacks ?? List<String>.from(this.unlockedEmojiPacks),
      claimedFlameMilestones: claimedFlameMilestones ??
          Map<String, bool>.from(this.claimedFlameMilestones),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'partnerId': partnerId,
      'unlockedThemes': unlockedThemes,
      'unlockedEmojiPacks': unlockedEmojiPacks,
      'claimedFlameMilestones': claimedFlameMilestones,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
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

    return AppUser(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'User',
      photoUrl: map['photoUrl'] as String?,
      partnerId: map['partnerId'] as String?,
      unlockedThemes: themes,
      unlockedEmojiPacks: emojiPacks,
      claimedFlameMilestones: milestones,
      createdAt: DateUtilsHelper.parseDateTime(map['createdAt']),
      updatedAt: DateUtilsHelper.parseDateTime(map['updatedAt']),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppUser.fromJson(String source) =>
      AppUser.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
