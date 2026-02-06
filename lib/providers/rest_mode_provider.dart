import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider per lo stato di riposo globale
final restModeProvider = StateNotifierProvider<RestModeNotifier, RestModeState>((ref) {
  return RestModeNotifier();
});

class RestModeState {
  final bool isResting;
  final int remainingSeconds;
  final int? totalMinutes;

  const RestModeState({
    this.isResting = false,
    this.remainingSeconds = 0,
    this.totalMinutes,
  });

  RestModeState copyWith({
    bool? isResting,
    int? remainingSeconds,
    int? totalMinutes,
  }) {
    return RestModeState(
      isResting: isResting ?? this.isResting,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalMinutes: totalMinutes ?? this.totalMinutes,
    );
  }
}

class RestModeNotifier extends StateNotifier<RestModeState> {
  RestModeNotifier() : super(const RestModeState());

  void startRest(int minutes) {
    state = RestModeState(
      isResting: true,
      remainingSeconds: minutes * 60,
      totalMinutes: minutes,
    );
  }

  void updateTime(int seconds) {
    state = state.copyWith(remainingSeconds: seconds);
  }

  void endRest() {
    state = const RestModeState();
  }
}
