import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Market', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI row
            Row(
              children: [
                _kpi(cs, '12', 'Prodotti'),
                const SizedBox(width: 12),
                _kpi(cs, '6', 'Ordini/sett'),
                const SizedBox(width: 12),
                _kpi(cs, '\u20AC180', '/mese'),
              ],
            ),
            const SizedBox(height: 24),
            Text('Catalogo', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _productCard(cs, 'Energy Drink Box', '\u20AC 15.00', 'Bevande'),
                _productCard(cs, 'Snack Box', '\u20AC 12.00', 'Food'),
                _productCard(cs, 'Premium Water', '\u20AC 8.50', 'Bevande'),
                _productCard(cs, 'Protein Bar Pack', '\u20AC 18.00', 'Food'),
                _productCard(cs, 'Electrolyte Mix', '\u20AC 9.90', 'Integratori'),
                _productCard(cs, 'Coffee Kit', '\u20AC 22.00', 'Bevande'),
              ],
            ),
            const SizedBox(height: 24),
            Text('Ordini Recenti', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 12),
            _orderTile(cs, 'Anna V.', 'Energy Drink Box', '\u20AC 15.00', 'Consegnato'),
            _orderTile(cs, 'Paolo G.', 'Snack Box', '\u20AC 12.00', 'In corso'),
            _orderTile(cs, 'Maria L.', 'Protein Bar Pack', '\u20AC 18.00', 'Nuovo'),
          ],
        ),
      ),
    );
  }

  Widget _kpi(ColorScheme cs, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9E9E9E))),
          ],
        ),
      ),
    );
  }

  Widget _productCard(ColorScheme cs, String name, String price, String category) {
    final catColor = category == 'Bevande'
        ? AppColors.routeBlue
        : category == 'Food'
            ? AppColors.turboOrange
            : AppColors.earningsGreen;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(price, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: catColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(category, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: catColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderTile(ColorScheme cs, String customer, String product, String amount, String status) {
    final statusColor = status == 'Consegnato'
        ? AppColors.earningsGreen
        : status == 'In corso'
            ? AppColors.turboOrange
            : AppColors.routeBlue;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                Text(product, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9E9E9E))),
              ],
            ),
          ),
          Text(amount, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
          ),
        ],
      ),
    );
  }
}
