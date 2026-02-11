import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/market_product.dart';
import '../services/market_products_service.dart';

/// Real-time stream of all rider's market products
final marketProductsStreamProvider = StreamProvider<List<MarketProduct>>((ref) {
  return MarketProductsService.subscribeToProducts();
});

/// Active products only (is_active + in stock)
final activeProductsProvider = Provider<List<MarketProduct>>((ref) {
  final productsAsync = ref.watch(marketProductsStreamProvider);
  return productsAsync.when(
    data: (products) =>
        products.where((p) => p.isActive && p.isInStock).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Total product count
final productCountProvider = Provider<int>((ref) {
  final productsAsync = ref.watch(marketProductsStreamProvider);
  return productsAsync.when(
    data: (products) => products.where((p) => p.isActive).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Total catalog value (sum of prices of active products)
final totalCatalogValueProvider = Provider<double>((ref) {
  final productsAsync = ref.watch(marketProductsStreamProvider);
  return productsAsync.when(
    data: (products) => products
        .where((p) => p.isActive)
        .fold(0.0, (sum, p) => sum + p.price),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Products grouped by category
final productsByCategoryProvider =
    Provider<Map<String, List<MarketProduct>>>((ref) {
  final productsAsync = ref.watch(marketProductsStreamProvider);
  return productsAsync.when(
    data: (products) {
      final map = <String, List<MarketProduct>>{};
      for (final p in products.where((p) => p.isActive)) {
        map.putIfAbsent(p.category, () => []).add(p);
      }
      return map;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});
