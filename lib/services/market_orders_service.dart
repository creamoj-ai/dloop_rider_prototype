import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/earning.dart';
import '../models/market_order.dart';
import '../utils/retry.dart';
import 'earnings_service.dart';
import 'market_products_service.dart';

class MarketOrdersService {
  static final _client = Supabase.instance.client;

  static String? get _riderId => _client.auth.currentUser?.id;

  /// Real-time stream of rider's market orders
  static Stream<List<MarketOrder>> subscribeToMarketOrders() {
    final riderId = _riderId;
    if (riderId == null) return Stream.value([]);

    return retryStream(
      () => _client
          .from('market_orders')
          .stream(primaryKey: ['id'])
          .eq('rider_id', riderId)
          .order('created_at', ascending: false)
          .map((data) =>
              data.map((json) => MarketOrder.fromJson(json)).toList()),
      onReconnect: (attempt, e) {
        print('⚡ MarketOrdersService.subscribeToMarketOrders reconnect $attempt: $e');
      },
    );
  }

  /// Fetch market orders with optional status filter
  static Future<List<MarketOrder>> getMarketOrders({String? status}) async {
    final riderId = _riderId;
    if (riderId == null) return [];

    return retry(() async {
      var query = _client
          .from('market_orders')
          .select()
          .eq('rider_id', riderId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => MarketOrder.fromJson(json))
          .toList();
    }, onRetry: (attempt, e) {
      print('⚡ MarketOrdersService.getMarketOrders retry $attempt: $e');
    });
  }

  /// Create a new market order
  static Future<void> createMarketOrder({
    String? productId,
    required String productName,
    required String customerName,
    String customerPhone = '',
    String customerAddress = '',
    int quantity = 1,
    required double unitPrice,
    String source = 'app',
    String notes = '',
  }) async {
    final riderId = _riderId;
    if (riderId == null) throw Exception('Not authenticated');

    await retry(() async {
      await _client.from('market_orders').insert({
        'rider_id': riderId,
        'product_id': productId,
        'product_name': productName,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'customer_address': customerAddress,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': unitPrice * quantity,
        'status': 'pending',
        'source': source,
        'notes': notes,
      });
    }, onRetry: (attempt, e) {
      print('⚡ MarketOrdersService.createMarketOrder retry $attempt: $e');
    });
  }

  /// Update market order status
  static Future<void> updateMarketOrderStatus(
    String orderId,
    MarketOrderStatus status,
  ) async {
    final riderId = _riderId;
    if (riderId == null) return;

    try {
      await retry(() async {
        final updates = <String, dynamic>{
          'status': status.name,
        };

        final now = DateTime.now().toIso8601String();
        if (status == MarketOrderStatus.accepted) {
          updates['accepted_at'] = now;
        } else if (status == MarketOrderStatus.delivered) {
          updates['delivered_at'] = now;
        }

        await _client
            .from('market_orders')
            .update(updates)
            .eq('id', orderId)
            .eq('rider_id', riderId);
      }, onRetry: (attempt, e) {
        print('⚡ MarketOrdersService.updateMarketOrderStatus retry $attempt: $e');
      });
    } catch (e) {
      print('❌ MarketOrdersService.updateMarketOrderStatus failed: $e');
    }
  }

  /// Complete a market order: set status to delivered + create market_sale transaction
  static Future<void> completeMarketOrder(String orderId) async {
    final riderId = _riderId;
    if (riderId == null) return;

    try {
      // Fetch order details for the transaction
      final row = await retry(() async {
        return await _client
            .from('market_orders')
            .select()
            .eq('id', orderId)
            .eq('rider_id', riderId)
            .single();
      });

      final order = MarketOrder.fromJson(row);

      // Update status to delivered
      await updateMarketOrderStatus(orderId, MarketOrderStatus.delivered);

      // Update product sold count if product_id exists
      if (order.productId != null && order.productId!.isNotEmpty) {
        await MarketProductsService.incrementSoldCount(order.productId!);
      }

      // Create market_sale transaction
      final earning = Earning(
        id: '',
        amount: order.totalPrice,
        type: EarningType.market,
        description: '${order.productName} x${order.quantity} — ${order.customerName}',
        orderId: orderId,
        dateTime: DateTime.now(),
        status: EarningStatus.completed,
      );
      await EarningsService.createEarning(earning);
    } catch (e) {
      print('❌ MarketOrdersService.completeMarketOrder failed: $e');
    }
  }
}
