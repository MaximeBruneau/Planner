import 'dart:convert';

class PartnerInfo {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final DateTime pairedAt;

  const PartnerInfo({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.pairedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'pairedAt': pairedAt.toIso8601String(),
    };
  }

  factory PartnerInfo.fromMap(Map<String, dynamic> map) {
    return PartnerInfo(
      uid: map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'FT 🐰',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      pairedAt: map['pairedAt'] != null
          ? DateTime.tryParse(map['pairedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }



  String toJson() => jsonEncode(toMap());

  factory PartnerInfo.fromJson(String source) =>
      PartnerInfo.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
