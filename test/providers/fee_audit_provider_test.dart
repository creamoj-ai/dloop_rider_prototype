import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/fee_audit.dart';

/// Tests for FeeAudit model and provider-level logic.
/// Provider integration tests require Supabase mock, so we test
/// the model and aggregation logic that providers depend on.
void main() {
  group('FeeAudit provider-level logic', () {
    final sampleFees = [
      {
        'id': 'fa-1',
        'order_id': 'ord-1',
        'dealer_contact_id': 'dc-1',
        'rider_id': 'r-1',
        'total_amount_cents': 1250,
        'dealer_amount_cents': 1050,
        'platform_fee_cents': 200,
        'stripe_fee_cents': 43,
        'dealer_tier': 'starter',
        'per_order_fee_applied': true,
        'created_at': '2026-02-13T10:00:00Z',
      },
      {
        'id': 'fa-2',
        'order_id': 'ord-2',
        'dealer_contact_id': 'dc-2',
        'rider_id': 'r-1',
        'total_amount_cents': 2500,
        'dealer_amount_cents': 2300,
        'platform_fee_cents': 200,
        'stripe_fee_cents': 60,
        'dealer_tier': 'pro',
        'per_order_fee_applied': false,
        'created_at': '2026-02-13T11:00:00Z',
      },
      {
        'id': 'fa-3',
        'order_id': 'ord-3',
        'dealer_contact_id': 'dc-1',
        'rider_id': 'r-1',
        'total_amount_cents': 800,
        'dealer_amount_cents': 600,
        'platform_fee_cents': 200,
        'stripe_fee_cents': 36,
        'dealer_tier': 'starter',
        'per_order_fee_applied': true,
        'created_at': '2026-02-13T12:00:00Z',
      },
    ];

    test('parse fee list', () {
      final fees =
          sampleFees.map((e) => FeeAudit.fromJson(e)).toList();
      expect(fees.length, 3);
    });

    test('aggregate total platform revenue', () {
      final fees =
          sampleFees.map((e) => FeeAudit.fromJson(e)).toList();
      final totalPlatformCents =
          fees.fold<int>(0, (sum, f) => sum + f.platformFeeCents);
      expect(totalPlatformCents, 600); // 200 + 200 + 200
      expect(totalPlatformCents / 100.0, 6.0);
    });

    test('aggregate per-dealer revenue', () {
      final fees =
          sampleFees.map((e) => FeeAudit.fromJson(e)).toList();

      final perDealer = <String, int>{};
      for (final f in fees) {
        if (f.dealerContactId != null) {
          perDealer[f.dealerContactId!] =
              (perDealer[f.dealerContactId!] ?? 0) + f.platformFeeCents;
        }
      }

      expect(perDealer['dc-1'], 400); // 200 + 200
      expect(perDealer['dc-2'], 200);
    });

    test('find fees for specific order', () {
      final fees =
          sampleFees.map((e) => FeeAudit.fromJson(e)).toList();
      final forOrder =
          fees.where((f) => f.orderId == 'ord-2').toList();
      expect(forOrder.length, 1);
      expect(forOrder.first.totalEur, 25.0);
      expect(forOrder.first.dealerTier, 'pro');
    });

    test('count orders with per_order_fee applied', () {
      final fees =
          sampleFees.map((e) => FeeAudit.fromJson(e)).toList();
      final withFee =
          fees.where((f) => f.perOrderFeeApplied).length;
      expect(withFee, 2); // fa-1 and fa-3 (starter tier)
    });

    test('calculate Stripe fee percentage', () {
      final fees =
          sampleFees.map((e) => FeeAudit.fromJson(e)).toList();
      final totalStripe =
          fees.fold<int>(0, (sum, f) => sum + f.stripeFeeCents);
      final totalAmount =
          fees.fold<int>(0, (sum, f) => sum + f.totalAmountCents);

      final stripePercent = totalStripe / totalAmount * 100;
      // (43 + 60 + 36) / (1250 + 2500 + 800) * 100 = 139/4550*100 ≈ 3.05%
      expect(stripePercent, closeTo(3.05, 0.1));
    });
  });
}
