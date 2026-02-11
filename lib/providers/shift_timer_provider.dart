import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/session_repository.dart';

class ShiftTimerState {
  final bool isRunning;
  final DateTime? startedAt;
  final int elapsedSeconds;
  final String? sessionId; // Supabase session ID

  const ShiftTimerState({
    this.isRunning = false,
    this.startedAt,
    this.elapsedSeconds = 0,
    this.sessionId,
  });

  String get formattedTime {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  ShiftTimerState copyWith({
    bool? isRunning,
    DateTime? startedAt,
    int? elapsedSeconds,
    String? sessionId,
  }) {
    return ShiftTimerState(
      isRunning: isRunning ?? this.isRunning,
      startedAt: startedAt ?? this.startedAt,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class ShiftTimerNotifier extends StateNotifier<ShiftTimerState> {
  final SessionRepository _repo = SessionRepository();

  ShiftTimerNotifier() : super(const ShiftTimerState());

  Future<void> start() async {
    // Start session in DB
    String? sessionId = state.sessionId;
    if (sessionId == null) {
      try {
        sessionId = await _repo.startSession();
      } catch (e) {
        debugPrint('Failed to start session in DB: $e');
      }
    }

    state = state.copyWith(
      isRunning: true,
      startedAt: state.startedAt ?? DateTime.now(),
      sessionId: sessionId,
    );
  }

  Future<void> stop() async {
    state = state.copyWith(isRunning: false);

    // Update session in DB with active minutes
    if (state.sessionId != null) {
      try {
        await _repo.updateSessionMetrics(
          state.sessionId!,
          activeMinutes: state.elapsedSeconds ~/ 60,
        );
      } catch (e) {
        debugPrint('Failed to update session metrics: $e');
      }
    }
  }

  void tick() {
    if (!state.isRunning || state.startedAt == null) return;
    final elapsed = DateTime.now().difference(state.startedAt!).inSeconds;
    state = state.copyWith(elapsedSeconds: elapsed);
  }

  Future<void> reset() async {
    // End session in DB
    if (state.sessionId != null) {
      try {
        await _repo.endSession(
          state.sessionId!,
          durationMinutes: state.elapsedSeconds ~/ 60,
          activeMinutes: state.elapsedSeconds ~/ 60,
        );
      } catch (e) {
        debugPrint('Failed to end session in DB: $e');
      }
    }

    state = const ShiftTimerState();
  }
}

final shiftTimerProvider = StateNotifierProvider<ShiftTimerNotifier, ShiftTimerState>(
  (ref) => ShiftTimerNotifier(),
);
