import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/dealer_platform.dart';

void main() {
  group('DealerPlatform Stripe fields', () {
    test('fromJson parses Stripe fields correctly', () {
      final dp = DealerPlatform.fromJson({
        'id': 'dp-1',
        'rider_id': 'r-1',
        'contact_id': 'c-1',
        'platform_type': 'custom',
        'platform_name': 'Test',
        'created_at': '2026-02-13T10:00:00Z',
        'stripe_account_id': 'acct_123',
        'stripe_onboarding_status': 'complete',
        'stripe_charges_enabled': true,
        'stripe_payouts_enabled': true,
        'stripe_onboarded_at': '2026-02-13T12:00:00Z',
      });

      expect(dp.stripeAccountId, 'acct_123');
      expect(dp.stripeOnboardingStatus, 'complete');
      expect(dp.stripeChargesEnabled, true);
      expect(dp.stripePayoutsEnabled, true);
      expect(dp.stripeOnboardedAt, isNotNull);
    });

    test('fromJson handles missing Stripe fields', () {
      final dp = DealerPlatform.fromJson({
        'id': 'dp-2',
        'platform_type': 'custom',
        'platform_name': 'Test',
        'created_at': '2026-02-13T10:00:00Z',
      });

      expect(dp.stripeAccountId, isNull);
      expect(dp.stripeOnboardingStatus, isNull);
      expect(dp.stripeChargesEnabled, false);
      expect(dp.stripePayoutsEnabled, false);
      expect(dp.stripeOnboardedAt, isNull);
    });

    test('isStripeReady requires both charges and payouts enabled', () {
      final ready = DealerPlatform.fromJson({
        'id': 'dp-3',
        'platform_type': 'custom',
        'platform_name': 'Test',
        'created_at': '2026-02-13T10:00:00Z',
        'stripe_account_id': 'acct_123',
        'stripe_charges_enabled': true,
        'stripe_payouts_enabled': true,
      });
      expect(ready.isStripeReady, true);

      final notReady = DealerPlatform.fromJson({
        'id': 'dp-4',
        'platform_type': 'custom',
        'platform_name': 'Test',
        'created_at': '2026-02-13T10:00:00Z',
        'stripe_account_id': 'acct_123',
        'stripe_charges_enabled': true,
        'stripe_payouts_enabled': false,
      });
      expect(notReady.isStripeReady, false);
    });

    test('stripeStatusLabel returns correct labels', () {
      expect(
        DealerPlatform.fromJson({
          'id': '1',
          'platform_type': 'c',
          'platform_name': 'n',
          'created_at': '2026-01-01',
        }).stripeStatusLabel,
        'Non configurato',
      );

      expect(
        DealerPlatform.fromJson({
          'id': '2',
          'platform_type': 'c',
          'platform_name': 'n',
          'created_at': '2026-01-01',
          'stripe_account_id': 'acct_1',
          'stripe_onboarding_status': 'pending',
        }).stripeStatusLabel,
        'In attesa',
      );

      expect(
        DealerPlatform.fromJson({
          'id': '3',
          'platform_type': 'c',
          'platform_name': 'n',
          'created_at': '2026-01-01',
          'stripe_account_id': 'acct_1',
          'stripe_onboarding_status': 'incomplete',
        }).stripeStatusLabel,
        'Incompleto',
      );

      expect(
        DealerPlatform.fromJson({
          'id': '4',
          'platform_type': 'c',
          'platform_name': 'n',
          'created_at': '2026-01-01',
          'stripe_account_id': 'acct_1',
          'stripe_charges_enabled': true,
          'stripe_payouts_enabled': true,
        }).stripeStatusLabel,
        'Attivo',
      );
    });
  });
}
