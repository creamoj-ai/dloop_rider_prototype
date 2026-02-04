import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/rush_hour_service.dart';
import '../providers/earnings_provider.dart';

/// Banner che mostra lo stato Rush Hour
/// Si mostra automaticamente quando è attivo o sta per iniziare
class RushHourBanner extends ConsumerWidget {
  const RushHourBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRushHour = ref.watch(isRushHourProvider);
    final minutesToRush = ref.watch(minutesToRushHourProvider);

    // Se è rush hour, mostra banner attivo
    if (isRushHour) {
      return _ActiveRushBanner();
    }

    // Se rush hour inizia tra meno di 30 minuti, mostra countdown
    if (minutesToRush != null && minutesToRush <= 30) {
      return _UpcomingRushBanner(minutesRemaining: minutesToRush);
    }

    // Altrimenti non mostrare nulla
    return const SizedBox.shrink();
  }
}

/// Banner quando Rush Hour è ATTIVO
class _ActiveRushBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final activeSlot = RushHourService.getActiveSlot();
    final minutesRemaining = RushHourService.minutesRemainingInRushHour();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icona animata
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Text('🔥', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),

          // Testo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'RUSH HOUR ATTIVO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '2X',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activeSlot != null
                      ? '${activeSlot.label} • ${minutesRemaining ?? 0} min rimanenti'
                      : 'Guadagni raddoppiati!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Badge moltiplicatore
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Text(
                  '×2',
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'BASE',
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner quando Rush Hour sta per iniziare
class _UpcomingRushBanner extends StatelessWidget {
  final int minutesRemaining;

  const _UpcomingRushBanner({required this.minutesRemaining});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Rush Hour tra $minutesRemaining min • Guadagni 2X',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              RushHourService.formatTimeRemaining(minutesRemaining),
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge compatto per indicare Rush Hour (da usare in altre parti dell'UI)
class RushHourBadge extends StatelessWidget {
  final bool large;

  const RushHourBadge({super.key, this.large = false});

  @override
  Widget build(BuildContext context) {
    if (!RushHourService.isRushHourNow()) {
      return const SizedBox.shrink();
    }

    if (large) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.orange, Colors.deepOrange],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔥', style: TextStyle(fontSize: 14)),
            SizedBox(width: 6),
            Text(
              'RUSH 2X',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '🔥 2X',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
