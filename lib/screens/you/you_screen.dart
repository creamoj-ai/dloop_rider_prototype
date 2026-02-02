import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/tokens.dart';
import 'widgets/profile_header.dart';
import 'widgets/gamification_card.dart';
import 'widgets/lifetime_stats.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          const LifetimeStats(),
          const SizedBox(height: 32),
        ],
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
