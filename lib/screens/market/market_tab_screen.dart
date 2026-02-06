import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/tokens.dart';
import '../../widgets/dloop_top_bar.dart';
import '../../widgets/header_sheets.dart';

class MarketTabScreen extends StatelessWidget {
  const MarketTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: AppColors.earningsGreen,
        child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bot WhatsApp in arrivo')),
          );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            DloopTopBar(
              isOnline: true,
              notificationCount: 0,
              searchHint: 'Cerca prodotti...',
              onSearchTap: () => SearchSheet.show(context, hint: 'Cerca prodotti...'),
              onNotificationTap: () => NotificationsSheet.show(context),
              onQuickActionTap: () => QuickActionsSheet.show(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildKpiRow(),
                  const SizedBox(height: 12),
                  _label('Catalogo'),
                  const SizedBox(height: 6),
                  _buildProductsGrid(context),
                  const SizedBox(height: 12),
                  _label('Ordini'),
                  const SizedBox(height: 6),
                  _buildOrdersList(context),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white));

  Widget _buildKpiRow() {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          _kpiBox('12', 'Prodotti', AppColors.turboOrange),
          const SizedBox(width: 6),
          _kpiBox('6', 'Ordini', AppColors.routeBlue),
          const SizedBox(width: 6),
          _kpiBox('€180', 'Guadagni', AppColors.earningsGreen),
        ],
      ),
    );
  }

  Widget _kpiBox(String v, String l, Color c) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF1A1A1E), borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(v, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: c)),
            ),
            Text(l, style: GoogleFonts.inter(fontSize: 8, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid(BuildContext ctx) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: _productCard('Energy', '€15', 'B', ctx)),
            const SizedBox(width: 6),
            Expanded(child: _productCard('Snack', '€12', 'F', ctx)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _productCard('Water', '€8.50', 'B', ctx)),
            const SizedBox(width: 6),
            Expanded(child: _productCard('Protein', '€18', 'F', ctx)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _productCard('Electro', '€9.90', 'I', ctx)),
            const SizedBox(width: 6),
            Expanded(child: _productCard('Coffee', '€22', 'B', ctx)),
          ],
        ),
      ],
    );
  }

  Widget _productCard(String name, String price, String cat, BuildContext ctx) {
    final c = cat == 'B' ? AppColors.routeBlue : cat == 'F' ? AppColors.turboOrange : AppColors.earningsGreen;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1E), borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(price, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Invio $name'))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: AppColors.turboOrange, borderRadius: BorderRadius.circular(4)),
              child: const Icon(Icons.send, size: 10, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(BuildContext ctx) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _orderRow('Anna V.', '€15', 'OK', AppColors.earningsGreen, ctx),
        _orderRow('Paolo G.', '€12', '...', AppColors.turboOrange, ctx),
        _orderRow('Maria L.', '€18', 'NEW', AppColors.routeBlue, ctx),
        _orderRow('Luca R.', '€8.50', 'OK', AppColors.earningsGreen, ctx),
      ],
    );
  }

  Widget _orderRow(String name, String amt, String stat, Color c, BuildContext ctx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1E), borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          Expanded(
            child: Text(name, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Text(amt, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.earningsGreen)),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
            child: Text(stat, style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.w600, color: c)),
          ),
          const SizedBox(width: 3),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Chat $name'))),
            child: const Icon(Icons.chat_bubble_outline, size: 10, color: AppColors.bonusPurple),
          ),
        ],
      ),
    );
  }
}
