import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/fee_audit.dart';

void main() {
  group('FeeAudit', () {
    test('fromJson parses all fields', () {
      final fee = FeeAudit.fromJson({
        'id': 'fa-1',
        'order_id': 'ord-1',
        'relay_id': 'rel-1',
        'dealer_contact_id': 'dc-1',
        'rider_id': 'r-1',
        'total_amount_cents': 1250,
        'dealer_amount_cents': 1050,
        'rider_delivery_fee_cents': 0,
        'platform_fee_cents': 200,
        'stripe_fee_cents': 43,
        'dealer_tier': 'pro',
        'per_order_fee_applied': false,
        'created_at': '2026-02-13T10:00:00Z',
      });

      expect(fee.id, 'fa-1');
      expect(fee.orderId, 'ord-1');
      expect(fee.relayId, 'rel-1');
      expect(fee.dealerContactId, 'dc-1');
      expect(fee.totalAmountCents, 1250);
      expect(fee.dealerAmountCents, 1050);
      expect(fee.platformFeeCents, 200);
      expect(fee.stripeFeeCents, 43);
      expect(fee.dealerTier, 'pro');
      expect(fee.perOrderFeeApplied, false);
    });

    test('fromJson handles defaults', () {
      final fee = FeeAudit.fromJson({
        'id': 'fa-2',
        'order_id': 'ord-2',
        'total_amount_cents': 500,
      });

      expect(fee.relayId, isNull);
      expect(fee.dealerContactId, isNull);
      expect(fee.dealerAmountCents, 0);
      expect(fee.riderDeliveryFeeCents, 0);
      expect(fee.platformFeeCents, 0);
      expect(fee.stripeFeeCents, 0);
      expect(fee.dealerTier, isNull);
      expect(fee.perOrderFeeApplied, false);
    });

    test('EUR conversions are correct', () {
      final fee = FeeAudit.fromJson({
        'id': 'fa-3',
        'order_id': 'ord-3',
        'total_amount_cents': 1500,
        'dealer_amount_cents': 1200,
        'rider_delivery_fee_cents': 100,
        'platform_fee_cents': 300,
        'stripe_fee_cents': 46,
      });

      expect(fee.totalEur, 15.0);
      expect(fee.dealerEur, 12.0);
      expect(fee.riderEur, 1.0);
      expect(fee.platformEur, 3.0);
      expect(fee.stripeEur, 0.46);
    });

    test('percentage calculations', () {
      final fee = FeeAudit.fromJson({
        'id': 'fa-4',
        'order_id': 'ord-4',
        'total_amount_cents': 1000,
        'dealer_amount_cents': 800,
        'platform_fee_cents': 200,
      });

      expect(fee.dealerPercent, 80.0);
      expect(fee.platformPercent, 20.0);
    });

    test('percentage with zero total', () {
      final fee = FeeAudit.fromJson({
        'id': 'fa-5',
        'order_id': 'ord-5',
        'total_amount_cents': 0,
        'dealer_amount_cents': 0,
        'platform_fee_cents': 0,
      });

      expect(fee.dealerPercent, 0);
      expect(fee.platformPercent, 0);
    });

    test('numeric types handled (int vs double from JSON)', () {
      final fee = FeeAudit.fromJson({
        'id': 'fa-6',
        'order_id': 'ord-6',
        'total_amount_cents': 1250.0,
        'dealer_amount_cents': 1050.0,
        'platform_fee_cents': 200.0,
        'stripe_fee_cents': 43.0,
      });

      expect(fee.totalAmountCents, 1250);
      expect(fee.dealerAmountCents, 1050);
    });
  });
}
