import 'package:flutter_test/flutter_test.dart';
import 'package:my_dairy/models/pairing_code.dart';
import 'package:my_dairy/models/partner_connection.dart';

void main() {
  group('PairingCode Model & Expiration Tests', () {
    test('new pairing code defaults to 10-minute expiry and unused', () {
      final now = DateTime.now();
      final code = PairingCode(
        code: 'VIBE-123456',
        creatorUserId: 'user_1',
        creatorDisplayName: 'Alice',
        createdAt: now,
      );

      expect(code.code, equals('VIBE-123456'));
      expect(code.used, isFalse);
      expect(code.expiresAt.difference(now).inMinutes, equals(10));
      expect(code.isValid, isTrue);
    });

    test('pairing code is expired when expiresAt is in the past', () {
      final past = DateTime.now().subtract(const Duration(minutes: 15));
      final code = PairingCode(
        code: 'VIBE-EXPIRE',
        creatorUserId: 'user_2',
        createdAt: past,
        expiresAt: past.add(const Duration(minutes: 10)),
      );

      expect(code.isExpired, isTrue);
      expect(code.isValid, isFalse);
    });

    test('used pairing code is not valid even if not expired', () {
      final code = PairingCode(
        code: 'VIBE-USEDD1',
        creatorUserId: 'user_3',
        used: true,
      );

      expect(code.used, isTrue);
      expect(code.isValid, isFalse);
    });

    test('PairingCode serialization and deserialization', () {
      final code = PairingCode(
        code: 'VIBE-778899',
        creatorUserId: 'user_xyz',
        creatorDisplayName: 'Bob 🐰',
        creatorEmail: 'bob@example.com',
        creatorPhotoUrl: 'https://example.com/photo.png',
        used: false,
      );

      final map = code.toMap();
      final restored = PairingCode.fromMap(map);

      expect(restored.code, equals('VIBE-778899'));
      expect(restored.creatorUserId, equals('user_xyz'));
      expect(restored.creatorDisplayName, equals('Bob 🐰'));
      expect(restored.creatorEmail, equals('bob@example.com'));
      expect(restored.used, isFalse);
    });
  });

  group('PartnerConnection Model Tests', () {
    test('PartnerConnection initialization and JSON serialization', () {
      final conn = PartnerConnection(
        id: 'userA_userB',
        userA: 'userA',
        userB: 'userB',
        status: 'active',
      );

      expect(conn.isActive, isTrue);
      final json = conn.toJson();
      final fromJson = PartnerConnection.fromJson(json);

      expect(fromJson.id, equals('userA_userB'));
      expect(fromJson.userA, equals('userA'));
      expect(fromJson.userB, equals('userB'));
      expect(fromJson.status, equals('active'));
    });
  });
}
