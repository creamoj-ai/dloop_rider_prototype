import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/tokens.dart';
import '../../widgets/dloop_top_bar.dart';
import '../../widgets/invite_sheet.dart';
import '../../widgets/header_sheets.dart';
import 'widgets/profile_header.dart';
import 'widgets/gamification_card.dart';
import 'widgets/lifetime_stats.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
                  Center(
                    child: Text('OGGI', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF9E9E9E), letterSpacing: 1)),
                  ),
                  const SizedBox(height: 10),
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
                  const LifetimeStats(),
                  const SizedBox(height: 24),
                  _buildInviteSection(context, cs),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
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
