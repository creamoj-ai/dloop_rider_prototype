import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';

class OrdersService {
  static final _client = Supabase.instance.client;

  static String? get _riderId => _client.auth.currentUser?.id;

  /// Fetch today's orders for the current rider
  static Future<List<Order>> getTodayOrders() async {
    try {
      final riderId = _riderId;
      if (riderId == null) return [];

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
    } catch (e) {
      return [];
    }
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

  /// Update order status
  static Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final riderId = _riderId;
      if (riderId == null) return;

      final updates = <String, dynamic>{
        'status': status.name,
      };

      // Set the appropriate timestamp
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
    } catch (e) {
      // Silently fail
    }
  }

  /// Subscribe to real-time order updates for today
  static Stream<List<Order>> subscribeToOrders() {
    final riderId = _riderId;
    if (riderId == null) {
      return Stream.value([]);
    }

    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('rider_id', riderId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Order.fromJson(json)).toList());
  }
}
