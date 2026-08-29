import 'dart:convert';
import '../core/utils/date_utils_helper.dart';

/// Represents a member in a shared calendar space
class SpaceMember {
  final String userId;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String role; // 'owner' | 'member'
  final DateTime joinedAt;

  SpaceMember({
    required this.userId,
    required this.displayName,
    this.email = '',
    this.photoUrl,
    this.role = 'member',
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  factory SpaceMember.fromMap(Map<String, dynamic> map) {
    final email = map['email'] as String? ?? '';
    var name = (map['displayName'] as String?)?.trim() ?? '';
    if (name.isEmpty || name.toLowerCase() == 'member' || name.toLowerCase() == 'user') {
      if (email.contains('@')) {
        name = email.split('@')[0];
      } else if (name.isEmpty) {
        name = 'Member';
      }
    }
    return SpaceMember(
      userId: map['userId'] as String? ?? '',
      displayName: name,
      email: email,
      photoUrl: map['photoUrl'] as String?,
      role: map['role'] as String? ?? 'member',
      joinedAt: DateUtilsHelper.parseDateTime(map['joinedAt']),
    );
  }
}

/// Represents a shared calendar space (e.g. "Weekend Squad 🍕" with code "SUPER-4892")
class SharedSpace {
  final String id;
  final String name;
  final String code; // 6-10 character share code (e.g. "SUPER-4892")
  final String creatorId;
  final List<String> memberIds;
  final Map<String, SpaceMember> members;
  final String? lastActivityNotice;
  final DateTime createdAt;
  final DateTime updatedAt;

  SharedSpace({
    required this.id,
    required this.name,
    required this.code,
    required this.creatorId,
    List<String>? memberIds,
    Map<String, SpaceMember>? members,
    this.lastActivityNotice,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : memberIds = memberIds ?? [],
        members = members ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int get memberCount => memberIds.length;

  bool isMember(String userId) => memberIds.contains(userId);
  bool isOwner(String userId) => creatorId == userId;

  SharedSpace copyWith({
    String? id,
    String? name,
    String? code,
    String? creatorId,
    List<String>? memberIds,
    Map<String, SpaceMember>? members,
    String? lastActivityNotice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SharedSpace(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      creatorId: creatorId ?? this.creatorId,
      memberIds: memberIds ?? List<String>.from(this.memberIds),
      members: members ?? Map<String, SpaceMember>.from(this.members),
      lastActivityNotice: lastActivityNotice ?? this.lastActivityNotice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final membersMap = <String, dynamic>{};
    members.forEach((key, value) {
      membersMap[key] = value.toMap();
    });

    return {
      'id': id,
      'name': name,
      'code': code,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'members': membersMap,
      'lastActivityNotice': lastActivityNotice,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SharedSpace.fromMap(Map<String, dynamic> map) {
    final rawMemberIds = (map['memberIds'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final rawMembers = map['members'] as Map?;
    final membersMap = <String, SpaceMember>{};

    if (rawMembers != null) {
      rawMembers.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          membersMap[k.toString()] = SpaceMember.fromMap(v);
        }
      });
    }

    return SharedSpace(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Our Shared Calendar 🗓️',
      code: map['code'] as String? ?? '',
      creatorId: map['creatorId'] as String? ?? '',
      memberIds: rawMemberIds,
      members: membersMap,
      lastActivityNotice: map['lastActivityNotice'] as String?,
      createdAt: DateUtilsHelper.parseDateTime(map['createdAt']),
      updatedAt: DateUtilsHelper.parseDateTime(map['updatedAt']),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory SharedSpace.fromJson(String source) =>
      SharedSpace.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
