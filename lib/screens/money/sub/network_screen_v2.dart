import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/merchant_referral.dart';
import '../../../providers/merchant_referrals_provider.dart';
import '../../../services/merchant_referral_service.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/dloop_card.dart';

/// Network Screen V2: Merchant Referrals Model
///
/// Modello SaaS puro: rider segnala dealer, riceve bonus FISSO una tantum.
/// NO commission, NO monthly earnings, NO dealer tier/subscription exposure.
class NetworkScreenV2 extends ConsumerWidget {
  const NetworkScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralsAsync = ref.watch(merchantReferralsStreamProvider);
    final pendingCount = ref.watch(pendingMerchantReferralsCountProvider);
    final activeCount = ref.watch(activeMerchantReferralsCountProvider);
    final completedCount = ref.watch(completedMerchantReferralsCountProvider);
    final totalBonus = ref.watch(merchantReferralBonusProvider);

    return Scaffold(
      backgroundColor: DloopTokens.bgBase,
      appBar: AppBar(
        title: const Text('Network'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: referralsAsync.when(
        data: (referrals) => _buildContent(
          context,
          ref,
          referrals,
          pendingCount,
          activeCount,
          completedCount,
          totalBonus,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Errore caricamento: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(merchantReferralsStreamProvider),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReferralSheet(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Segnala Dealer'),
        backgroundColor: DloopTokens.primary,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<MerchantReferral> referrals,
    int pendingCount,
    int activeCount,
    int completedCount,
    double totalBonus,
  ) {
    return CustomScrollView(
      slivers: [
        // KPI Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildKPISection(
              pendingCount,
              activeCount,
              completedCount,
              totalBonus,
            ),
          ),
        ),

        // Lista referrals
        if (referrals.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nessun dealer segnalato',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Inizia a segnalare dealer\nper guadagnare bonus',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final referral = referrals[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildReferralCard(context, ref, referral),
                  );
                },
                childCount: referrals.length,
              ),
            ),
          ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  Widget _buildKPISection(
    int pending,
    int active,
    int completed,
    double totalBonus,
  ) {
    return DloopCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'I Tuoi Referral',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildKPIItem(
                    label: 'In attesa',
                    value: pending.toString(),
                    color: Colors.grey,
                  ),
                ),
                Expanded(
                  child: _buildKPIItem(
                    label: 'Attivi',
                    value: active.toString(),
                    color: DloopTokens.turboOrange,
                  ),
                ),
                Expanded(
                  child: _buildKPIItem(
                    label: 'Completati',
                    value: completed.toString(),
                    color: DloopTokens.earningsGreen,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bonus Guadagnati',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  '€ ${totalBonus.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: DloopTokens.earningsGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildReferralCard(
    BuildContext context,
    WidgetRef ref,
    MerchantReferral referral,
  ) {
    return DloopCard(
      child: InkWell(
        onTap: () => _showReferralDetails(context, ref, referral),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Dealer name
                  Expanded(
                    child: Text(
                      referral.dealerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Status badge
                  _buildStatusBadge(referral.status),
                ],
              ),
              const SizedBox(height: 8),

              // Phone/email se disponibile
              if (referral.dealerPhone != null) ...[
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      referral.dealerPhone!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              // Progress bar (solo per active)
              if (referral.isActive) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          referral.progressLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${referral.progressPercent.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: referral.progressPercent / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(
                        DloopTokens.turboOrange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ancora ${referral.remainingOrders} ordini',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],

              // Bonus amount (sempre visibile)
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    referral.isCompleted ? 'Bonus Ricevuto' : 'Bonus Previsto',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '€ ${referral.bonusEur.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: referral.isCompleted
                          ? DloopTokens.earningsGreen
                          : Colors.grey,
                    ),
                  ),
                ],
              ),

              // Expiry warning (se in scadenza)
              if (referral.daysUntilExpiry != null &&
                  referral.daysUntilExpiry! < 30) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Scade tra ${referral.daysUntilExpiry} giorni',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(MerchantReferralStatus status) {
    Color color;
    String label;

    switch (status) {
      case MerchantReferralStatus.pending:
        color = Colors.grey;
        label = 'In attesa';
        break;
      case MerchantReferralStatus.active:
        color = DloopTokens.turboOrange;
        label = 'Attivo';
        break;
      case MerchantReferralStatus.completed:
        color = DloopTokens.earningsGreen;
        label = 'Completato';
        break;
      case MerchantReferralStatus.expired:
        color = Colors.red;
        label = 'Scaduto';
        break;
      case MerchantReferralStatus.cancelled:
        color = Colors.grey;
        label = 'Annullato';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  void _showAddReferralSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddMerchantReferralSheet(),
    );
  }

  void _showReferralDetails(
    BuildContext context,
    WidgetRef ref,
    MerchantReferral referral,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(referral.dealerName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Stato', referral.statusLabel),
            _buildDetailRow('Progresso', referral.progressLabel),
            _buildDetailRow(
              'Bonus',
              '€ ${referral.bonusEur.toStringAsFixed(2)}',
            ),
            if (referral.dealerPhone != null)
              _buildDetailRow('Telefono', referral.dealerPhone!),
            if (referral.dealerEmail != null)
              _buildDetailRow('Email', referral.dealerEmail!),
            _buildDetailRow(
              'Segnalato il',
              '${referral.createdAt.day}/${referral.createdAt.month}/${referral.createdAt.year}',
            ),
            if (referral.completedAt != null)
              _buildDetailRow(
                'Completato il',
                '${referral.completedAt!.day}/${referral.completedAt!.month}/${referral.completedAt!.year}',
              ),
          ],
        ),
        actions: [
          if (referral.canBeCancelled)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Annulla Referral'),
                    content: const Text(
                      'Sei sicuro di voler annullare questo referral? Non potrai ricevere il bonus.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annulla'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Conferma'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await MerchantReferralService.cancelReferral(referral.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Referral annullato')),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Annulla Referral'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Sheet per aggiungere nuovo referral
class AddMerchantReferralSheet extends StatefulWidget {
  const AddMerchantReferralSheet({super.key});

  @override
  State<AddMerchantReferralSheet> createState() =>
      _AddMerchantReferralSheetState();
}

class _AddMerchantReferralSheetState extends State<AddMerchantReferralSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final referralId = await MerchantReferralService.createReferral(
        dealerName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
      );

      if (referralId != null && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dealer segnalato con successo!'),
            backgroundColor: DloopTokens.earningsGreen,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante la segnalazione'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Segnala Nuovo Dealer',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nome (required)
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome Dealer *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Nome obbligatorio' : null,
            ),
            const SizedBox(height: 16),

            // Telefono (optional)
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefono',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Email (optional)
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),

            // Info bonus
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DloopTokens.earningsGreen.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: DloopTokens.earningsGreen),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Riceverai €50 quando il dealer completa i primi 10 ordini',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: DloopTokens.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Segnala Dealer',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
