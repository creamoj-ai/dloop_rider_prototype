import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/services/referral_service.dart';

void main() {
  group('ReferralService.generateReferralCode', () {
    test('with valid first and last name', () {
      final code = ReferralService.generateReferralCode(
        'Mario',
        'Rossi',
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
      );

      // lastName "ROSSI" → prefix "ROSS"
      // userId starts with "a1b2c3d4" → remove hyphens → "a1b2" (first 4 uppercase) → "A1B2"
      expect(code, 'ROSSA1B2');
    });

    test('with firstName null uses lastName', () {
      final code = ReferralService.generateReferralCode(
        null,
        'Bianchi',
        'x9y8z7w6-0000-0000-0000-000000000000',
      );

      // lastName "BIANCHI" → prefix "BIAN"
      expect(code.substring(0, 4), 'BIAN');
    });

    test('with both names null uses DLOOP', () {
      final code = ReferralService.generateReferralCode(
        null,
        null,
        'abcd1234-0000-0000-0000-000000000000',
      );

      // "DLOOP" → prefix "DLOO"
      expect(code.substring(0, 4), 'DLOO');
    });

    test('with userId null uses 0000 suffix', () {
      final code = ReferralService.generateReferralCode(
        'Mario',
        'Rossi',
        null,
      );

      // suffix from "0000" → "0000"
      expect(code.substring(4), '0000');
    });

    test('with short lastName pads with X', () {
      final code = ReferralService.generateReferralCode(
        'A',
        'Li',
        'abcd1234-0000-0000-0000-000000000000',
      );

      // lastName "LI" → padRight(4, 'X') → "LIXX"
      expect(code.substring(0, 4), 'LIXX');
    });

    test('produces different codes for different inputs', () {
      final code1 = ReferralService.generateReferralCode(
        'Mario', 'Rossi', 'aaaa-bbbb-cccc',
      );
      final code2 = ReferralService.generateReferralCode(
        'Luigi', 'Verdi', 'xxxx-yyyy-zzzz',
      );

      expect(code1, isNot(equals(code2)));
    });

    test('code is always 8 characters', () {
      final codes = [
        ReferralService.generateReferralCode('Mario', 'Rossi', 'abcd-1234-5678'),
        ReferralService.generateReferralCode(null, null, null),
        ReferralService.generateReferralCode('A', 'B', 'abcd-efgh-1234'),
        ReferralService.generateReferralCode('VeryLongFirstName', 'VeryLongLastName', 'very-long-uuid-string'),
      ];

      for (final code in codes) {
        expect(code.length, 8, reason: 'Code "$code" is not 8 characters');
      }
    });

    test('code is always uppercase', () {
      final code = ReferralService.generateReferralCode(
        'mario', 'rossi', 'abcd-1234',
      );

      expect(code, equals(code.toUpperCase()));
    });
  });

  group('Referral model', () {
    test('fromJson with complete data', () {
      final json = {
        'id': 'ref-001',
        'referred_name': 'Luigi Verdi',
        'referred_email': 'luigi@test.com',
        'status': 'active',
        'bonus_amount': 10.0,
        'created_at': '2026-01-15T10:00:00Z',
        'activated_at': '2026-01-20T12:00:00Z',
      };

      final referral = Referral.fromJson(json);

      expect(referral.id, 'ref-001');
      expect(referral.referredName, 'Luigi Verdi');
      expect(referral.referredEmail, 'luigi@test.com');
      expect(referral.status, 'active');
      expect(referral.bonusAmount, 10.0);
      expect(referral.isActive, true);
      expect(referral.isPending, false);
      expect(referral.activatedAt, isNotNull);
    });

    test('fromJson with missing fields uses defaults', () {
      final json = {
        'id': 'ref-002',
      };

      final referral = Referral.fromJson(json);

      expect(referral.referredName, 'Sconosciuto');
      expect(referral.referredEmail, isNull);
      expect(referral.status, 'pending');
      expect(referral.bonusAmount, 10.0);
      expect(referral.isActive, false);
      expect(referral.isPending, true);
      expect(referral.activatedAt, isNull);
    });

    test('fromJson with bonus_amount as string', () {
      final json = {
        'id': 'ref-003',
        'bonus_amount': '15.50',
      };

      expect(Referral.fromJson(json).bonusAmount, 15.50);
    });

    test('isActive and isPending computed properties', () {
      final active = Referral.fromJson({
        'id': 'r1',
        'status': 'active',
        'bonus_amount': 10,
      });
      expect(active.isActive, true);
      expect(active.isPending, false);

      final pending = Referral.fromJson({
        'id': 'r2',
        'status': 'pending',
        'bonus_amount': 10,
      });
      expect(pending.isActive, false);
      expect(pending.isPending, true);

      final expired = Referral.fromJson({
        'id': 'r3',
        'status': 'expired',
        'bonus_amount': 10,
      });
      expect(expired.isActive, false);
      expect(expired.isPending, false);
    });
  });
}
