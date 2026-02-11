import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/market_order.dart';
import '../../providers/market_orders_provider.dart';
import '../../providers/market_products_provider.dart';
import '../../services/market_orders_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/dloop_top_bar.dart';
import '../../widgets/header_sheets.dart';
import 'widgets/add_product_dialog.dart';
import 'widgets/market_order_card.dart';

class MarketTabScreen extends ConsumerWidget {
  const MarketTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productCount = ref.watch(productCountProvider);
    final weeklyOrders = ref.watch(weeklyMarketOrdersCountProvider);
    final monthlyEarnings = ref.watch(monthlyMarketEarningsProvider);
    final activeProducts = ref.watch(activeProductsProvider);
    final activeOrders = ref.watch(activeMarketOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
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
                  // KPI Row
                  SizedBox(
                    height: 50,
                    child: Row(
                      children: [
                        _kpiBox('$productCount', 'Prodotti', AppColors.turboOrange),
                        const SizedBox(width: 6),
                        _kpiBox('$weeklyOrders', 'Ordini', AppColors.routeBlue),
                        const SizedBox(width: 6),
                        _kpiBox(
                          '\u20AC${monthlyEarnings.toStringAsFixed(0)}',
                          'Guadagni',
                          AppColors.earningsGreen,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _label('Catalogo'),
                  const SizedBox(height: 6),
                  // Products grid from DB
                  if (activeProducts.isEmpty)
                    _emptyState('Nessun prodotto', 'Aggiungi il primo prodotto con il bottone +')
                  else
                    _buildProductsGrid(context, activeProducts),
                  const SizedBox(height: 12),
                  _label('Ordini attivi'),
                  const SizedBox(height: 6),
                  // Orders from DB
                  if (activeOrders.isEmpty)
                    _emptyState('Nessun ordine attivo', 'Gli ordini appariranno qui')
                  else
                    ...activeOrders.map((o) => MarketOrderCard(order: o)),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddProductDialog.show(context),
        backgroundColor: AppColors.turboOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _label(String t) => Text(
        t,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );

  Widget _emptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white54)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: Colors.white30)),
        ],
      ),
    );
  }

  Widget _kpiBox(String v, String l, Color c) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1E),
          borderRadius: BorderRadius.circular(8),
        ),
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

  Widget _buildProductsGrid(BuildContext ctx, List products) {
    final rows = <Widget>[];
    for (var i = 0; i < products.length; i += 2) {
      final left = products[i];
      final right = i + 1 < products.length ? products[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(child: _productCard(left.name, '\u20AC${left.price.toStringAsFixed(2)}', left.category, left, ctx)),
              const SizedBox(width: 6),
              right != null
                  ? Expanded(child: _productCard(right.name, '\u20AC${right.price.toStringAsFixed(2)}', right.category, right, ctx))
                  : const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  Widget _productCard(String name, String price, String cat, dynamic product, BuildContext ctx) {
    final c = cat == 'bevande'
        ? AppColors.routeBlue
        : cat == 'food'
            ? AppColors.turboOrange
            : AppColors.earningsGreen;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name,
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(price, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
                Text('Stock: ${product.stock}',
                    style: GoogleFonts.inter(fontSize: 7, color: Colors.white38)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showCreateOrderDialog(ctx, product),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.turboOrange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.send, size: 10, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateOrderDialog(BuildContext ctx, dynamic product) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');

    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1E),
        title: Text('Nuovo ordine: ${product.name}',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(nameCtrl, 'Nome cliente'),
              const SizedBox(height: 8),
              _field(phoneCtrl, 'Telefono'),
              const SizedBox(height: 8),
              _field(addressCtrl, 'Indirizzo'),
              const SizedBox(height: 8),
              _field(qtyCtrl, 'Quantita\'', isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Annulla', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.turboOrange),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final qty = int.tryParse(qtyCtrl.text) ?? 1;

              await MarketOrdersService.createMarketOrder(
                productId: product.id,
                productName: product.name,
                customerName: name,
                customerPhone: phoneCtrl.text.trim(),
                customerAddress: addressCtrl.text.trim(),
                quantity: qty,
                unitPrice: product.price,
              );

              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Ordine creato per $name')),
                );
              }
            },
            child: Text('Crea ordine', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.turboOrange)),
      ),
    );
  }
}
