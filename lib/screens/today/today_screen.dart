import 'package:flutter/material.dart';
import 'widgets/kpi_strip.dart';
import 'widgets/active_mode_card.dart';
import 'widgets/hot_zones.dart';
import 'widgets/wellness_card.dart';
import 'widgets/quick_actions_grid.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KpiStrip(),
                SizedBox(height: 24),
                ActiveModeCard(),
                SizedBox(height: 24),
                HotZones(),
                SizedBox(height: 24),
                QuickActionsGrid(),
                SizedBox(height: 24),
                WellnessCard(),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
