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
          final member = SpaceMember.fromMap(v);
          final uid = member.userId.isNotEmpty ? member.userId : k.toString();
          membersMap[uid] = member.userId.isNotEmpty
              ? member
              : SpaceMember(
                  userId: uid,
                  displayName: member.displayName,
                  email: member.email,
                  photoUrl: member.photoUrl,
                  role: member.role,
                  joinedAt: member.joinedAt,
                );
        }
      });
    }

    // Deduplicate members to prevent duplicate cards
    final emailToKey = <String, String>{};
    final keysToRemove = <String>[];

    // 1. Merge by non-empty email
    membersMap.forEach((key, member) {
      if (member.email.isNotEmpty) {
        final lowerEmail = member.email.toLowerCase().trim();
        if (emailToKey.containsKey(lowerEmail)) {
          final existingKey = emailToKey[lowerEmail]!;
          final existing = membersMap[existingKey]!;
          final role = (existing.role == 'owner' || member.role == 'owner') ? 'owner' : 'member';
          final name = member.displayName.isNotEmpty && member.displayName != 'Member'
              ? member.displayName
              : existing.displayName;
          final photo = member.photoUrl ?? existing.photoUrl;

          membersMap[existingKey] = SpaceMember(
            userId: existingKey,
            displayName: name,
            email: member.email,
            photoUrl: photo,
            role: role,
            joinedAt: existing.joinedAt.isBefore(member.joinedAt) ? existing.joinedAt : member.joinedAt,
          );
          keysToRemove.add(key);
        } else {
          emailToKey[lowerEmail] = key;
        }
      }
    });

    for (final k in keysToRemove) {
      membersMap.remove(k);
    }
    keysToRemove.clear();

    // 2. Merge by display name / owner role if email is missing or same person
    final nameToKey = <String, String>{};
    membersMap.forEach((key, member) {
      final cleanName = member.displayName.toLowerCase().trim();
      if (cleanName.isNotEmpty && cleanName != 'member' && cleanName != 'user') {
        if (nameToKey.containsKey(cleanName)) {
          final existingKey = nameToKey[cleanName]!;
          final existing = membersMap[existingKey]!;
          final email = existing.email.isNotEmpty ? existing.email : member.email;
          final photo = existing.photoUrl ?? member.photoUrl;
          final role = (existing.role == 'owner' || member.role == 'owner') ? 'owner' : 'member';

          membersMap[existingKey] = SpaceMember(
            userId: existingKey,
            displayName: existing.displayName,
            email: email,
            photoUrl: photo,
            role: role,
            joinedAt: existing.joinedAt.isBefore(member.joinedAt) ? existing.joinedAt : member.joinedAt,
          );
          keysToRemove.add(key);
        } else {
          nameToKey[cleanName] = key;
        }
      }
    });

    for (final k in keysToRemove) {
      membersMap.remove(k);
    }

    final deduplicatedMemberIds = rawMemberIds
        .where((id) => membersMap.containsKey(id) && !keysToRemove.contains(id))
        .toSet()
        .toList();

    return SharedSpace(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Our Shared Calendar 🗓️',
      code: map['code'] as String? ?? '',
      creatorId: map['creatorId'] as String? ?? '',
      memberIds: deduplicatedMemberIds.isNotEmpty ? deduplicatedMemberIds : membersMap.keys.toList(),
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
