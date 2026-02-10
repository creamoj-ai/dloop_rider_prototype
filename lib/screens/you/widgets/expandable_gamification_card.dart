import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/dloop_card.dart';
import '../../../providers/rider_stats_provider.dart';

class ExpandableGamificationCard extends ConsumerStatefulWidget {
  const ExpandableGamificationCard({super.key});

  @override
  ConsumerState<ExpandableGamificationCard> createState() => _ExpandableGamificationCardState();
}

class _ExpandableGamificationCardState extends ConsumerState<ExpandableGamificationCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statsAsync = ref.watch(riderStatsProvider);

    final stats = statsAsync.when(
      data: (s) => s,
      loading: () => const RiderStats(),
      error: (_, __) => const RiderStats(),
    );

    return DloopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header cliccabile
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 18,
                    color: AppColors.statsGold,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GAMIFICATION',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // XP progress bar inline
                  Expanded(
                    child: _isExpanded
                        ? const SizedBox.shrink()
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: stats.xpProgress,
                              minHeight: 4,
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation(AppColors.bonusPurple),
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Lv ${stats.currentLevel}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.bonusPurple,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Contenuto espandibile
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const SizedBox(height: 16),
                // XP progress bar (expanded)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${stats.currentXp} XP',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                        ),
                        Text(
                          '${stats.xpToNextLevel} XP',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: stats.xpProgress,
                        minHeight: 6,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation(AppColors.bonusPurple),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat(
                      Icons.local_fire_department,
                      '${stats.currentDailyStreak} giorni',
                      'Streak',
                      AppColors.turboOrange,
                    ),
                    _stat(
                      Icons.star,
                      '${stats.currentLevel}',
                      'Livello',
                      AppColors.bonusPurple,
                    ),
                    _stat(
                      Icons.emoji_events,
                      '${stats.achievementsUnlocked}/20',
                      'Badge',
                      AppColors.statsGold,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _badge(Icons.shopping_bag, 'First Order', AppColors.turboOrange, true),
                      _badge(Icons.flash_on, 'Speed Demon', AppColors.urgentRed, stats.lifetimeOrders >= 100),
                      _badge(Icons.people, 'Network Builder', AppColors.earningsGreen, stats.lifetimeOrders >= 200),
                      _badge(Icons.trending_up, 'Top Earner', AppColors.statsGold, stats.lifetimeEarnings >= 5000),
                      _badge(Icons.favorite, 'Loyal Rider', AppColors.bonusPurple, stats.currentDailyStreak >= 7),
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
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

  Widget _badge(IconData icon, String label, Color color, bool unlocked) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.3,
        child: Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF9E9E9E)), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
