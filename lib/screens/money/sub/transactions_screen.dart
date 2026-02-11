import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';
import '../../../models/earning.dart';
import '../../../providers/transactions_provider.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
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

    final allTxs = ref.watch(allTransactionsProvider);

    final filtered = _filterIndex == 0
        ? allTxs
        : allTxs.where((t) {
            switch (_filterIndex) {
              case 1: return t.type == EarningType.delivery;
              case 2: return t.type == EarningType.network;
              case 3: return t.type == EarningType.market;
              default: return true;
            }
          }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Transazioni', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, size: 48, color: Colors.grey[700]),
                        const SizedBox(height: 12),
                        Text(
                          'Nessuna transazione',
                          style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final tx = filtered[i];
                      final icon = _iconForType(tx.type);
                      final color = _colorForType(tx.type);
                      final timeLabel = _relativeTime(tx.dateTime);

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
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.description.isNotEmpty ? tx.description : _defaultDesc(tx.type),
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                                  ),
                                  Text(timeLabel, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9E9E9E))),
                                ],
                              ),
                            ),
                            Text(
                              '+\u20AC ${tx.amount.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.earningsGreen),
                            ),
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

  static IconData _iconForType(EarningType type) {
    switch (type) {
      case EarningType.delivery: return Icons.bolt;
      case EarningType.network: return Icons.eco;
      case EarningType.market: return Icons.shopping_cart;
    }
  }

  static Color _colorForType(EarningType type) {
    switch (type) {
      case EarningType.delivery: return AppColors.turboOrange;
      case EarningType.network: return AppColors.earningsGreen;
      case EarningType.market: return AppColors.bonusPurple;
    }
  }

  static String _defaultDesc(EarningType type) {
    switch (type) {
      case EarningType.delivery: return 'Consegna';
      case EarningType.network: return 'Commissione network';
      case EarningType.market: return 'Vendita market';
    }
  }

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'adesso';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min fa';
    if (diff.inHours < 24) return '${diff.inHours}h fa';
    if (diff.inDays == 1) return 'Ieri';
    if (diff.inDays < 7) return '${diff.inDays} giorni fa';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
