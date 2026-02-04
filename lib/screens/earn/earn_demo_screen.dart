import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/tokens.dart';
import '../../providers/earnings_provider.dart';
import '../../models/order.dart';
import '../../services/rush_hour_service.dart';

/// Schermata EARN - Guadagna con le consegne
class EarnDemoScreen extends ConsumerWidget {
  const EarnDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(earningsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, earnings),

            // Contenuto
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Obiettivo giornaliero
                    _ObiettivoCard(earnings: earnings),
                    const SizedBox(height: 16),

                    // Rush Hour (se attivo o vicino)
                    const _RushHourCard(),

                    // Ordine attivo o nuovo ordine
                    if (earnings.hasActiveOrder)
                      _OrdineAttivoCard(
                        order: earnings.activeOrder!,
                        onPickup: () => ref.read(earningsProvider.notifier).pickupOrder(),
                        onDeliver: () => ref.read(earningsProvider.notifier).completeDelivery(tipAmount: 1.50),
                      )
                    else if (earnings.isOnline)
                      _NuovoOrdineCard(
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
                      )
                    else
                      _OfflineCard(
                        onGoOnline: () => ref.read(earningsProvider.notifier).setOnline(true),
                      ),

                    const SizedBox(height: 16),

                    // Riepilogo guadagni
                    _RiepilogoCard(earnings: earnings),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EarningsState earnings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Guadagna',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          // Toggle online
          GestureDetector(
            onTap: () {
              // Toggle handled by provider
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: earnings.isOnline
                    ? AppColors.earningsGreen.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: earnings.isOnline ? AppColors.earningsGreen : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    earnings.isOnline ? 'Online' : 'Offline',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: earnings.isOnline ? AppColors.earningsGreen : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card obiettivo giornaliero - compatta
class _ObiettivoCard extends StatelessWidget {
  final EarningsState earnings;

  const _ObiettivoCard({required this.earnings});

  @override
  Widget build(BuildContext context) {
    final target = earnings.dailyTarget;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Obiettivo oggi',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (target.isComplete)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.earningsGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Raggiunto!',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.earningsGreen,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '€ ${target.currentAmount.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  '/ € ${target.targetAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${target.progressPercent}%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: target.isComplete ? AppColors.earningsGreen : AppColors.routeBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
          if (!target.isComplete && target.ordersCompleted > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Ancora ~${target.estimatedOrdersToComplete} consegne per € ${target.targetAmount.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card Rush Hour
class _RushHourCard extends StatelessWidget {
  const _RushHourCard();

  @override
  Widget build(BuildContext context) {
    final isRush = RushHourService.isRushHourNow();
    final minutesToRush = RushHourService.minutesToNextRushHour();
    final activeSlot = RushHourService.getActiveSlot();

    // Mostra solo se rush attivo o entro 30 minuti
    if (!isRush && (minutesToRush == null || minutesToRush > 30)) {
      return const SizedBox.shrink();
    }

    if (isRush) {
      final remaining = RushHourService.minutesRemainingInRushHour();
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rush Hour attivo',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Guadagni x2 • ${remaining ?? 0} min rimanenti',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '×2',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF6B00),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Rush in arrivo
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Rush Hour tra $minutesToRush min',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
            ),
          ),
          Text(
            'x2',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card ordine attivo
class _OrdineAttivoCard extends StatelessWidget {
  final Order order;
  final VoidCallback onPickup;
  final VoidCallback onDeliver;

  const _OrdineAttivoCard({
    required this.order,
    required this.onPickup,
    required this.onDeliver,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPickedUp = order.status == OrderStatus.pickedUp;

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              if (order.isRushHour)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🔥 x2',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Ristorante
          Text(
            order.restaurantName,
            style: GoogleFonts.inter(
              fontSize: 18,
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
          const SizedBox(height: 16),

          // Info
          Row(
            children: [
              Icon(Icons.straighten, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${order.distanceKm.toStringAsFixed(1)} km',
                style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.euro, size: 14, color: AppColors.earningsGreen),
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
                      letterSpacing: 0.5,
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

/// Card nuovo ordine disponibile
class _NuovoOrdineCard extends StatelessWidget {
  final VoidCallback onAccept;

  const _NuovoOrdineCard({required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRush = RushHourService.isRushHourNow();
    final multiplier = RushHourService.getCurrentMultiplier();

    // Calcola guadagno stimato
    const distanceKm = 2.5;
    final baseEarning = distanceKm * Order.ratePerKm;
    final totalEarning = baseEarning * multiplier + 1.0; // +1 bonus

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              if (isRush)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🔥 x2',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Pizzeria Da Mario',
            style: GoogleFonts.inter(
              fontSize: 18,
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
          const SizedBox(height: 16),

          Row(
            children: [
              Icon(Icons.straighten, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${distanceKm.toStringAsFixed(1)} km',
                style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.euro, size: 14, color: AppColors.earningsGreen),
              const SizedBox(width: 4),
              Text(
                '€ ${totalEarning.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.earningsGreen,
                ),
              ),
              if (isRush) ...[
                const SizedBox(width: 6),
                Text(
                  '(x2)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.orange,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

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
                    'ACCETTA',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.power_settings_new, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'Sei offline',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vai online per ricevere ordini',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
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
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card riepilogo guadagni
class _RiepilogoCard extends StatelessWidget {
  final EarningsState earnings;

  const _RiepilogoCard({required this.earnings});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final breakdown = earnings.todayBreakdown;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riepilogo oggi',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Consegne',
                value: '${earnings.ordersCount}',
                color: AppColors.routeBlue,
              ),
              _StatItem(
                label: 'Km',
                value: earnings.totalKmToday.toStringAsFixed(1),
                color: AppColors.turboOrange,
              ),
              _StatItem(
                label: '€/ora',
                value: '€ ${earnings.hourlyRate.toStringAsFixed(0)}',
                color: AppColors.earningsGreen,
              ),
            ],
          ),

          if (earnings.ordersCount > 0) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            _BreakdownRow('Base (€/km)', breakdown['base'] ?? 0),
            if ((breakdown['rush'] ?? 0) > 0)
              _BreakdownRow('Rush Hour', breakdown['rush'] ?? 0, isBonus: true),
            if ((breakdown['bonus'] ?? 0) > 0)
              _BreakdownRow('Bonus', breakdown['bonus'] ?? 0, isBonus: true),
            if ((breakdown['tips'] ?? 0) > 0)
              _BreakdownRow('Mance', breakdown['tips'] ?? 0, isBonus: true),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBonus;

  const _BreakdownRow(this.label, this.amount, {this.isBonus = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
          ),
          Text(
            '€ ${amount.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isBonus ? FontWeight.w600 : FontWeight.normal,
              color: isBonus ? AppColors.earningsGreen : cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
