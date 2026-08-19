import 'dart:convert';
import '../core/utils/date_utils_helper.dart';

class PairingCode {
  final String code;
  final String creatorUserId;
  final String creatorDisplayName;
  final String? creatorEmail;
  final String? creatorPhotoUrl;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool used;

  PairingCode({
    required this.code,
    required this.creatorUserId,
    this.creatorDisplayName = 'Duo 🐰',
    this.creatorEmail,
    this.creatorPhotoUrl,
    DateTime? createdAt,
    DateTime? expiresAt,
    this.used = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        expiresAt = expiresAt ??
            (createdAt != null
                ? createdAt.add(const Duration(minutes: 10))
                : DateTime.now().add(const Duration(minutes: 10)));

  bool isExpiredAt([DateTime? referenceTime]) =>
      (referenceTime ?? DateTime.now()).isAfter(expiresAt);

  bool isValidAt([DateTime? referenceTime]) =>
      !used && !isExpiredAt(referenceTime);

  bool get isExpired => isExpiredAt();
  bool get isValid => isValidAt();

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'creatorUserId': creatorUserId,
      'creatorDisplayName': creatorDisplayName,
      'creatorEmail': creatorEmail,
      'creatorPhotoUrl': creatorPhotoUrl,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'used': used,
    };
  }

  factory PairingCode.fromMap(Map<String, dynamic> map) {
    final created = DateUtilsHelper.parseDateTime(map['createdAt']);
    final expires = map['expiresAt'] != null
        ? DateUtilsHelper.parseDateTime(map['expiresAt'])
        : created.add(const Duration(minutes: 10));

    return PairingCode(
      code: map['code'] as String? ?? '',
      creatorUserId: map['creatorUserId'] as String? ??
          (map['ownerUid'] as String? ?? ''),
      creatorDisplayName: map['creatorDisplayName'] as String? ??
          (map['displayName'] as String? ?? 'Duo 🐰'),
      creatorEmail:
          map['creatorEmail'] as String? ?? (map['email'] as String?),
      creatorPhotoUrl:
          map['creatorPhotoUrl'] as String? ?? (map['photoUrl'] as String?),
      createdAt: created,
      expiresAt: expires,
      used: map['used'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory PairingCode.fromJson(String source) =>
      PairingCode.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
