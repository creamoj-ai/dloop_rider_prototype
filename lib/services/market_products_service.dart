import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/market_product.dart';
import '../utils/logger.dart';
import '../utils/retry.dart';

class MarketProductsService {
  static final _client = Supabase.instance.client;

  static String? get _riderId => _client.auth.currentUser?.id;

  /// Real-time stream of rider's products
  static Stream<List<MarketProduct>> subscribeToProducts() {
    final riderId = _riderId;
    if (riderId == null) return Stream.value([]);

    return retryStream(
      () => _client
          .from('market_products')
          .stream(primaryKey: ['id'])
          .eq('rider_id', riderId)
          .order('created_at', ascending: false)
          .map((data) =>
              data.map((json) => MarketProduct.fromJson(json)).toList()),
      onReconnect: (attempt, e) {
        dlog('⚡ MarketProductsService.subscribeToProducts reconnect $attempt: $e');
      },
    );
  }

  /// Fetch all rider's products
  static Future<List<MarketProduct>> getProducts() async {
    final riderId = _riderId;
    if (riderId == null) return [];

    return retry(() async {
      final response = await _client
          .from('market_products')
          .select()
          .eq('rider_id', riderId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MarketProduct.fromJson(json))
          .toList();
    }, onRetry: (attempt, e) {
      dlog('⚡ MarketProductsService.getProducts retry $attempt: $e');
    });
  }

  /// Add a new product
  static Future<void> addProduct({
    required String name,
    required double price,
    double costPrice = 0,
    required String category,
    int stock = 0,
    String description = '',
    String imageUrl = '',
  }) async {
    final riderId = _riderId;
    if (riderId == null) throw Exception('Not authenticated');

    await retry(() async {
      await _client.from('market_products').insert({
        'rider_id': riderId,
        'name': name,
        'price': price,
        'cost_price': costPrice,
        'category': category,
        'stock': stock,
        'description': description,
        'image_url': imageUrl,
      });
    }, onRetry: (attempt, e) {
      dlog('⚡ MarketProductsService.addProduct retry $attempt: $e');
    });
  }

  /// Update a product
  static Future<void> updateProduct(
    String productId, {
    String? name,
    double? price,
    double? costPrice,
    String? category,
    int? stock,
    String? description,
    bool? isActive,
  }) async {
    final riderId = _riderId;
    if (riderId == null) throw Exception('Not authenticated');

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (price != null) updates['price'] = price;
    if (costPrice != null) updates['cost_price'] = costPrice;
    if (category != null) updates['category'] = category;
    if (stock != null) updates['stock'] = stock;
    if (description != null) updates['description'] = description;
    if (isActive != null) updates['is_active'] = isActive;

    if (updates.isEmpty) return;

    await retry(() async {
      await _client
          .from('market_products')
          .update(updates)
          .eq('id', productId)
          .eq('rider_id', riderId);
    }, onRetry: (attempt, e) {
      dlog('⚡ MarketProductsService.updateProduct retry $attempt: $e');
    });
  }

  /// Delete a product
  static Future<void> deleteProduct(String productId) async {
    final riderId = _riderId;
    if (riderId == null) throw Exception('Not authenticated');

    await retry(() async {
      await _client
          .from('market_products')
          .delete()
          .eq('id', productId)
          .eq('rider_id', riderId);
    });
  }

  /// Increment sold count and decrement stock (on order completion)
  static Future<void> incrementSoldCount(String productId) async {
    final riderId = _riderId;
    if (riderId == null) return;

    try {
      await retry(() async {
        // Fetch current values
        final row = await _client
            .from('market_products')
            .select('sold_count, stock')
            .eq('id', productId)
            .eq('rider_id', riderId)
            .single();

        final currentSold = (row['sold_count'] as int?) ?? 0;
        final currentStock = (row['stock'] as int?) ?? 0;

        await _client
            .from('market_products')
            .update({
              'sold_count': currentSold + 1,
              'stock': currentStock > 0 ? currentStock - 1 : 0,
            })
            .eq('id', productId)
            .eq('rider_id', riderId);
      }, onRetry: (attempt, e) {
        dlog('⚡ MarketProductsService.incrementSoldCount retry $attempt: $e');
      });
    } catch (e) {
      dlog('❌ MarketProductsService.incrementSoldCount failed: $e');
    }
  }
}
