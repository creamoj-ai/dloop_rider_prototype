import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/user.dart';

void main() {
  final fullJson = {
    'id': 'user-abc-123',
    'email': 'mario@test.com',
    'first_name': 'Mario',
    'last_name': 'Rossi',
    'phone': '+39 333 1234567',
    'avatar_url': 'https://example.com/avatar.png',
    'is_online': true,
    'is_active': true,
    'current_lat': 40.8518,
    'current_lng': 14.2681,
    'last_location_update': '2026-02-10T14:30:00Z',
    'total_earnings': 1250.50,
    'rating': 4.8,
    'total_orders': 156,
    'referral_code': 'MARIO2026',
    'referred_by': 'LUIGI2025',
    'created_at': '2025-12-01T10:00:00Z',
    'updated_at': '2026-02-10T14:30:00Z',
  };

  group('User.fromJson', () {
    test('with complete profile', () {
      final user = User.fromJson(fullJson);

      expect(user.id, 'user-abc-123');
      expect(user.email, 'mario@test.com');
      expect(user.firstName, 'Mario');
      expect(user.lastName, 'Rossi');
      expect(user.phone, '+39 333 1234567');
      expect(user.avatarUrl, 'https://example.com/avatar.png');
      expect(user.isOnline, true);
      expect(user.isActive, true);
      expect(user.currentLat, 40.8518);
      expect(user.currentLng, 14.2681);
      expect(user.lastLocationUpdate, isNotNull);
      expect(user.totalEarnings, 1250.50);
      expect(user.rating, 4.8);
      expect(user.totalOrders, 156);
      expect(user.referralCode, 'MARIO2026');
      expect(user.referredBy, 'LUIGI2025');
    });

    test('with nullable fields (phone, avatar, lat/lng)', () {
      final json = {
        'id': 'user-456',
        'email': 'test@test.com',
        'first_name': null,
        'last_name': null,
        'phone': null,
        'avatar_url': null,
        'current_lat': null,
        'current_lng': null,
        'last_location_update': null,
        'referral_code': null,
        'referred_by': null,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };

      final user = User.fromJson(json);

      expect(user.firstName, isNull);
      expect(user.lastName, isNull);
      expect(user.phone, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.currentLat, isNull);
      expect(user.currentLng, isNull);
      expect(user.lastLocationUpdate, isNull);
      expect(user.isOnline, false);
      expect(user.isActive, true);
      expect(user.totalEarnings, 0.0);
      expect(user.rating, 5.0);
      expect(user.totalOrders, 0);
    });
  });

  group('User.toJson', () {
    test('serializes all fields correctly', () {
      final user = User.fromJson(fullJson);
      final json = user.toJson();

      expect(json['id'], 'user-abc-123');
      expect(json['email'], 'mario@test.com');
      expect(json['first_name'], 'Mario');
      expect(json['last_name'], 'Rossi');
      expect(json['is_online'], true);
      expect(json['total_earnings'], 1250.50);
      expect(json['rating'], 4.8);
      expect(json['total_orders'], 156);
    });
  });

  group('User.copyWith', () {
    test('overwrites only specified fields', () {
      final user = User.fromJson(fullJson);
      final updated = user.copyWith(
        firstName: 'Luigi',
        totalEarnings: 2000.0,
      );

      expect(updated.firstName, 'Luigi');
      expect(updated.totalEarnings, 2000.0);
      // unchanged
      expect(updated.id, user.id);
      expect(updated.email, user.email);
      expect(updated.lastName, user.lastName);
      expect(updated.rating, user.rating);
      expect(updated.totalOrders, user.totalOrders);
    });

    test('without parameters returns identical copy', () {
      final user = User.fromJson(fullJson);
      final copy = user.copyWith();

      expect(copy.id, user.id);
      expect(copy.email, user.email);
      expect(copy.firstName, user.firstName);
      expect(copy.lastName, user.lastName);
      expect(copy.phone, user.phone);
      expect(copy.isOnline, user.isOnline);
      expect(copy.totalEarnings, user.totalEarnings);
      expect(copy.rating, user.rating);
    });
  });

  group('User helpers', () {
    test('fullName with first and last name', () {
      final user = User.fromJson(fullJson);
      expect(user.fullName, 'Mario Rossi');
    });

    test('fullName with only firstName', () {
      final user = User(
        id: 'u1',
        email: 'test@test.com',
        firstName: 'Mario',
        isOnline: false,
        isActive: true,
        totalEarnings: 0,
        rating: 5.0,
        totalOrders: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(user.fullName, 'Mario');
    });

    test('fullName with no name falls back to email prefix', () {
      final user = User(
        id: 'u2',
        email: 'test@example.com',
        isOnline: false,
        isActive: true,
        totalEarnings: 0,
        rating: 5.0,
        totalOrders: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(user.fullName, 'test');
    });

    test('initials with first and last name', () {
      final user = User.fromJson(fullJson);
      expect(user.initials, 'MR');
    });

    test('initials with no name falls back to email initial', () {
      final user = User(
        id: 'u3',
        email: 'test@example.com',
        isOnline: false,
        isActive: true,
        totalEarnings: 0,
        rating: 5.0,
        totalOrders: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(user.initials, 'T');
    });
  });
}
