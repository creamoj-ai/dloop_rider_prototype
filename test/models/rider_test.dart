import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/rider.dart';

void main() {
  group('RiderPricing', () {
    test('default constructor has correct defaults', () {
      const pricing = RiderPricing();

      expect(pricing.ratePerKm, 1.50);
      expect(pricing.minDeliveryFee, 3.00);
      expect(pricing.holdCostPerMin, 0.15);
      expect(pricing.holdFreeMinutes, 5);
      expect(pricing.shortDistanceMax, 2.0);
      expect(pricing.mediumDistanceMax, 5.0);
      expect(pricing.longDistanceBonus, 0.50);
    });

    group('calculateBaseEarning', () {
      const pricing = RiderPricing();

      test('with distance 0 km returns minDeliveryFee', () {
        // 0 * 1.50 = 0, which is < minDeliveryFee (3.00)
        expect(pricing.calculateBaseEarning(0), 3.00);
      });

      test('with short distance (1 km) applies min guarantee', () {
        // 1 * 1.50 = 1.50 < 3.00 → return 3.00
        expect(pricing.calculateBaseEarning(1.0), 3.00);
      });

      test('with short distance (2 km) exactly at threshold', () {
        // 2 * 1.50 = 3.00 >= 3.00 → return 3.00
        expect(pricing.calculateBaseEarning(2.0), 3.00);
      });

      test('with medium distance (3.5 km)', () {
        // 3.5 * 1.50 = 5.25
        expect(pricing.calculateBaseEarning(3.5), 5.25);
      });

      test('with medium distance (5 km) exactly at threshold', () {
        // 5 * 1.50 = 7.50
        expect(pricing.calculateBaseEarning(5.0), 7.50);
      });

      test('with long distance (8 km) adds bonus', () {
        // base: 8 * 1.50 = 12.00
        // extra km: 8 - 5 = 3 → 3 * 0.50 = 1.50
        // total: 12.00 + 1.50 = 13.50
        expect(pricing.calculateBaseEarning(8.0), 13.50);
      });

      test('with custom pricing', () {
        final custom = RiderPricing(
          ratePerKm: 2.0,
          minDeliveryFee: 5.0,
          shortDistanceMax: 3.0,
          mediumDistanceMax: 7.0,
          longDistanceBonus: 1.0,
        );

        // 10 * 2.0 = 20.0 + (10-7) * 1.0 = 3.0 → 23.0
        expect(custom.calculateBaseEarning(10.0), 23.0);
      });
    });

    group('calculateHoldCost', () {
      const pricing = RiderPricing();

      test('with 0 minutes returns 0', () {
        expect(pricing.calculateHoldCost(0), 0.0);
      });

      test('within free minutes returns 0', () {
        expect(pricing.calculateHoldCost(3), 0.0);
        expect(pricing.calculateHoldCost(5), 0.0);
      });

      test('with 10 minutes charges for 5 billable minutes', () {
        // (10 - 5) * 0.15 = 0.75
        expect(pricing.calculateHoldCost(10), 0.75);
      });

      test('with 20 minutes charges for 15 billable minutes', () {
        // (20 - 5) * 0.15 = 2.25
        expect(pricing.calculateHoldCost(20), 2.25);
      });
    });

    group('copyWith', () {
      test('overwrites specified fields', () {
        const pricing = RiderPricing();
        final updated = pricing.copyWith(
          ratePerKm: 2.0,
          holdFreeMinutes: 10,
        );

        expect(updated.ratePerKm, 2.0);
        expect(updated.holdFreeMinutes, 10);
        // unchanged
        expect(updated.minDeliveryFee, 3.00);
        expect(updated.holdCostPerMin, 0.15);
      });
    });

    group('fromJson / toJson', () {
      test('round-trip serialization', () {
        const original = RiderPricing(
          ratePerKm: 2.0,
          minDeliveryFee: 4.0,
          holdCostPerMin: 0.20,
          holdFreeMinutes: 8,
        );

        final json = original.toJson();
        final restored = RiderPricing.fromJson(json);

        expect(restored.ratePerKm, 2.0);
        expect(restored.minDeliveryFee, 4.0);
        expect(restored.holdCostPerMin, 0.20);
        expect(restored.holdFreeMinutes, 8);
      });

      test('fromJson with missing values uses defaults', () {
        final pricing = RiderPricing.fromJson({});

        expect(pricing.ratePerKm, 1.50);
        expect(pricing.minDeliveryFee, 3.00);
        expect(pricing.holdCostPerMin, 0.15);
        expect(pricing.holdFreeMinutes, 5);
      });
    });
  });

  group('Rider', () {
    late Rider rider;

    setUp(() {
      rider = Rider(
        name: 'Mario Rossi',
        email: 'mario@test.com',
        avatarUrl: 'https://example.com/avatar.png',
        level: 5,
        currentXp: 350,
        xpToNextLevel: 500,
        streak: 7,
        totalOrders: 156,
        totalEarnings: 1250.0,
        totalKm: 890.5,
        avgRating: 4.8,
        memberSince: DateTime(2025, 6, 1),
      );
    });

    test('copyWith overwrites specified fields', () {
      final updated = rider.copyWith(
        name: 'Luigi Verdi',
        level: 10,
        streak: 15,
      );

      expect(updated.name, 'Luigi Verdi');
      expect(updated.level, 10);
      expect(updated.streak, 15);
      // unchanged
      expect(updated.email, rider.email);
      expect(updated.totalOrders, rider.totalOrders);
      expect(updated.totalEarnings, rider.totalEarnings);
    });

    test('copyWith without parameters returns identical copy', () {
      final copy = rider.copyWith();

      expect(copy.name, rider.name);
      expect(copy.email, rider.email);
      expect(copy.level, rider.level);
      expect(copy.currentXp, rider.currentXp);
      expect(copy.xpToNextLevel, rider.xpToNextLevel);
      expect(copy.streak, rider.streak);
      expect(copy.totalOrders, rider.totalOrders);
      expect(copy.totalEarnings, rider.totalEarnings);
      expect(copy.totalKm, rider.totalKm);
      expect(copy.avgRating, rider.avgRating);
    });

    test('default pricing is RiderPricing()', () {
      expect(rider.pricing.ratePerKm, 1.50);
      expect(rider.pricing.minDeliveryFee, 3.00);
    });

    test('copyWith can override pricing', () {
      final updated = rider.copyWith(
        pricing: const RiderPricing(ratePerKm: 3.0),
      );
      expect(updated.pricing.ratePerKm, 3.0);
    });
  });
}
