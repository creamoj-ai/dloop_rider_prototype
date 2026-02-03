import 'package:flutter/material.dart';
import '../../widgets/dloop_top_bar.dart';
import 'widgets/balance_hero.dart';
import 'widgets/income_streams.dart';
import 'widgets/recent_activity.dart';

class MoneyScreen extends StatelessWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          DloopTopBar(
            isOnline: true,
            notificationCount: 2,
            searchHint: 'Cerca transazioni...',
            onSearchTap: () {
              // TODO: Implementare ricerca transazioni
            },
          ),
          const Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BalanceHero(),
                  SizedBox(height: 24),
                  IncomeStreams(),
                  SizedBox(height: 24),
                  RecentActivity(),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
