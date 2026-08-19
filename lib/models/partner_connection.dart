import 'dart:convert';
import '../core/utils/date_utils_helper.dart';

class PartnerConnection {
  final String id;
  final String userA;
  final String userB;
  final String status; // 'active' | 'dissolved'
  final DateTime createdAt;

  PartnerConnection({
    required this.id,
    required this.userA,
    required this.userB,
    this.status = 'active',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isActive => status == 'active';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userA': userA,
      'userB': userB,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PartnerConnection.fromMap(Map<String, dynamic> map) {
    return PartnerConnection(
      id: map['id'] as String? ?? '',
      userA: map['userA'] as String? ?? '',
      userB: map['userB'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      createdAt: DateUtilsHelper.parseDateTime(map['createdAt']),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory PartnerConnection.fromJson(String source) =>
      PartnerConnection.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
