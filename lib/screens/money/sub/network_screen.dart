import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/rider_contact.dart';
import '../../../providers/contacts_provider.dart';
import '../../../providers/order_relay_provider.dart';
import '../../../services/contacts_service.dart';
import '../../../theme/tokens.dart';

class NetworkScreen extends ConsumerWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final contactsAsync = ref.watch(contactsStreamProvider);
    final activeDealers = ref.watch(activeDealersCountProvider);
    final clientsCount = ref.watch(clientsCountProvider);
    final monthlyEarnings = ref.watch(contactsMonthlyEarningsProvider);

    return Scaffold(
      appBar: AppBar(
          title: Text('Network',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.earningsGreen,
        onPressed: () => _showAddContactDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: contactsAsync.when(
        loading: () => const Center(
            child:
                CircularProgressIndicator(color: AppColors.turboOrange)),
        error: (e, _) => Center(
            child: Text('Errore: $e',
                style: GoogleFonts.inter(color: cs.onSurfaceVariant))),
        data: (contacts) {
          final dealers =
              contacts.where((c) => c.isDealer).toList();
          final clients =
              contacts.where((c) => c.isClient).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI row
                Row(
                  children: [
                    _kpi(cs, '$activeDealers', 'Dealer attivi'),
                    const SizedBox(width: 12),
                    _kpi(cs, '$clientsCount', 'Clienti'),
                    const SizedBox(width: 12),
                    _kpi(cs,
                        '\u20AC${monthlyEarnings.toStringAsFixed(0)}',
                        '/mese'),
                  ],
                ),
                const SizedBox(height: 24),
                if (dealers.isNotEmpty) ...[
                  Text('Dealer',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 12),
                  ...dealers.map((d) => _dealerTile(cs, d, context, ref)),
                  const SizedBox(height: 24),
                ],
                if (clients.isNotEmpty) ...[
                  Text('Clienti',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 12),
                  ...clients.map((c) => _clientTile(cs, c, context)),
                ],
                if (contacts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Column(
                        children: [
                          Icon(Icons.people_outline,
                              size: 64,
                              color:
                                  cs.onSurfaceVariant.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text('Nessun contatto',
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: cs.onSurfaceVariant)),
                          const SizedBox(height: 8),
                          Text(
                              'Aggiungi dealer e clienti con il pulsante +',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant
                                      .withOpacity(0.6))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _kpi(ColorScheme cs, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: const Color(0xFF9E9E9E))),
          ],
        ),
      ),
    );
  }

  Widget _dealerTile(
      ColorScheme cs, RiderContact d, BuildContext context, WidgetRef ref) {
    final relayCount = ref.watch(dealerRelayCountProvider(d.id));
    return Dismissible(
      key: Key(d.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: AppColors.urgentRed,
            borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context, d.name),
      onDismissed: (_) => ContactsService.deleteContact(d.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: cs.surface, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            CircleAvatar(
                radius: 18,
                backgroundColor:
                    AppColors.earningsGreen.withOpacity(0.2),
                child: const Icon(Icons.person,
                    color: AppColors.earningsGreen, size: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.name,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(
                        d.phone ?? '${d.totalOrders} ordini',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF9E9E9E))),
                  ]),
            ),
            if (relayCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.routeBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('$relayCount relay',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.routeBlue)),
              ),
              const SizedBox(width: 6),
            ],
            if (d.monthlyEarnings > 0)
              Text(
                  '\u20AC ${d.monthlyEarnings.toStringAsFixed(0)}/mese',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF9E9E9E))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (d.isActive
                        ? AppColors.earningsGreen
                        : AppColors.turboOrange)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                  d.isActive ? 'Attivo' : 'Potenziale',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: d.isActive
                          ? AppColors.earningsGreen
                          : AppColors.turboOrange)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clientTile(
      ColorScheme cs, RiderContact c, BuildContext context) {
    return Dismissible(
      key: Key(c.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: AppColors.urgentRed,
            borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context, c.name),
      onDismissed: (_) => ContactsService.deleteContact(c.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: cs.surface, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            CircleAvatar(
                radius: 18,
                backgroundColor:
                    AppColors.bonusPurple.withOpacity(0.2),
                child: const Icon(Icons.person,
                    color: AppColors.bonusPurple, size: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(c.name,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (c.isVip) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color:
                              AppColors.statsGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('VIP',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.statsGold)),
                    ),
                  ],
                ],
              ),
            ),
            Text('${c.totalOrders} ordini',
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF9E9E9E))),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(
      BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Elimina contatto',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text('Vuoi eliminare $name dalla tua lista?',
            style: GoogleFonts.inter()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Annulla', style: GoogleFonts.inter())),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Elimina',
                  style: GoogleFonts.inter(
                      color: AppColors.urgentRed))),
        ],
      ),
    );
  }

  void _showAddContactDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedType = 'dealer';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: cs.surface,
          title: Text('Aggiungi contatto',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: GoogleFonts.inter(color: cs.onSurface),
                decoration: InputDecoration(
                  labelText: 'Nome',
                  labelStyle: GoogleFonts.inter(
                      color: cs.onSurfaceVariant),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                style: GoogleFonts.inter(color: cs.onSurface),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telefono (opzionale)',
                  labelStyle: GoogleFonts.inter(
                      color: cs.onSurfaceVariant),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _typeChip(
                      'Dealer', 'dealer', selectedType,
                      AppColors.earningsGreen, cs,
                      () => setDialogState(
                          () => selectedType = 'dealer')),
                  const SizedBox(width: 8),
                  _typeChip(
                      'Cliente', 'client', selectedType,
                      AppColors.bonusPurple, cs,
                      () => setDialogState(
                          () => selectedType = 'client')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:
                    Text('Annulla', style: GoogleFonts.inter())),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.earningsGreen),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ContactsService.addContact(
                    name: name,
                    contactType: selectedType,
                    phone: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name aggiunto!'),
                        backgroundColor: AppColors.earningsGreen,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Errore: $e'),
                        backgroundColor: AppColors.urgentRed,
                      ),
                    );
                  }
                }
              },
              child: Text('Aggiungi',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, String value, String selected,
      Color color, ColorScheme cs, VoidCallback onTap) {
    final isSelected = selected == value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: color.withOpacity(0.5))
              : null,
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? color : cs.onSurfaceVariant)),
      ),
    );
  }
}
