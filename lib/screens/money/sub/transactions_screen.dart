import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _filterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final filters = ['Tutti', 'Consegne', 'Network', 'Market'];
    final filterColors = [
      Colors.white,
      AppColors.turboOrange,
      AppColors.earningsGreen,
      AppColors.bonusPurple,
    ];

    final transactions = [
      _Tx('Consegna Via Roma', '12 min fa', '+\u20AC 4.80', Icons.bolt, AppColors.turboOrange, 0),
      _Tx('Commissione Dealer Marco', '1h fa', '+\u20AC 2.40', Icons.eco, AppColors.earningsGreen, 1),
      _Tx('Vendita Box Premium', '2h fa', '+\u20AC 15.00', Icons.shopping_cart, AppColors.bonusPurple, 2),
      _Tx('Consegna Piazza Duomo', '3h fa', '+\u20AC 5.20', Icons.bolt, AppColors.turboOrange, 0),
      _Tx('Commissione Cliente Anna', '4h fa', '+\u20AC 1.80', Icons.eco, AppColors.earningsGreen, 1),
      _Tx('Consegna Corso Italia', '5h fa', '+\u20AC 6.10', Icons.bolt, AppColors.turboOrange, 0),
      _Tx('Vendita Energy Drink Pack', '6h fa', '+\u20AC 8.50', Icons.shopping_cart, AppColors.bonusPurple, 2),
      _Tx('Commissione Dealer Luca', '7h fa', '+\u20AC 3.20', Icons.eco, AppColors.earningsGreen, 1),
      _Tx('Consegna Via Dante', 'Ieri', '+\u20AC 4.50', Icons.bolt, AppColors.turboOrange, 0),
      _Tx('Vendita Snack Box', 'Ieri', '+\u20AC 12.00', Icons.shopping_cart, AppColors.bonusPurple, 2),
    ];

    final filtered = _filterIndex == 0
        ? transactions
        : transactions.where((t) => t.category == _filterIndex - 1).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Transazioni', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: List.generate(filters.length, (i) {
                final sel = _filterIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      filters[i],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : filterColors[i],
                      ),
                    ),
                    selected: sel,
                    onSelected: (_) => setState(() => _filterIndex = i),
                    backgroundColor: Colors.transparent,
                    selectedColor: (i == 0 ? Colors.white : filterColors[i]).withOpacity(0.2),
                    side: BorderSide(color: filterColors[i].withOpacity(sel ? 0 : 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    showCheckmark: false,
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final tx = filtered[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: tx.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(tx.icon, color: tx.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.desc, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                            Text(tx.date, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9E9E9E))),
                          ],
                        ),
                      ),
                      Text(tx.amount, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.earningsGreen)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Tx {
  final String desc, date, amount;
  final IconData icon;
  final Color color;
  final int category; // 0=consegne, 1=network, 2=market
  _Tx(this.desc, this.date, this.amount, this.icon, this.color, this.category);
}
