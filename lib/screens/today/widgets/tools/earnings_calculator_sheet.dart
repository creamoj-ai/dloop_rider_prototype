import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/tokens.dart';
import '../../../../providers/rider_stats_provider.dart';
import '../../../../services/rush_hour_service.dart';

class EarningsCalculatorSheet extends ConsumerStatefulWidget {
  const EarningsCalculatorSheet({super.key});

  @override
  ConsumerState<EarningsCalculatorSheet> createState() => _EarningsCalculatorSheetState();
}

class _EarningsCalculatorSheetState extends ConsumerState<EarningsCalculatorSheet> {
  double _hours = 4;
  int _ordersPerHour = 3;

  double _avgEarning(RiderStats stats) {
    if (stats.lifetimeOrders > 0) {
      return stats.lifetimeEarnings / stats.lifetimeOrders;
    }
    return 4.50; // fallback
  }

  bool get _isRushHour => RushHourService.isRushHourNow();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statsAsync = ref.watch(riderStatsProvider);

    return statsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator(color: AppColors.earningsGreen)),
      ),
      error: (_, __) => _buildContent(cs, const RiderStats()),
      data: (stats) => _buildContent(cs, stats),
    );
  }

  Widget _buildContent(ColorScheme cs, RiderStats stats) {
    final avg = _avgEarning(stats);
    final baseProjected = _hours * _ordersPerHour * avg;
    final projected = baseProjected * RushHourService.getCurrentMultiplier();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.earningsGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calculate, color: AppColors.earningsGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calcolatore Guadagni', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
                    Text(
                      stats.lifetimeOrders > 0
                          ? 'Media da ${stats.lifetimeOrders} ordini reali'
                          : 'Stima con media di default',
                      style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Hours slider
          Text('Ore di lavoro: ${_hours.toStringAsFixed(1)}h', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
          Slider(
            value: _hours,
            min: 1,
            max: 12,
            divisions: 22,
            activeColor: AppColors.earningsGreen,
            onChanged: (v) => setState(() => _hours = v),
          ),

          const SizedBox(height: 16),

          // Orders per hour
          Text('Ordini per ora: $_ordersPerHour', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final value = i + 1;
              final selected = value == _ordersPerHour;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 4 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _ordersPerHour = value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.earningsGreen.withValues(alpha: 0.2) : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                        border: selected ? Border.all(color: AppColors.earningsGreen) : null,
                      ),
                      child: Center(
                        child: Text(
                          '$value',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: selected ? AppColors.earningsGreen : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 24),

          // Result
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.earningsGreen.withValues(alpha: 0.2), AppColors.earningsGreen.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.earningsGreen.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text('Guadagno stimato', style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(
                  '€ ${projected.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.earningsGreen),
                ),
                if (_isRushHour) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.earningsGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('2X Rush Hour attivo!', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.earningsGreen)),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${(_hours * _ordersPerHour).toInt()} ordini totali • €${avg.toStringAsFixed(2)}/ordine${stats.lifetimeOrders > 0 ? ' (reale)' : ''}',
                  style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
