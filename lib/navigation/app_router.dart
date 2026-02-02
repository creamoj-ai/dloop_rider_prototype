import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_shell.dart';
import '../screens/today/today_screen.dart';
import '../screens/today/zone_map_screen.dart';
import '../screens/today/route_screen.dart';
import '../screens/money/money_screen.dart';
import '../screens/money/sub/transactions_screen.dart';
import '../screens/money/sub/network_screen.dart';
import '../screens/money/sub/analytics_screen.dart';
import '../screens/market/market_tab_screen.dart';
import '../screens/money/sub/market_screen.dart';
import '../screens/you/you_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/today',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/today',
          pageBuilder: (context, state) => const NoTransitionPage(child: TodayScreen()),
          routes: [
            GoRoute(path: 'zone', builder: (context, state) => const ZoneMapScreen()),
            GoRoute(path: 'route', builder: (context, state) => const RouteScreen()),
          ],
        ),
        GoRoute(
          path: '/money',
          pageBuilder: (context, state) => const NoTransitionPage(child: MoneyScreen()),
          routes: [
            GoRoute(path: 'transactions', builder: (context, state) => const TransactionsScreen()),
            GoRoute(path: 'network', builder: (context, state) => const NetworkScreen()),
            GoRoute(path: 'analytics', builder: (context, state) => const AnalyticsScreen()),
          ],
        ),
        GoRoute(
          path: '/market',
          pageBuilder: (context, state) => const NoTransitionPage(child: MarketTabScreen()),
          routes: [
            GoRoute(path: 'products', builder: (context, state) => const MarketScreen()),
          ],
        ),
        GoRoute(
          path: '/you',
          pageBuilder: (context, state) => const NoTransitionPage(child: YouScreen()),
        ),
      ],
    ),
  ],
);
