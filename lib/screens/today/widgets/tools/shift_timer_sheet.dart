import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/tokens.dart';
import '../../../../providers/shift_timer_provider.dart';
import '../../../../providers/active_orders_provider.dart';

class ShiftTimerSheet extends ConsumerStatefulWidget {
  const ShiftTimerSheet({super.key});

  @override
  ConsumerState<ShiftTimerSheet> createState() => _ShiftTimerSheetState();
}

class _ShiftTimerSheetState extends ConsumerState<ShiftTimerSheet> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTickTimer();
  }

  void _startTickTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(shiftTimerProvider.notifier).tick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timerState = ref.watch(shiftTimerProvider);
    final ordersState = ref.watch(activeOrdersProvider);
    final completedCount = ordersState.orders.where((o) => o.phase == OrderPhase.completed).length;
    final earningsPerHour = timerState.elapsedSeconds > 0
        ? (ordersState.totalEarning / (timerState.elapsedSeconds / 3600))
        : 0.0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.routeBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.timer, color: AppColors.routeBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Timer Turno', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
                    Text(timerState.isRunning ? 'In corso...' : 'In pausa', style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Timer display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: timerState.isRunning
                  ? AppColors.routeBlue.withValues(alpha: 0.1)
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: timerState.isRunning
                  ? Border.all(color: AppColors.routeBlue.withValues(alpha: 0.3))
                  : null,
            ),
            child: Column(
              children: [
                Text(
                  timerState.formattedTime,
                  style: GoogleFonts.inter(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: timerState.isRunning ? AppColors.routeBlue : cs.onSurfaceVariant,
                    letterSpacing: 2,
                  ),
                ),
                if (timerState.startedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Inizio: ${timerState.startedAt!.hour.toString().padLeft(2, '0')}:${timerState.startedAt!.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _statBox(cs, '$completedCount', 'Ordini', Icons.shopping_bag),
              const SizedBox(width: 12),
              _statBox(cs, '€${earningsPerHour.toStringAsFixed(1)}', '/ora', Icons.euro),
            ],
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              if (timerState.elapsedSeconds > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref.read(shiftTimerProvider.notifier).reset(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text('RESET', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.urgentRed,
                      side: BorderSide(color: AppColors.urgentRed.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              if (timerState.elapsedSeconds > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (timerState.isRunning) {
                      ref.read(shiftTimerProvider.notifier).stop();
                    } else {
                      ref.read(shiftTimerProvider.notifier).start();
                    }
                  },
                  icon: Icon(timerState.isRunning ? Icons.pause : Icons.play_arrow, size: 20),
                  label: Text(
                    timerState.isRunning ? 'PAUSA' : 'AVVIA TURNO',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: timerState.isRunning ? AppColors.turboOrange : AppColors.earningsGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _statBox(ColorScheme cs, String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(label, style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
