import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/tokens.dart';

class IncomeStreams extends StatefulWidget {
  const IncomeStreams({super.key});

  @override
  State<IncomeStreams> createState() => _IncomeStreamsState();
}

class _IncomeStreamsState extends State<IncomeStreams> {
  final _controller = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StreamData('CONSEGNE', Icons.delivery_dining, '\u20AC 2.400/mese',
          '8 oggi', '\u20AC 14.80/h', AppColors.turboOrange, '/money/analytics'),
      _StreamData('NETWORK', Icons.people, '\u20AC 340/mese',
          '4 dealer', '5 clienti', AppColors.earningsGreen, '/money/network'),
      _StreamData('MARKET', Icons.shopping_cart, '\u20AC 180/mese',
          '12 prodotti', '6 ordini/sett', AppColors.bonusPurple, '/money/market'),
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
                    : const Color(0xFF9E9E9E).withOpacity(0.3),
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
