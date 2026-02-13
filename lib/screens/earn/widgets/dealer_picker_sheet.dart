import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/rider_contact.dart';
import '../../../providers/contacts_provider.dart';
import '../../../theme/tokens.dart';

/// Shows a bottom sheet to pick a dealer from rider's contacts.
/// Returns the selected [RiderContact] or null if dismissed.
Future<RiderContact?> showDealerPickerSheet(BuildContext context) {
  return showModalBottomSheet<RiderContact>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DealerPickerSheet(),
  );
}

class _DealerPickerSheet extends ConsumerStatefulWidget {
  const _DealerPickerSheet();

  @override
  ConsumerState<_DealerPickerSheet> createState() => _DealerPickerSheetState();
}

class _DealerPickerSheetState extends ConsumerState<_DealerPickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final dealersAsync = ref.watch(dealersProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.store, color: AppColors.earningsGreen, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Seleziona Dealer',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cerca dealer...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Divider(color: Color(0xFF333333), height: 1),
            // Dealer list
            Expanded(
              child: dealersAsync.when(
                data: (dealers) {
                  final filtered = _searchQuery.isEmpty
                      ? dealers
                      : dealers.where((d) =>
                          d.name.toLowerCase().contains(_searchQuery) ||
                          (d.phone?.contains(_searchQuery) ?? false)).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.store_mall_directory_outlined,
                                color: Colors.grey.shade600, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Nessun dealer.\nAggiungine dalla schermata Network.'
                                  : 'Nessun risultato per "$_searchQuery"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Color(0xFF2A2A2A), height: 1, indent: 72),
                    itemBuilder: (context, i) {
                      final dealer = filtered[i];
                      return _DealerTile(
                        dealer: dealer,
                        onTap: () => Navigator.pop(context, dealer),
                      );
                    },
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.earningsGreen)),
                error: (_, __) => Center(
                  child: Text('Errore caricamento dealer',
                      style: TextStyle(color: Colors.grey.shade500)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DealerTile extends StatelessWidget {
  final RiderContact dealer;
  final VoidCallback onTap;

  const _DealerTile({required this.dealer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.earningsGreen.withOpacity(0.15),
        child: const Icon(Icons.store, color: AppColors.earningsGreen, size: 20),
      ),
      title: Text(
        dealer.name,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        '${dealer.phone ?? 'Nessun telefono'} • ${dealer.totalOrders} ordini',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: dealer.isActive
              ? AppColors.earningsGreen.withOpacity(0.15)
              : Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          dealer.isActive ? 'Attivo' : 'Potenziale',
          style: TextStyle(
            color: dealer.isActive ? AppColors.earningsGreen : Colors.grey,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
