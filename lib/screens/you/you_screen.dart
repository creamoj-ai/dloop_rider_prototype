import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/tokens.dart';
import '../../widgets/dloop_top_bar.dart';
import '../../widgets/invite_sheet.dart';
import '../../widgets/header_sheets.dart';
import 'pricing_settings_screen.dart';
import 'widgets/profile_header.dart';
import 'widgets/gamification_card.dart';
import 'widgets/lifetime_stats.dart';

class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final pricing = ref.watch(riderPricingProvider);

    return SafeArea(
      child: Column(
        children: [
          DloopTopBar(
            isOnline: true,
            notificationCount: 1,
            searchHint: 'Cerca impostazioni...',
            onSearchTap: () => SearchSheet.show(context, hint: 'Cerca impostazioni...'),
            onNotificationTap: () => NotificationsSheet.show(context),
            onQuickActionTap: () => QuickActionsSheet.show(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  const ProfileHeader(),
                  const SizedBox(height: 24),
                  // Today snapshot pills
                  Row(
                    children: [
                      _pill(cs, 'Ordini', '8', AppColors.turboOrange),
                      const SizedBox(width: 10),
                      _pill(cs, 'Ore', '6.5h', AppColors.earningsGreen),
                      const SizedBox(width: 10),
                      _pill(cs, 'Guadagno', '\u20AC142.60', AppColors.bonusPurple),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const GamificationCard(),
                  const SizedBox(height: 24),
                  _buildTariffeSection(context, cs, pricing),
                  const SizedBox(height: 24),
                  _buildInviteSection(context, cs),
                  const SizedBox(height: 24),
                  const LifetimeStats(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTariffeSection(BuildContext context, ColorScheme cs, dynamic pricing) {
    final sampleEarning = pricing.calculateBaseEarning(3.5);

    return InkWell(
      onTap: () => context.go('/you/pricing'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.earningsGreen.withOpacity(0.15),
              AppColors.routeBlue.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.earningsGreen.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.earningsGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.euro,
                    color: AppColors.earningsGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Le Mie Tariffe',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.earningsGreen,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Rate pills row
            Row(
              children: [
                _ratePill(cs, '\u20AC${pricing.ratePerKm.toStringAsFixed(2)}', '/km', AppColors.earningsGreen),
                const SizedBox(width: 8),
                _ratePill(cs, 'min \u20AC${pricing.minDeliveryFee.toStringAsFixed(2)}', '', AppColors.turboOrange),
                const SizedBox(width: 8),
                _ratePill(cs, '\u20AC${pricing.holdCostPerMin.toStringAsFixed(2)}', '/min', AppColors.bonusPurple),
              ],
            ),
            const SizedBox(height: 14),

            // Distance tiers
            Row(
              children: [
                _tierDot(AppColors.earningsGreen),
                const SizedBox(width: 4),
                Text(
                  '0\u2013${pricing.shortDistanceMax.toStringAsFixed(0)}km',
                  style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                _tierDot(AppColors.routeBlue),
                const SizedBox(width: 4),
                Text(
                  '${pricing.shortDistanceMax.toStringAsFixed(0)}\u2013${pricing.mediumDistanceMax.toStringAsFixed(0)}km',
                  style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                _tierDot(AppColors.turboOrange),
                const SizedBox(width: 4),
                Text(
                  '>${pricing.mediumDistanceMax.toStringAsFixed(0)}km',
                  style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.earningsGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '3.5km \u2192 \u20AC${sampleEarning.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.earningsGreen,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ratePill(ColorScheme cs, String value, String suffix, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Center(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: suffix,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tierDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildInviteSection(BuildContext context, ColorScheme cs) {
    return InkWell(
      onTap: () => InviteSheet.show(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.turboOrange.withValues(alpha: 0.2),
              AppColors.turboOrange.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.turboOrange.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.turboOrange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.card_giftcard,
                color: AppColors.turboOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invita amici',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Guadagna €10 per ogni rider',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.turboOrange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(ColorScheme cs, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}
