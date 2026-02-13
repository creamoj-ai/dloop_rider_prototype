import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_relay.dart';
import '../services/order_relay_service.dart';

/// Real-time stream of all relays for current rider
final activeRelaysStreamProvider = StreamProvider<List<OrderRelay>>((ref) {
  return OrderRelayService.streamActiveRelays();
});

/// Family provider: relay for a specific order (real-time)
final orderRelayProvider =
    StreamProvider.family<OrderRelay?, String>((ref, orderId) {
  return OrderRelayService.streamRelayForOrder(orderId);
});

/// Count of active relays (not cancelled/picked_up)
final activeRelayCountProvider = Provider<int>((ref) {
  return ref.watch(activeRelaysStreamProvider).whenOrNull(
            data: (relays) => relays.where((r) => r.isActive).length,
          ) ??
      0;
});

/// Relays grouped by dealer contact ID (for Network screen)
final relaysByDealerProvider =
    Provider<Map<String, List<OrderRelay>>>((ref) {
  return ref.watch(activeRelaysStreamProvider).whenOrNull(
            data: (relays) {
              final map = <String, List<OrderRelay>>{};
              for (final r in relays) {
                map.putIfAbsent(r.dealerContactId, () => []).add(r);
              }
              return map;
            },
          ) ??
      {};
});

/// Relay count for a specific dealer
final dealerRelayCountProvider =
    Provider.family<int, String>((ref, dealerContactId) {
  final byDealer = ref.watch(relaysByDealerProvider);
  return byDealer[dealerContactId]?.length ?? 0;
});
