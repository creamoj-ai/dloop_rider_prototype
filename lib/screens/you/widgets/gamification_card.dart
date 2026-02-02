import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/dloop_card.dart';

class GamificationCard extends StatelessWidget {
  const GamificationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DloopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GAMIFICATION', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF9E9E9E), letterSpacing: 1)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat(Icons.local_fire_department, '12 giorni', 'Streak', AppColors.turboOrange),
              _stat(Icons.star, '12', 'Livello', AppColors.bonusPurple),
              _stat(Icons.emoji_events, '8/20', 'Badge', AppColors.statsGold),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _badge(Icons.shopping_bag, 'First Order', AppColors.turboOrange),
                _badge(Icons.flash_on, 'Speed Demon', AppColors.urgentRed),
                _badge(Icons.people, 'Network Builder', AppColors.earningsGreen),
                _badge(Icons.trending_up, 'Top Earner', AppColors.statsGold),
                _badge(Icons.favorite, 'Loyal Rider', AppColors.bonusPurple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9E9E9E))),
      ],
    );
  }

  Widget _badge(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF9E9E9E)), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
