import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/market_order.dart';
import '../services/market_orders_service.dart';

/// Real-time stream of all rider's market orders
final marketOrdersStreamProvider = StreamProvider<List<MarketOrder>>((ref) {
  return MarketOrdersService.subscribeToMarketOrders();
});

/// Active market orders (pending + accepted + delivering)
final activeMarketOrdersProvider = Provider<List<MarketOrder>>((ref) {
  final ordersAsync = ref.watch(marketOrdersStreamProvider);
  return ordersAsync.when(
    data: (orders) => orders.where((o) => o.isActive).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Completed market orders (delivered)
final completedMarketOrdersProvider = Provider<List<MarketOrder>>((ref) {
  final ordersAsync = ref.watch(marketOrdersStreamProvider);
  return ordersAsync.when(
    data: (orders) => orders.where((o) => o.isCompleted).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Today's market orders
final todayMarketOrdersProvider = Provider<List<MarketOrder>>((ref) {
  final ordersAsync = ref.watch(marketOrdersStreamProvider);
  final todayStart = DateTime.now().copyWith(
    hour: 0, minute: 0, second: 0, millisecond: 0,
  );
  return ordersAsync.when(
    data: (orders) =>
        orders.where((o) => o.createdAt.isAfter(todayStart)).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Today's market earnings (sum of delivered orders today)
final todayMarketEarningsProvider = Provider<double>((ref) {
  final todayOrders = ref.watch(todayMarketOrdersProvider);
  return todayOrders
      .where((o) => o.isCompleted)
      .fold(0.0, (sum, o) => sum + o.totalPrice);
});

/// Weekly market orders count
final weeklyMarketOrdersCountProvider = Provider<int>((ref) {
  final ordersAsync = ref.watch(marketOrdersStreamProvider);
  final weekStart = DateTime.now().subtract(const Duration(days: 7));
  return ordersAsync.when(
    data: (orders) =>
        orders.where((o) => o.createdAt.isAfter(weekStart)).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Monthly market earnings (sum of delivered orders this month)
final monthlyMarketEarningsProvider = Provider<double>((ref) {
  final ordersAsync = ref.watch(marketOrdersStreamProvider);
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  return ordersAsync.when(
    data: (orders) => orders
        .where((o) =>
            o.isCompleted && o.createdAt.isAfter(monthStart))
        .fold(0.0, (sum, o) => sum + o.totalPrice),
    loading: () => 0,
    error: (_, __) => 0,
  );
});
