import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';
import '../../../providers/earnings_provider.dart';
import '../../../models/order.dart';

/// Card unificata per EARN - sostituisce ActiveModeCard
/// Mostra: stato ordine + obiettivo giornaliero + azioni
class EarnCard extends ConsumerWidget {
  const EarnCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(earningsProvider);
    final cs = Theme.of(context).colorScheme;

    // Se offline
    if (!earnings.isOnline) {
      return _OfflineCard(
        onGoOnline: () => ref.read(earningsProvider.notifier).setOnline(true),
      );
    }

    // Se ha ordine attivo
    if (earnings.hasActiveOrder) {
      return _OrdineAttivoCard(
        order: earnings.activeOrder!,
        target: earnings.dailyTarget,
        onPickup: () => ref.read(earningsProvider.notifier).pickupOrder(),
        onDeliver: () => ref.read(earningsProvider.notifier).completeDelivery(tipAmount: 1.50),
      );
    }

    // Ordine disponibile
    return _NuovoOrdineCard(
      target: earnings.dailyTarget,
      onAccept: () {
        final order = Order.create(
          id: 'order_${DateTime.now().millisecondsSinceEpoch}',
          restaurantName: 'Pizzeria Da Mario',
          customerAddress: 'Via Verdi 42',
          distanceKm: 2.5,
          bonusEarning: 1.0,
        );
        ref.read(earningsProvider.notifier).acceptOrder(order);
      },
    );
  }
}

/// Card ordine attivo
class _OrdineAttivoCard extends StatelessWidget {
  final Order order;
  final dynamic target;
  final VoidCallback onPickup;
  final VoidCallback onDeliver;

  const _OrdineAttivoCard({
    required this.order,
    required this.target,
    required this.onPickup,
    required this.onDeliver,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPickedUp = order.status == OrderStatus.pickedUp;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.turboOrange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.turboOrange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPickedUp ? 'IN CONSEGNA' : 'DA RITIRARE',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.turboOrange,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Dettagli ordine
          Text(
            order.restaurantName,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '→ ${order.customerAddress}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          // Info: km + guadagno
          Row(
            children: [
              Icon(Icons.straighten, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '${order.distanceKm.toStringAsFixed(1)} km',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 20),
              Icon(Icons.euro, size: 14, color: AppColors.earningsGreen),
              const SizedBox(width: 4),
              Text(
                '€ ${order.totalEarning.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.earningsGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Obiettivo giornaliero integrato
          _TargetProgress(target: target),
          const SizedBox(height: 20),

          // CTA
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isPickedUp ? onDeliver : onPickup,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.turboOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isPickedUp ? 'CONSEGNATO' : 'HO RITIRATO',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card nuovo ordine
class _NuovoOrdineCard extends StatelessWidget {
  final dynamic target;
  final VoidCallback onAccept;

  const _NuovoOrdineCard({
    required this.target,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.earningsGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.earningsGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'NUOVO ORDINE',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.earningsGreen,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Dettagli
          Text(
            'Pizzeria Da Mario',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '→ Via Verdi 42',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          // Info
          Row(
            children: [
              Icon(Icons.straighten, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '2.5 km',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 20),
              Icon(Icons.euro, size: 14, color: AppColors.earningsGreen),
              const SizedBox(width: 4),
              Text(
                '€ 4.75',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.earningsGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Obiettivo
          _TargetProgress(target: target),
          const SizedBox(height: 20),

          // CTA
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.earningsGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ACCETTA E VAI',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card offline
class _OfflineCard extends StatelessWidget {
  final VoidCallback onGoOnline;

  const _OfflineCard({required this.onGoOnline});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.power_settings_new, size: 40, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'Sei offline',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vai online per ricevere ordini',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onGoOnline,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.earningsGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'VAI ONLINE',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress bar obiettivo giornaliero (compatta)
class _TargetProgress extends StatelessWidget {
  final dynamic target;

  const _TargetProgress({required this.target});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '€ ${target.currentAmount.toStringAsFixed(0)} / € ${target.targetAmount.toStringAsFixed(0)} oggi',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
            Text(
              '${target.progressPercent}%',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: target.isComplete ? AppColors.earningsGreen : AppColors.routeBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: target.progress,
            minHeight: 6,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              target.isComplete ? AppColors.earningsGreen : AppColors.routeBlue,
            ),
          ),
        ),
      ],
    );
  }
}
