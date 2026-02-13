import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Countdown timer widget showing seconds remaining until expiry.
/// Turns red when < 15 seconds. Calls [onExpired] when timer hits 0.
class CountdownTimer extends StatefulWidget {
  final DateTime expiresAt;
  final VoidCallback? onExpired;

  const CountdownTimer({
    super.key,
    required this.expiresAt,
    this.onExpired,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _updateSecondsLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateSecondsLeft();
      if (_secondsLeft <= 0) {
        _timer.cancel();
        widget.onExpired?.call();
      }
    });
  }

  void _updateSecondsLeft() {
    final diff = widget.expiresAt.difference(DateTime.now()).inSeconds;
    if (mounted) setState(() => _secondsLeft = diff.clamp(0, 999));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = _secondsLeft < 15;
    return Text(
      '${_secondsLeft}s',
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFFFF9800),
      ),
    );
  }
}
