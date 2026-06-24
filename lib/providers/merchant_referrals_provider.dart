import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/merchant_referral.dart';
import '../services/merchant_referral_service.dart';

// ============================================================
// STREAM PROVIDER: Real-time merchant referrals
// ============================================================

/// Stream di tutti i merchant referrals del rider corrente (real-time via Supabase)
final merchantReferralsStreamProvider =
    StreamProvider<List<MerchantReferral>>((ref) {
  return MerchantReferralService.subscribeToReferrals();
});

// ============================================================
// COMPUTED PROVIDERS: Stats e filtri
// ============================================================

/// Conteggio referrals pending
final pendingMerchantReferralsCountProvider = Provider<int>((ref) {
  final referralsAsync = ref.watch(merchantReferralsStreamProvider);
  return referralsAsync.when(
    data: (referrals) =>
        referrals.where((r) => r.status == MerchantReferralStatus.pending).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Conteggio referrals active
final activeMerchantReferralsCountProvider = Provider<int>((ref) {
  final referralsAsync = ref.watch(merchantReferralsStreamProvider);
  return referralsAsync.when(
    data: (referrals) =>
        referrals.where((r) => r.status == MerchantReferralStatus.active).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Conteggio referrals completed
final completedMerchantReferralsCountProvider = Provider<int>((ref) {
  final referralsAsync = ref.watch(merchantReferralsStreamProvider);
  return referralsAsync.when(
    data: (referrals) =>
        referrals.where((r) => r.status == MerchantReferralStatus.completed).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Total bonus earned (completed referrals)
final merchantReferralBonusProvider = Provider<double>((ref) {
  final referralsAsync = ref.watch(merchantReferralsStreamProvider);
  return referralsAsync.when(
    data: (referrals) {
      final completedReferrals =
          referrals.where((r) => r.status == MerchantReferralStatus.completed);
      return completedReferrals.fold<double>(
        0.0,
        (sum, r) => sum + r.bonusEur,
      );
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// Lista referrals attivi (pending + active)
final activeAndPendingReferralsProvider =
    Provider<List<MerchantReferral>>((ref) {
  final referralsAsync = ref.watch(merchantReferralsStreamProvider);
  return referralsAsync.when(
    data: (referrals) => referrals
        .where((r) =>
            r.status == MerchantReferralStatus.pending ||
            r.status == MerchantReferralStatus.active)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Lista referrals completed
final completedReferralsProvider = Provider<List<MerchantReferral>>((ref) {
  final referralsAsync = ref.watch(merchantReferralsStreamProvider);
  return referralsAsync.when(
    data: (referrals) =>
        referrals.where((r) => r.status == MerchantReferralStatus.completed).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// ============================================================
// FAMILY PROVIDER: Referral per dealer specifico
// ============================================================

/// Referral per uno specifico dealer_contact_id (null se non esiste)
final dealerReferralProvider =
    Provider.family<MerchantReferral?, String>((ref, dealerContactId) {
  final referralsAsync = ref.watch(merchantReferralsStreamProvider);
  return referralsAsync.when(
    data: (referrals) {
      try {
        return referrals.firstWhere((r) => r.dealerContactId == dealerContactId);
      } catch (_) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Map dealer_contact_id → referral status
final dealerReferralStatusMapProvider =
    Provider<Map<String, MerchantReferralStatus>>((ref) {
  final referralsAsync = ref.watch(merchantReferralsStreamProvider);
  return referralsAsync.when(
    data: (referrals) {
      final map = <String, MerchantReferralStatus>{};
      for (final r in referrals) {
        if (r.dealerContactId != null) {
          map[r.dealerContactId!] = r.status;
        }
      }
      return map;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

// ============================================================
// STATS PROVIDER: Stats aggregate
// ============================================================

/// Stats aggregate (pending/active/completed count + total bonus)
final merchantReferralStatsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  return await MerchantReferralService.getStats();
});
