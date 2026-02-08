import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rider.dart';

class PricingService {
  static final _client = Supabase.instance.client;

  static String? get _riderId => _client.auth.currentUser?.id;

  /// Fetch the current rider's pricing settings
  static Future<RiderPricing> getRiderPricing() async {
    try {
      final riderId = _riderId;
      if (riderId == null) return const RiderPricing();

      final response = await _client
          .from('rider_pricing')
          .select()
          .eq('rider_id', riderId)
          .maybeSingle();

      if (response == null) return const RiderPricing();
      return RiderPricing.fromJson(response);
    } catch (e) {
      return const RiderPricing();
    }
  }

  /// Upsert rider pricing settings
  static Future<void> saveRiderPricing(RiderPricing pricing) async {
    try {
      final riderId = _riderId;
      if (riderId == null) return;

      await _client.from('rider_pricing').upsert({
        'rider_id': riderId,
        ...pricing.toJson(),
      });
    } catch (e) {
      // Silently fail — UI keeps local state
    }
  }

  /// Subscribe to real-time pricing updates
  static Stream<RiderPricing> subscribeToPricing() {
    final riderId = _riderId;
    if (riderId == null) {
      return Stream.value(const RiderPricing());
    }

    return _client
        .from('rider_pricing')
        .stream(primaryKey: ['rider_id'])
        .eq('rider_id', riderId)
        .map((data) {
          if (data.isEmpty) return const RiderPricing();
          return RiderPricing.fromJson(data.first);
        });
  }
}
