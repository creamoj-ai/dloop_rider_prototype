import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/dealer_subscription.dart';

void main() {
  group('DealerSubscription', () {
    test('fromJson parses all fields', () {
      final sub = DealerSubscription.fromJson({
        'id': 'sub-1',
        'dealer_contact_id': 'dc-1',
        'rider_id': 'r-1',
        'tier': 'pro',
        'monthly_fee_cents': 4900,
        'commission_rate': 0.0,
        'per_order_fee_cents': 0,
        'started_at': '2026-02-01T00:00:00Z',
        'expires_at': '2026-03-01T00:00:00Z',
        'is_active': true,
        'stripe_subscription_id': 'sub_stripe_1',
        'created_at': '2026-02-01T00:00:00Z',
        'updated_at': '2026-02-13T10:00:00Z',
      });

      expect(sub.id, 'sub-1');
      expect(sub.tier, 'pro');
      expect(sub.monthlyFeeCents, 4900);
      expect(sub.perOrderFeeCents, 0);
      expect(sub.isActive, true);
      expect(sub.stripeSubscriptionId, 'sub_stripe_1');
    });

    test('fromJson handles defaults', () {
      final sub = DealerSubscription.fromJson({
        'id': 'sub-2',
        'dealer_contact_id': 'dc-2',
        'rider_id': 'r-2',
        'created_at': '2026-02-01',
        'updated_at': '2026-02-01',
        'started_at': '2026-02-01',
      });

      expect(sub.tier, 'starter');
      expect(sub.monthlyFeeCents, 0);
      expect(sub.perOrderFeeCents, 50);
      expect(sub.commissionRate, 0.0);
      expect(sub.isActive, true);
    });

    test('computed EUR values', () {
      final sub = DealerSubscription.fromJson({
        'id': 's1',
        'dealer_contact_id': 'dc',
        'rider_id': 'r',
        'tier': 'pro',
        'monthly_fee_cents': 4900,
        'per_order_fee_cents': 0,
        'started_at': '2026-02-01',
        'created_at': '2026-02-01',
        'updated_at': '2026-02-01',
      });

      expect(sub.monthlyFeeEur, 49.0);
      expect(sub.perOrderFeeEur, 0.0);
    });

    test('tierLabel returns correct labels', () {
      for (final entry in {
        'starter': 'Starter',
        'pro': 'Pro',
        'business': 'Business',
        'enterprise': 'Enterprise',
      }.entries) {
        final sub = DealerSubscription.fromJson({
          'id': 'x',
          'dealer_contact_id': 'dc',
          'rider_id': 'r',
          'tier': entry.key,
          'started_at': '2026-02-01',
          'created_at': '2026-02-01',
          'updated_at': '2026-02-01',
        });
        expect(sub.tierLabel, entry.value);
      }
    });

    test('isExpired detects expired subscription', () {
      final expired = DealerSubscription.fromJson({
        'id': 'exp',
        'dealer_contact_id': 'dc',
        'rider_id': 'r',
        'expires_at': '2020-01-01T00:00:00Z',
        'started_at': '2019-01-01',
        'created_at': '2019-01-01',
        'updated_at': '2019-01-01',
      });
      expect(expired.isExpired, true);

      final active = DealerSubscription.fromJson({
        'id': 'act',
        'dealer_contact_id': 'dc',
        'rider_id': 'r',
        'expires_at': '2030-01-01T00:00:00Z',
        'started_at': '2026-01-01',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      expect(active.isExpired, false);

      final noExpiry = DealerSubscription.fromJson({
        'id': 'ne',
        'dealer_contact_id': 'dc',
        'rider_id': 'r',
        'started_at': '2026-01-01',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      expect(noExpiry.isExpired, false);
    });

    test('tier configs have correct values', () {
      final configs = DealerSubscription.tierConfigs;
      expect(configs['starter']!.monthlyFeeEur, 0.0);
      expect(configs['starter']!.perOrderFeeEur, 0.50);
      expect(configs['pro']!.monthlyFeeEur, 49.0);
      expect(configs['pro']!.perOrderFeeEur, 0.0);
      expect(configs['business']!.monthlyFeeEur, 79.0);
      expect(configs['enterprise']!.monthlyFeeEur, 149.0);
    });

    test('toJson serializes correctly', () {
      final sub = DealerSubscription.fromJson({
        'id': 'sub-1',
        'dealer_contact_id': 'dc-1',
        'rider_id': 'r-1',
        'tier': 'pro',
        'monthly_fee_cents': 4900,
        'per_order_fee_cents': 0,
        'started_at': '2026-02-01T00:00:00.000Z',
        'created_at': '2026-02-01T00:00:00.000Z',
        'updated_at': '2026-02-01T00:00:00.000Z',
      });

      final json = sub.toJson();
      expect(json['tier'], 'pro');
      expect(json['monthly_fee_cents'], 4900);
      expect(json['dealer_contact_id'], 'dc-1');
    });
  });
}
