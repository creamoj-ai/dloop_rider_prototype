import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/tokens.dart';
import '../../widgets/dloop_top_bar.dart';
import '../../widgets/invite_sheet.dart';
import 'widgets/balance_hero.dart';
import 'widgets/income_streams.dart';
import 'widgets/recent_activity.dart';

class MoneyScreen extends StatelessWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          DloopTopBar(
            isOnline: true,
            notificationCount: 2,
            searchHint: 'Cerca transazioni...',
            onSearchTap: () {},
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BalanceHero(),
                  const SizedBox(height: 24),
                  _buildInviteEarnCard(context, cs),
                  const SizedBox(height: 24),
                  const IncomeStreams(),
                  const SizedBox(height: 24),
                  const RecentActivity(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteEarnCard(BuildContext context, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.earningsGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.earningsGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: AppColors.earningsGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Guadagna di più',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invita amici',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '€10 per ogni rider attivo',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => InviteSheet.show(context),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.earningsGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'INVITA',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'I tuoi invitati: 3 attivi',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
              Text(
                '+€30 guadagnati',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.earningsGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
