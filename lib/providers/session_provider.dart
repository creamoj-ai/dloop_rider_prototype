import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/session_repository.dart';

/// Active session state
class ActiveSessionState {
  final bool isLoading;
  final String? error;
  final bool hasActiveSession;
  final String mode;
  final String zoneName;
  final String zoneCity;
  final double sessionEarnings;
  final int ordersCompleted;
  final double distanceKm;
  final int activeMinutes;
  final DateTime? startTime;

  const ActiveSessionState({
    this.isLoading = true,
    this.error,
    this.hasActiveSession = false,
    this.mode = 'earn',
    this.zoneName = '',
    this.zoneCity = '',
    this.sessionEarnings = 0,
    this.ordersCompleted = 0,
    this.distanceKm = 0,
    this.activeMinutes = 0,
    this.startTime,
  });

  ActiveSessionState copyWith({
    bool? isLoading,
    String? error,
    bool? hasActiveSession,
    String? mode,
    String? zoneName,
    String? zoneCity,
    double? sessionEarnings,
    int? ordersCompleted,
    double? distanceKm,
    int? activeMinutes,
    DateTime? startTime,
  }) {
    return ActiveSessionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasActiveSession: hasActiveSession ?? this.hasActiveSession,
      mode: mode ?? this.mode,
      zoneName: zoneName ?? this.zoneName,
      zoneCity: zoneCity ?? this.zoneCity,
      sessionEarnings: sessionEarnings ?? this.sessionEarnings,
      ordersCompleted: ordersCompleted ?? this.ordersCompleted,
      distanceKm: distanceKm ?? this.distanceKm,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      startTime: startTime ?? this.startTime,
    );
  }
}

class ActiveSessionNotifier extends StateNotifier<ActiveSessionState> {
  final SessionRepository _repo = SessionRepository();

  ActiveSessionNotifier() : super(const ActiveSessionState()) {
    load();
  }

  /// Reload data (for pull-to-refresh or manual retry)
  Future<void> reload() => load();

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final session = await _repo.getActiveSession();
      if (session == null) {
        state = state.copyWith(isLoading: false, hasActiveSession: false);
        return;
      }

      state = ActiveSessionState(
        isLoading: false,
        hasActiveSession: true,
        mode: session['mode'] ?? 'earn',
        zoneName: '',
        zoneCity: '',
        sessionEarnings: (session['session_earnings'] as num?)?.toDouble() ?? 0,
        ordersCompleted: (session['orders_completed'] as num?)?.toInt() ?? 0,
        distanceKm: (session['distance_km'] as num?)?.toDouble() ?? 0,
        activeMinutes: (session['active_minutes'] as num?)?.toInt() ?? 0,
        startTime: session['start_time'] != null
            ? DateTime.tryParse(session['start_time'])
            : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final activeSessionProvider =
    StateNotifierProvider<ActiveSessionNotifier, ActiveSessionState>(
  (ref) => ActiveSessionNotifier(),
);
