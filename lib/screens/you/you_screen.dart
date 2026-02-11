import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/tokens.dart';
import '../../widgets/dloop_top_bar.dart';
import '../../widgets/invite_sheet.dart';
import '../../widgets/header_sheets.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/earnings_provider.dart';
import '../../providers/referral_provider.dart';
import 'widgets/profile_header.dart';
import 'widgets/today_stats_card.dart';
import 'widgets/stats_only_card.dart';
import 'widgets/expandable_gamification_card.dart';
import 'widgets/account_section.dart';

class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final isOnline = ref.watch(earningsProvider).isOnline;
    final activeReferrals = ref.watch(activeReferralsCountProvider);
    final referralBonus = ref.watch(referralBonusProvider);

    return SafeArea(
      child: Column(
        children: [
          DloopTopBar(
            isOnline: isOnline,
            notificationCount: unreadCount,
            searchHint: 'Cerca impostazioni...',
            onSearchTap: () => SearchSheet.show(context, hint: 'Cerca impostazioni...'),
            onNotificationTap: () => context.push('/today/notifications'),
            onQuickActionTap: () => QuickActionsSheet.show(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  // 1. Profile Header
                  const ProfileHeader(),
                  const SizedBox(height: 24),
                  // 2. Le Mie Statistiche di Oggi
                  const TodayStatsCard(),
                  const SizedBox(height: 24),
                  // 3. Invita Amici
                  _buildInviteSection(context, cs, activeReferrals, referralBonus),
                  const SizedBox(height: 24),
                  // 4. Le Mie Tariffe
                  _buildPricingSection(context, cs),
                  const SizedBox(height: 24),
                  // 5. Statistiche Lifetime
                  const StatsOnlyCard(),
                  const SizedBox(height: 24),
                  // 6. Gamification (espandibile)
                  const ExpandableGamificationCard(),
                  const SizedBox(height: 24),
                  // 7. Account
                  const AccountSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection(BuildContext context, ColorScheme cs) {
    return InkWell(
      onTap: () => context.go('/you/pricing'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.earningsGreen.withOpacity(0.2),
              AppColors.earningsGreen.withOpacity(0.05),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.earningsGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.tune,
                color: AppColors.earningsGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Le Mie Tariffe',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configura €/km, attesa, fasce distanza',
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
              color: AppColors.earningsGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteSection(BuildContext context, ColorScheme cs, int activeReferrals, double referralBonus) {
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
                    activeReferrals > 0
                        ? '$activeReferrals attivi • +€${referralBonus.toStringAsFixed(0)} guadagnati'
                        : 'Guadagna €10 per ogni rider',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: activeReferrals > 0 ? AppColors.earningsGreen : cs.onSurfaceVariant,
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
}
