import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../utils/retry.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ========================================
  // GET: Profilo utente corrente (with retry)
  // ========================================
  Future<User?> getCurrentUser() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      return await retry(() async {
        final response = await _supabase
            .from('users')
            .select()
            .eq('id', userId)
            .single();

        return User.fromJson(response);
      }, onRetry: (attempt, e) {
        print('⚡ UserService.getCurrentUser retry $attempt: $e');
      });
    } catch (e) {
      print('❌ UserService.getCurrentUser failed after retries: $e');
      return null;
    }
  }

  // ========================================
  // GET: Profilo utente per ID
  // ========================================
  Future<User?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return User.fromJson(response);
    } catch (e) {
      print('❌ Error getting user by ID: $e');
      return null;
    }
  }

  // ========================================
  // UPDATE: Aggiorna profilo (with retry)
  // ========================================
  Future<User?> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      return await retry(() async {
        final updates = <String, dynamic>{};
        if (firstName != null) updates['first_name'] = firstName;
        if (lastName != null) updates['last_name'] = lastName;
        if (phone != null) updates['phone'] = phone;
        if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

        final response = await _supabase
            .from('users')
            .update(updates)
            .eq('id', userId)
            .select()
            .single();

        return User.fromJson(response);
      }, onRetry: (attempt, e) {
        print('⚡ UserService.updateProfile retry $attempt: $e');
      });
    } catch (e) {
      print('❌ UserService.updateProfile failed after retries: $e');
      return null;
    }
  }

  // ========================================
  // UPDATE: Stato online
  // ========================================
  Future<bool> setOnlineStatus(bool isOnline) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('users')
          .update({'is_online': isOnline})
          .eq('id', userId);

      return true;
    } catch (e) {
      print('❌ Error setting online status: $e');
      return false;
    }
  }

  // ========================================
  // UPDATE: Posizione in tempo reale
  // ========================================
  Future<bool> updateLocation(double lat, double lng) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('users')
          .update({
            'current_lat': lat,
            'current_lng': lng,
            'last_location_update': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return true;
    } catch (e) {
      print('❌ Error updating location: $e');
      return false;
    }
  }

  // ========================================
  // UPDATE: Incrementa statistiche dopo ordine
  // ========================================
  Future<bool> incrementOrderStats(double earnings) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // RPC per incremento atomico
      await _supabase.rpc('increment_user_stats', params: {
        'user_id': userId,
        'earnings_amount': earnings,
      });

      return true;
    } catch (e) {
      print('❌ Error incrementing order stats: $e');
      // Fallback: update manuale
      try {
        final user = await getCurrentUser();
        if (user == null) return false;

        await _supabase
            .from('users')
            .update({
              'total_orders': user.totalOrders + 1,
              'total_earnings': user.totalEarnings + earnings,
            })
            .eq('id', user.id);

        return true;
      } catch (e) {
        print('❌ Fallback update failed: $e');
        return false;
      }
    }
  }

  // ========================================
  // GET: Utente tramite referral code
  // ========================================
  Future<User?> getUserByReferralCode(String code) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('referral_code', code)
          .single();

      return User.fromJson(response);
    } catch (e) {
      print('❌ Error getting user by referral code: $e');
      return null;
    }
  }

  // ========================================
  // REALTIME: Stream profilo corrente
  // ========================================
  Stream<User?> watchCurrentUser() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value(null);

    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) {
          if (data.isEmpty) return null;
          return User.fromJson(data.first);
        });
  }

  // ========================================
  // DELETE: Elimina account (soft delete)
  // ========================================
  Future<bool> deactivateAccount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('users')
          .update({
            'is_active': false,
            'is_online': false,
          })
          .eq('id', userId);

      return true;
    } catch (e) {
      print('❌ Error deactivating account: $e');
      return false;
    }
  }
}
