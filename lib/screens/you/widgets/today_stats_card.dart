import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/dloop_card.dart';

class TodayStatsCard extends StatelessWidget {
  const TodayStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DloopCard(
      child: Column(
        children: [
          // Header centrato
          Center(
            child: Text(
              'OGGI',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Grid 3 colonne
          Row(
            children: [
              _statColumn(
                context,
                icon: Icons.shopping_bag_outlined,
                value: '8',
                label: 'Ordini',
                color: AppColors.turboOrange,
              ),
              const SizedBox(width: 12),
              _statColumn(
                context,
                icon: Icons.schedule,
                value: '6.5h',
                label: 'Ore',
                color: AppColors.earningsGreen,
              ),
              const SizedBox(width: 12),
              _statColumn(
                context,
                icon: Icons.euro,
                value: '142.60',
                label: 'Guadagno',
                color: AppColors.bonusPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statColumn(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
