import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/fee_audit.dart';
import '../../../providers/fee_audit_provider.dart';
import '../../../theme/tokens.dart';

/// Bottom sheet showing fee breakdown for a completed order.
class FeeBreakdownSheet extends ConsumerWidget {
  final String orderId;
  const FeeBreakdownSheet({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feeAsync = ref.watch(feeAuditProvider(orderId));

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Dettagli Fee',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 16),
          feeAsync.when(
            data: (fee) =>
                fee != null ? _buildBreakdown(fee) : _buildNoData(),
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.turboOrange),
            ),
            error: (e, _) => Text('Errore: $e',
                style: GoogleFonts.inter(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoData() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text('Nessun dato fee disponibile',
          style: GoogleFonts.inter(color: Colors.grey)),
    );
  }

  Widget _buildBreakdown(FeeAudit fee) {
    return Column(
      children: [
        // Total
        _feeRow('Totale cliente', fee.totalEur, Colors.white, isBold: true),
        const Divider(color: Color(0xFF333333), height: 24),
        // Dealer
        _feeRow('Quota dealer', fee.dealerEur, AppColors.earningsGreen),
        _feeBar(fee.dealerPercent, AppColors.earningsGreen),
        const SizedBox(height: 12),
        // Rider delivery
        if (fee.riderDeliveryFeeCents > 0) ...[
          _feeRow('Consegna rider', fee.riderEur, AppColors.routeBlue),
          const SizedBox(height: 12),
        ],
        // DLOOP platform fee
        _feeRow('Service fee DLOOP', fee.platformEur, AppColors.turboOrange),
        _feeBar(fee.platformPercent, AppColors.turboOrange),
        const SizedBox(height: 12),
        // Stripe fee (estimated)
        _feeRow('Fee Stripe (stima)', fee.stripeEur, Colors.grey.shade500),
        const SizedBox(height: 16),
        // Tier badge
        if (fee.dealerTier != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _tierColor(fee.dealerTier!).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Tier: ${_tierLabel(fee.dealerTier!)}${fee.perOrderFeeApplied ? ' (+\u20AC0.50/ordine)' : ''}',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _tierColor(fee.dealerTier!),
              ),
            ),
          ),
      ],
    );
  }

  Widget _feeRow(String label, double amount, Color color,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: color,
            )),
        Text('\u20AC${amount.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: color,
            )),
      ],
    );
  }

  Widget _feeBar(double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: percent / 100.0,
          backgroundColor: const Color(0xFF333333),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 4,
        ),
      ),
    );
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'pro':
        return AppColors.routeBlue;
      case 'business':
        return AppColors.turboOrange;
      case 'enterprise':
        return AppColors.bonusPurple;
      default:
        return Colors.grey;
    }
  }

  String _tierLabel(String tier) {
    switch (tier) {
      case 'starter':
        return 'Starter';
      case 'pro':
        return 'Pro';
      case 'business':
        return 'Business';
      case 'enterprise':
        return 'Enterprise';
      default:
        return tier;
    }
  }
}

/// Show fee breakdown as bottom sheet.
void showFeeBreakdownSheet(BuildContext context, String orderId) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => FeeBreakdownSheet(orderId: orderId),
  );
}
