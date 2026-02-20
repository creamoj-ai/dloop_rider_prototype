import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dealer_subscription.dart';
import '../services/dealer_subscription_service.dart';

/// Stream all active dealer subscriptions for the current rider.
final dealerSubscriptionsStreamProvider =
    StreamProvider<List<DealerSubscription>>((ref) {
  return DealerSubscriptionService.streamSubscriptions();
});

/// Get subscription for a specific dealer contact.
final dealerSubscriptionProvider =
    FutureProvider.family<DealerSubscription?, String>(
        (ref, dealerContactId) async {
  return DealerSubscriptionService.getSubscription(dealerContactId);
});

/// Map of dealer_contact_id → tier label (derived from stream).
final dealerTierMapProvider = Provider<Map<String, String>>((ref) {
  final subs = ref.watch(dealerSubscriptionsStreamProvider);
  return subs.whenOrNull(
        data: (list) => {
          for (final s in list) s.dealerContactId: s.tierLabel,
        },
      ) ??
      {};
});
