import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/referral_service.dart';
import '../utils/retry.dart';

/// Real-time stream of referrals
final referralsStreamProvider = StreamProvider<List<Referral>>((ref) {
  return retryStream(() => ReferralService.subscribeToReferrals());
});

/// Active referrals count
final activeReferralsCountProvider = Provider<int>((ref) {
  final referrals = ref.watch(referralsStreamProvider);
  return referrals.when(
    data: (list) => list.where((r) => r.isActive).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Total bonus earned from referrals
final referralBonusProvider = Provider<double>((ref) {
  final referrals = ref.watch(referralsStreamProvider);
  return referrals.when(
    data: (list) => list
        .where((r) => r.isActive)
        .fold(0.0, (sum, r) => sum + r.bonusAmount),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});
