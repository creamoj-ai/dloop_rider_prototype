import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_relay.dart';
import '../utils/logger.dart';
import '../utils/retry.dart';

class OrderRelayService {
  static final _client = Supabase.instance.client;

  static String? get _riderId => _client.auth.currentUser?.id;

  /// Create a new relay for an order
  static Future<OrderRelay?> createRelay({
    required String orderId,
    required String dealerContactId,
    String relayChannel = 'in_app',
    double? estimatedAmount,
    String? dealerMessage,
  }) async {
    final riderId = _riderId;
    if (riderId == null) return null;

    try {
      return await retry(() async {
        final response = await _client.from('order_relays').insert({
          'order_id': orderId,
          'rider_id': riderId,
          'dealer_contact_id': dealerContactId,
          'relay_channel': relayChannel,
          'estimated_amount': estimatedAmount,
          'dealer_message': dealerMessage,
          'status': 'pending',
          'payment_status': 'pending',
        }).select().single();

        return OrderRelay.fromJson(response);
      }, onRetry: (attempt, e) {
        dlog('⚡ OrderRelayService.createRelay retry $attempt: $e');
      });
    } catch (e) {
      dlog('❌ OrderRelayService.createRelay failed: $e');
      return null;
    }
  }

  /// Update relay status with automatic timestamp
  static Future<void> updateRelayStatus(
    String relayId,
    OrderRelayStatus newStatus,
  ) async {
    try {
      await retry(() async {
        final updates = <String, dynamic>{
          'status': newStatus.name == 'pickedUp' ? 'picked_up' : newStatus.name,
        };

        final now = DateTime.now().toIso8601String();
        switch (newStatus) {
          case OrderRelayStatus.sent:
            updates['relayed_at'] = now;
            break;
          case OrderRelayStatus.confirmed:
            updates['confirmed_at'] = now;
            break;
          case OrderRelayStatus.ready:
            updates['ready_at'] = now;
            break;
          case OrderRelayStatus.pickedUp:
            updates['picked_up_at'] = now;
            break;
          default:
            break;
        }

        await _client
            .from('order_relays')
            .update(updates)
            .eq('id', relayId);
      }, onRetry: (attempt, e) {
        dlog('⚡ OrderRelayService.updateRelayStatus retry $attempt: $e');
      });
    } catch (e) {
      dlog('❌ OrderRelayService.updateRelayStatus failed: $e');
    }
  }

  /// Stream relay for a specific order (real-time)
  static Stream<OrderRelay?> streamRelayForOrder(String orderId) {
    final riderId = _riderId;
    if (riderId == null) return Stream.value(null);

    return retryStream(
      () => _client
          .from('order_relays')
          .stream(primaryKey: ['id'])
          .eq('order_id', orderId)
          .order('created_at', ascending: false)
          .map((data) {
            if (data.isEmpty) return null;
            return OrderRelay.fromJson(data.first);
          }),
      onReconnect: (attempt, e) {
        dlog('⚡ OrderRelayService.streamRelayForOrder reconnect $attempt: $e');
      },
    );
  }

  /// Stream all active relays for current rider
  static Stream<List<OrderRelay>> streamActiveRelays() {
    final riderId = _riderId;
    if (riderId == null) return Stream.value([]);

    return retryStream(
      () => _client
          .from('order_relays')
          .stream(primaryKey: ['id'])
          .eq('rider_id', riderId)
          .order('created_at', ascending: false)
          .map((data) =>
              data.map((json) => OrderRelay.fromJson(json)).toList()),
      onReconnect: (attempt, e) {
        dlog('⚡ OrderRelayService.streamActiveRelays reconnect $attempt: $e');
      },
    );
  }

  /// Fetch relay for an order (one-shot)
  static Future<OrderRelay?> getRelayForOrder(String orderId) async {
    final riderId = _riderId;
    if (riderId == null) return null;

    try {
      final response = await _client
          .from('order_relays')
          .select()
          .eq('order_id', orderId)
          .eq('rider_id', riderId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return OrderRelay.fromJson(response);
    } catch (e) {
      dlog('❌ OrderRelayService.getRelayForOrder failed: $e');
      return null;
    }
  }
}
