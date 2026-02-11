import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dealer_platform.dart';
import '../utils/retry.dart';

class DealerPlatformService {
  static final _client = Supabase.instance.client;

  static String? get _riderId => _client.auth.currentUser?.id;

  /// Real-time stream of rider's dealer platforms
  static Stream<List<DealerPlatform>> subscribeToPlatforms() {
    final riderId = _riderId;
    if (riderId == null) return Stream.value([]);

    return retryStream(
      () => _client
          .from('dealer_platforms')
          .stream(primaryKey: ['id'])
          .eq('rider_id', riderId)
          .order('created_at', ascending: false)
          .map((data) =>
              data.map((json) => DealerPlatform.fromJson(json)).toList()),
      onReconnect: (attempt, e) {
        print('⚡ DealerPlatformService.subscribeToPlatforms reconnect $attempt: $e');
      },
    );
  }

  /// Add a new platform integration
  static Future<void> addPlatform({
    String? contactId,
    required String platformType,
    required String platformName,
    String? webhookUrl,
    String? scrapeUrl,
    Map<String, dynamic>? config,
  }) async {
    final riderId = _riderId;
    if (riderId == null) throw Exception('Not authenticated');

    await retry(() async {
      await _client.from('dealer_platforms').insert({
        'rider_id': riderId,
        'contact_id': contactId,
        'platform_type': platformType,
        'platform_name': platformName,
        'webhook_url': webhookUrl,
        'api_key': _generateApiKey(),
        'scrape_url': scrapeUrl,
        'config': config ?? {},
        'is_active': true,
      });
    }, onRetry: (attempt, e) {
      print('⚡ DealerPlatformService.addPlatform retry $attempt: $e');
    });
  }

  /// Update a platform
  static Future<void> updatePlatform(
    String platformId, {
    String? webhookUrl,
    String? scrapeUrl,
    bool? isActive,
    Map<String, dynamic>? config,
  }) async {
    final riderId = _riderId;
    if (riderId == null) throw Exception('Not authenticated');

    final updates = <String, dynamic>{};
    if (webhookUrl != null) updates['webhook_url'] = webhookUrl;
    if (scrapeUrl != null) updates['scrape_url'] = scrapeUrl;
    if (isActive != null) updates['is_active'] = isActive;
    if (config != null) updates['config'] = config;

    if (updates.isEmpty) return;

    await retry(() async {
      await _client
          .from('dealer_platforms')
          .update(updates)
          .eq('id', platformId)
          .eq('rider_id', riderId);
    }, onRetry: (attempt, e) {
      print('⚡ DealerPlatformService.updatePlatform retry $attempt: $e');
    });
  }

  /// Delete a platform
  static Future<void> deletePlatform(String platformId) async {
    final riderId = _riderId;
    if (riderId == null) throw Exception('Not authenticated');

    await retry(() async {
      await _client
          .from('dealer_platforms')
          .delete()
          .eq('id', platformId)
          .eq('rider_id', riderId);
    });
  }

  /// Generate a random 32-character hex API key
  static String _generateApiKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
