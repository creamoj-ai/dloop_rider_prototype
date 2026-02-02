import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/tokens.dart';

class MarketTabScreen extends StatelessWidget {
  const MarketTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.earningsGreen,
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: Text('Bot WhatsApp', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bot WhatsApp in arrivo')),
          );
        },
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Dropshipping KPI Strip ---
                  Row(
                    children: [
                      _kpiCard('Prodotti attivi', '12', AppColors.turboOrange),
                      const SizedBox(width: 10),
                      _kpiCard('Ordini settimana', '6', AppColors.routeBlue),
                      const SizedBox(width: 10),
                      _kpiCard('Commissioni mese', '€180', AppColors.earningsGreen),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // --- Catalogo Section ---
                  Text(
                    'Catalogo Prodotti',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.95,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _productCard(context, 'Energy Drink Box', '€15.00', 'Bevande'),
                      _productCard(context, 'Snack Box', '€12.00', 'Food'),
                      _productCard(context, 'Premium Water', '€8.50', 'Bevande'),
                      _productCard(context, 'Protein Bar Pack', '€18.00', 'Food'),
                      _productCard(context, 'Electrolyte Mix', '€9.90', 'Integratori'),
                      _productCard(context, 'Coffee Kit', '€22.00', 'Bevande'),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // --- Ordini Recenti Section ---
                  Text(
                    'Ordini Recenti',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  _orderTile(context, 'Anna V.', 'Energy Drink Box', '€15.00', 'Consegnato'),
                  _orderTile(context, 'Paolo G.', 'Snack Box', '€12.00', 'In corso'),
                  _orderTile(context, 'Maria L.', 'Protein Bar Pack', '€18.00', 'Nuovo'),
                  _orderTile(context, 'Luca R.', 'Premium Water', '€8.50', 'Consegnato'),
                  _orderTile(context, 'Sara B.', 'Coffee Kit', '€22.00', 'In corso'),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _kpiCard(String label, String value, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1E),
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: accent)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF9E9E9E)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _productCard(BuildContext context, String name, String price, String category) {
    final catColor = category == 'Bevande'
        ? AppColors.routeBlue
        : category == 'Food'
            ? AppColors.turboOrange
            : AppColors.earningsGreen;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
          Text(price, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: catColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(category, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: catColor)),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invio $name al cliente...')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.turboOrange, borderRadius: BorderRadius.circular(8)),
                  child: Text('INVIA', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderTile(BuildContext context, String customer, String product, String amount, String status) {
    final statusColor = status == 'Consegnato'
        ? AppColors.earningsGreen
        : status == 'In corso'
            ? AppColors.turboOrange
            : AppColors.routeBlue;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
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
          Text(amount, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.earningsGreen)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Messaggia $customer...')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.bonusPurple.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Text('MESSAGGIA', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.bonusPurple)),
            ),
          ),
        ],
      ),
    );
  }
}
