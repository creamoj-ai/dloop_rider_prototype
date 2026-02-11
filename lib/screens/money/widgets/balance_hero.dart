import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';
import '../../../models/earning.dart';
import '../../../providers/transactions_provider.dart';

class BalanceHero extends ConsumerStatefulWidget {
  const BalanceHero({super.key});

  @override
  ConsumerState<BalanceHero> createState() => _BalanceHeroState();
}

class _BalanceHeroState extends ConsumerState<BalanceHero> {
  bool _isPendingExpanded = false;

  static const _typeLabels = {
    EarningType.delivery: 'Consegne',
    EarningType.network: 'Network',
    EarningType.market: 'Market',
  };

  static const _typeColors = {
    EarningType.delivery: AppColors.turboOrange,
    EarningType.network: AppColors.earningsGreen,
    EarningType.market: AppColors.bonusPurple,
  };

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(completedBalanceProvider);
    final pendingTotal = ref.watch(pendingBalanceProvider);
    final pendingByType = ref.watch(pendingByTypeProvider);

    // Format balance Italian style (1.847,50)
    final balanceFormatted = _formatEuro(balance);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SALDO DISPONIBILE',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF9E9E9E),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '\u20AC $balanceFormatted',
          style: GoogleFonts.inter(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        if (pendingTotal > 0) _buildPendingCard(pendingTotal, pendingByType),
      ],
    );
  }

  String _formatEuro(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    // Add dots for thousands
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPart[i]);
    }
    return '$buffer,$decPart';
  }

  Widget _buildPendingCard(double pendingTotal, Map<EarningType, PendingInfo> pendingByType) {
    return GestureDetector(
      onTap: () => setState(() => _isPendingExpanded = !_isPendingExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.earningsGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.earningsGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: AppColors.earningsGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '+\u20AC ${pendingTotal.toStringAsFixed(2)} in arrivo',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.earningsGreen,
                    ),
                  ),
                ),
                Icon(
                  _isPendingExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppColors.earningsGreen,
                ),
              ],
            ),
            if (_isPendingExpanded && pendingByType.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(height: 1, color: AppColors.earningsGreen.withValues(alpha: 0.2)),
              const SizedBox(height: 12),
              ...pendingByType.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildPendingRow(
                  _typeLabels[entry.key] ?? '',
                  '\u20AC${entry.value.total.toStringAsFixed(2)}',
                  '${entry.value.count} in elaborazione',
                  _typeColors[entry.key] ?? AppColors.routeBlue,
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRow(String label, String amount, String detail, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              Text(detail, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF9E9E9E))),
            ],
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}
