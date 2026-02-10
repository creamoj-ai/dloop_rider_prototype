import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../services/orders_service.dart';

/// Real-time stream of all orders for the current rider
final ordersStreamProvider = StreamProvider<List<Order>>((ref) {
  return OrdersService.subscribeToOrders();
});

/// Derived: only active orders (pending, accepted, pickedUp)
final activeDbOrdersProvider = Provider<List<Order>>((ref) {
  final ordersAsync = ref.watch(ordersStreamProvider);
  return ordersAsync.when(
    data: (orders) => orders
        .where((o) =>
            o.status == OrderStatus.pending ||
            o.status == OrderStatus.accepted ||
            o.status == OrderStatus.pickedUp)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Derived: today's completed orders
final todayCompletedOrdersProvider = Provider<List<Order>>((ref) {
  final ordersAsync = ref.watch(ordersStreamProvider);
  final todayStart = DateTime.now().copyWith(
    hour: 0, minute: 0, second: 0, millisecond: 0,
  );

  return ordersAsync.when(
    data: (orders) => orders
        .where((o) =>
            o.status == OrderStatus.delivered &&
            o.deliveredAt != null &&
            o.deliveredAt!.isAfter(todayStart))
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Derived: today's total earnings from completed orders
final todayStreamEarningsProvider = Provider<double>((ref) {
  final completed = ref.watch(todayCompletedOrdersProvider);
  return completed.fold(0.0, (sum, o) => sum + o.totalEarning);
});
