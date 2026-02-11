import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/tokens.dart';
import '../../../models/earning.dart';
import '../../../providers/transactions_provider.dart';
import '../../../providers/earnings_provider.dart';

class IncomeStreams extends ConsumerStatefulWidget {
  const IncomeStreams({super.key});

  @override
  ConsumerState<IncomeStreams> createState() => _IncomeStreamsState();
}

class _IncomeStreamsState extends ConsumerState<IncomeStreams> {
  final _controller = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monthly = ref.watch(monthlyByTypeProvider);
    final earningsState = ref.watch(earningsProvider);
    final todayTxs = ref.watch(todayTransactionsProvider);

    final deliveryMonthly = monthly[EarningType.delivery];
    final networkMonthly = monthly[EarningType.network];
    final marketMonthly = monthly[EarningType.market];

    final todayDeliveries = todayTxs.where((t) => t.type == EarningType.delivery).length;

    final cards = [
      _StreamData(
        'CONSEGNE',
        Icons.delivery_dining,
        '\u20AC ${deliveryMonthly?.total.toStringAsFixed(0) ?? '0'}/mese',
        '$todayDeliveries oggi',
        '\u20AC ${earningsState.hourlyRate.toStringAsFixed(2)}/h',
        AppColors.turboOrange,
        '/money/analytics',
      ),
      _StreamData(
        'NETWORK',
        Icons.people,
        '\u20AC ${networkMonthly?.total.toStringAsFixed(0) ?? '0'}/mese',
        '${networkMonthly?.count ?? 0} commissioni',
        'questo mese',
        AppColors.earningsGreen,
        '/money/network',
      ),
      _StreamData(
        'MARKET',
        Icons.shopping_cart,
        '\u20AC ${marketMonthly?.total.toStringAsFixed(0) ?? '0'}/mese',
        '${marketMonthly?.count ?? 0} vendite',
        'questo mese',
        AppColors.bonusPurple,
        '/money/market',
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: cards.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) {
              final d = cards[i];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border(
                      left: BorderSide(color: d.color, width: 4),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(d.icon, color: d.color, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            d.title,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: d.color,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        d.mainStat,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${d.stat1}  \u2022  ${d.stat2}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.push(d.route),
                        child: Text(
                          'Dettagli >',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: d.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cards.length, (i) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == _currentPage
                    ? AppColors.turboOrange
                    : const Color(0xFF9E9E9E).withValues(alpha: 0.3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StreamData {
  final String title;
  final IconData icon;
  final String mainStat;
  final String stat1;
  final String stat2;
  final Color color;
  final String route;

  _StreamData(this.title, this.icon, this.mainStat, this.stat1, this.stat2,
      this.color, this.route);
}
