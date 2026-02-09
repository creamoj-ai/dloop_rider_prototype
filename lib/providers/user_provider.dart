import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/user_service.dart';

// ========================================
// Provider: UserService instance
// ========================================
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

// ========================================
// Provider: Current User (AsyncNotifier)
// ========================================
class CurrentUserNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    // Carica l'utente corrente all'avvio
    final userService = ref.read(userServiceProvider);
    return await userService.getCurrentUser();
  }

  // Ricarica i dati dell'utente
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final userService = ref.read(userServiceProvider);
    final user = await userService.getCurrentUser();
    state = AsyncValue.data(user);
  }

  // Aggiorna profilo
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
  }) async {
    final userService = ref.read(userServiceProvider);
    final updatedUser = await userService.updateProfile(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      avatarUrl: avatarUrl,
    );

    if (updatedUser != null) {
      state = AsyncValue.data(updatedUser);
    }
  }

  // Set online status
  Future<void> setOnlineStatus(bool isOnline) async {
    final userService = ref.read(userServiceProvider);
    final success = await userService.setOnlineStatus(isOnline);

    if (success) {
      // Aggiorna lo stato locale
      state.whenData((user) {
        if (user != null) {
          state = AsyncValue.data(user.copyWith(isOnline: isOnline));
        }
      });
    }
  }

  // Update location
  Future<void> updateLocation(double lat, double lng) async {
    final userService = ref.read(userServiceProvider);
    final success = await userService.updateLocation(lat, lng);

    if (success) {
      // Aggiorna lo stato locale
      state.whenData((user) {
        if (user != null) {
          state = AsyncValue.data(user.copyWith(
            currentLat: lat,
            currentLng: lng,
            lastLocationUpdate: DateTime.now(),
          ));
        }
      });
    }
  }

  // Logout
  void logout() {
    state = const AsyncValue.data(null);
  }
}

// Provider istanza
final currentUserProvider = AsyncNotifierProvider<CurrentUserNotifier, User?>(() {
  return CurrentUserNotifier();
});

// ========================================
// Provider: User Stream (Realtime)
// ========================================
final userStreamProvider = StreamProvider<User?>((ref) {
  final userService = ref.read(userServiceProvider);
  return userService.watchCurrentUser();
});

// ========================================
// Computed Providers (helpers)
// ========================================

// Is user authenticated?
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Is user online?
final isOnlineProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.isOnline ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

// User full name
final userFullNameProvider = Provider<String>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.fullName ?? 'Guest',
    loading: () => 'Loading...',
    error: (_, __) => 'Error',
  );
});

// User referral code
final userReferralCodeProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.referralCode,
    loading: () => null,
    error: (_, __) => null,
  );
});
