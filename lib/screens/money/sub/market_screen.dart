import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/market_orders_provider.dart';
import '../../../providers/market_products_provider.dart';
import '../../../theme/tokens.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final productCount = ref.watch(productCountProvider);
    final weeklyOrders = ref.watch(weeklyMarketOrdersCountProvider);
    final monthlyEarnings = ref.watch(monthlyMarketEarningsProvider);
    final productsByCategory = ref.watch(productsByCategoryProvider);
    final completedOrders = ref.watch(completedMarketOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Market', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI row
            Row(
              children: [
                _kpi(cs, '$productCount', 'Prodotti'),
                const SizedBox(width: 12),
                _kpi(cs, '$weeklyOrders', 'Ordini/sett'),
                const SizedBox(width: 12),
                _kpi(cs, '\u20AC${monthlyEarnings.toStringAsFixed(0)}', '/mese'),
              ],
            ),
            const SizedBox(height: 24),
            Text('Catalogo',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 12),
            if (productsByCategory.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Nessun prodotto',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
                ),
              )
            else
              ...productsByCategory.entries.map((entry) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          entry.key.toUpperCase(),
                          style: GoogleFonts.inter(
                              fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white38, letterSpacing: 1),
                        ),
                      ),
                      GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: entry.value
                            .map((p) => _productCard(cs, p.name, '\u20AC${p.price.toStringAsFixed(2)}', entry.key))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  )),
            Text('Ordini Recenti',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 12),
            if (completedOrders.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Nessun ordine completato',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
                ),
              )
            else
              ...completedOrders.take(5).map(
                    (o) => _orderTile(cs, o.customerName, o.productName,
                        '\u20AC${o.totalPrice.toStringAsFixed(2)}', o.statusLabel),
                  ),
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
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9E9E9E))),
          ],
        ),
      ),
    );
  }

  Widget _productCard(ColorScheme cs, String name, String price, String category) {
    final catColor = category == 'bevande'
        ? AppColors.routeBlue
        : category == 'food'
            ? AppColors.turboOrange
            : AppColors.earningsGreen;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(price,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                    overflow: TextOverflow.ellipsis),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(category,
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: catColor),
                      overflow: TextOverflow.ellipsis),
                ),
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
        : status == 'In consegna'
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
                Text(customer,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(product, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9E9E9E)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(amount,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
          ),
        ],
      ),
    );
  }
}
