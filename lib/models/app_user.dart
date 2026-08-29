import 'dart:convert';
import '../core/utils/date_utils_helper.dart';

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? currentSpaceId;
  final List<String> joinedSpaceIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.currentSpaceId,
    List<String>? joinedSpaceIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : joinedSpaceIds = joinedSpaceIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? currentSpaceId,
    List<String>? joinedSpaceIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      currentSpaceId: currentSpaceId ?? this.currentSpaceId,
      joinedSpaceIds: joinedSpaceIds ?? List<String>.from(this.joinedSpaceIds),
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
      'currentSpaceId': currentSpaceId,
      'joinedSpaceIds': joinedSpaceIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final rawSpaces = (map['joinedSpaceIds'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final email = map['email'] as String? ?? '';
    var name = (map['displayName'] as String?)?.trim() ?? '';
    if (name.isEmpty || name.toLowerCase() == 'user' || name.toLowerCase() == 'planner user') {
      if (email.contains('@')) {
        name = email.split('@')[0];
      } else if (name.isEmpty) {
        name = 'Planner User';
      }
    }

    return AppUser(
      id: map['id'] as String? ?? '',
      email: email,
      displayName: name,
      photoUrl: map['photoUrl'] as String?,
      currentSpaceId: map['currentSpaceId'] as String?,
      joinedSpaceIds: rawSpaces,
      createdAt: DateUtilsHelper.parseDateTime(map['createdAt']),
      updatedAt: DateUtilsHelper.parseDateTime(map['updatedAt']),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppUser.fromJson(String source) =>
      AppUser.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
