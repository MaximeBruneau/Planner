import 'dart:convert';

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'User',
      photoUrl: map['photoUrl'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppUser.fromJson(String source) =>
      AppUser.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
