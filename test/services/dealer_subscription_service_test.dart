import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/dealer_subscription.dart';

/// Tests for DealerSubscription model logic used by the service.
/// Service integration tests are not possible without Supabase mock,
/// so we test the model layer that the service depends on.
void main() {
  group('DealerSubscription service-level logic', () {
    final sampleData = [
      {
        'id': 'sub-1',
        'dealer_contact_id': 'dc-1',
        'rider_id': 'r-1',
        'tier': 'starter',
        'monthly_fee_cents': 0,
        'per_order_fee_cents': 50,
        'is_active': true,
        'started_at': '2026-01-01',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      },
      {
        'id': 'sub-2',
        'dealer_contact_id': 'dc-2',
        'rider_id': 'r-1',
        'tier': 'pro',
        'monthly_fee_cents': 4900,
        'per_order_fee_cents': 0,
        'is_active': true,
        'started_at': '2026-02-01',
        'created_at': '2026-02-01',
        'updated_at': '2026-02-01',
      },
      {
        'id': 'sub-3',
        'dealer_contact_id': 'dc-3',
        'rider_id': 'r-1',
        'tier': 'business',
        'monthly_fee_cents': 7900,
        'per_order_fee_cents': 0,
        'is_active': false,
        'started_at': '2025-01-01',
        'created_at': '2025-01-01',
        'updated_at': '2025-06-01',
      },
    ];

    test('parse list and filter active', () {
      final all = sampleData
          .map((e) => DealerSubscription.fromJson(e))
          .toList();
      expect(all.length, 3);

      final active = all.where((s) => s.isActive).toList();
      expect(active.length, 2);
      expect(active.map((s) => s.tier).toList(), ['starter', 'pro']);
    });

    test('find subscription by dealer_contact_id', () {
      final all = sampleData
          .map((e) => DealerSubscription.fromJson(e))
          .toList();

      final found = all
          .where((s) => s.dealerContactId == 'dc-2' && s.isActive)
          .toList();
      expect(found.length, 1);
      expect(found.first.tier, 'pro');
      expect(found.first.monthlyFeeEur, 49.0);
    });

    test('calculate total monthly revenue from subscriptions', () {
      final all = sampleData
          .map((e) => DealerSubscription.fromJson(e))
          .toList();

      final active = all.where((s) => s.isActive);
      final totalMonthly =
          active.fold<double>(0, (sum, s) => sum + s.monthlyFeeEur);
      expect(totalMonthly, 49.0); // starter=0 + pro=49
    });

    test('tier config access', () {
      final proConfig = DealerSubscription.tierConfigs['pro']!;
      expect(proConfig.monthlyFeeEur, 49.0);
      expect(proConfig.perOrderFeeEur, 0.0);

      final starterConfig = DealerSubscription.tierConfigs['starter']!;
      expect(starterConfig.monthlyFeeEur, 0.0);
      expect(starterConfig.perOrderFeeEur, 0.50);
    });

    test('build tier map from subscription list', () {
      final all = sampleData
          .map((e) => DealerSubscription.fromJson(e))
          .where((s) => s.isActive)
          .toList();

      final tierMap = {
        for (final s in all) s.dealerContactId: s.tierLabel,
      };

      expect(tierMap['dc-1'], 'Starter');
      expect(tierMap['dc-2'], 'Pro');
      expect(tierMap.containsKey('dc-3'), false); // inactive
    });
  });
}
