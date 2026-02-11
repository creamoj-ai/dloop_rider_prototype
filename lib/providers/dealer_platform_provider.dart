import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dealer_platform.dart';
import '../services/dealer_platform_service.dart';

/// Real-time stream of rider's dealer platforms
final dealerPlatformsStreamProvider =
    StreamProvider<List<DealerPlatform>>((ref) {
  return DealerPlatformService.subscribeToPlatforms();
});

/// Count of active platform integrations
final activePlatformsCountProvider = Provider<int>((ref) {
  final platformsAsync = ref.watch(dealerPlatformsStreamProvider);
  return platformsAsync.when(
    data: (platforms) => platforms.where((p) => p.isActive).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
