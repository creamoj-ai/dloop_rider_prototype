import 'package:flutter/material.dart';
import 'widgets/balance_hero.dart';
import 'widgets/income_streams.dart';
import 'widgets/recent_activity.dart';

class MoneyScreen extends StatelessWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
    );
  }
}
