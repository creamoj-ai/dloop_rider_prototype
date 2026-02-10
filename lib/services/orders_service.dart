import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../utils/retry.dart';

class OrdersService {
  static final _client = Supabase.instance.client;

  static String? get _riderId => _client.auth.currentUser?.id;

  /// Fetch today's orders for the current rider (with retry)
  static Future<List<Order>> getTodayOrders() async {
    final riderId = _riderId;
    if (riderId == null) return [];

    return retry(() async {
      final todayStart = DateTime.now().copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0,
      ).toIso8601String();

      final response = await _client
          .from('orders')
          .select()
          .eq('rider_id', riderId)
          .gte('created_at', todayStart)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Order.fromJson(json))
          .toList();
    }, onRetry: (attempt, e) {
      print('⚡ OrdersService.getTodayOrders retry $attempt: $e');
    });
  }

  /// Create a new order
  static Future<void> createOrder(Order order) async {
    try {
      final riderId = _riderId;
      if (riderId == null) return;

      await _client.from('orders').insert({
        'rider_id': riderId,
        ...order.toJson(),
      });
    } catch (e) {
      // Silently fail — local state is source of truth
    }
  }

  /// Update order status (with retry)
  static Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final riderId = _riderId;
    if (riderId == null) return;

    try {
      await retry(() async {
        final updates = <String, dynamic>{
          'status': status.name,
        };

        final now = DateTime.now().toIso8601String();
        switch (status) {
          case OrderStatus.accepted:
            updates['accepted_at'] = now;
            break;
          case OrderStatus.pickedUp:
            updates['picked_up_at'] = now;
            break;
          case OrderStatus.delivered:
            updates['delivered_at'] = now;
            break;
          default:
            break;
        }

        await _client
            .from('orders')
            .update(updates)
            .eq('id', orderId)
            .eq('rider_id', riderId);
      }, onRetry: (attempt, e) {
        print('⚡ OrdersService.updateOrderStatus retry $attempt: $e');
      });
    } catch (e) {
      print('❌ OrdersService.updateOrderStatus failed after retries: $e');
    }
  }

  /// Subscribe to real-time order updates (with auto-reconnect)
  static Stream<List<Order>> subscribeToOrders() {
    final riderId = _riderId;
    if (riderId == null) {
      return Stream.value([]);
    }

    return retryStream(
      () => _client
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('rider_id', riderId)
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => Order.fromJson(json)).toList()),
      onReconnect: (attempt, e) {
        print('⚡ OrdersService.subscribeToOrders reconnect $attempt: $e');
      },
    );
  }
}
