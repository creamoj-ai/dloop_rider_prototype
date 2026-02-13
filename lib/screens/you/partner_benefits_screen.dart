import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/tokens.dart';
import '../../providers/partner_benefits_provider.dart';
import '../../models/partner_offer.dart';

class PartnerBenefitsScreen extends ConsumerWidget {
  const PartnerBenefitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final offersAsync = ref.watch(partnerOffersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DLOOP Pro Vantaggi',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: offersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.bonusPurple),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: cs.error),
              const SizedBox(height: 16),
              Text('Errore nel caricamento', style: GoogleFonts.inter(color: cs.error)),
            ],
          ),
        ),
        data: (offers) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(cs),
            const SizedBox(height: 24),
            ...offers.map((offer) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _PartnerOfferCard(offer: offer),
            )),
            const SizedBox(height: 16),
            _buildFooter(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.bonusPurple.withValues(alpha: 0.15),
            AppColors.bonusPurple.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(
          color: AppColors.bonusPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bonusPurple.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: AppColors.bonusPurple,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Vantaggi esclusivi Pro',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Servizi selezionati da DLOOP per semplificare il tuo lavoro. Sconti e offerte riservate ai membri Pro.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Nuovi partner in arrivo ogni mese',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _PartnerOfferCard extends ConsumerWidget {
  final PartnerOffer offer;

  const _PartnerOfferCard({required this.offer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final color = _categoryColor(offer.category);
    final icon = _categoryIcon(offer.category);

    return InkWell(
      onTap: () => _openOffer(context, ref),
      borderRadius: BorderRadius.circular(Radii.lg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          offer.name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _categoryLabel(offer.category),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer.shortDescription,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.open_in_new, size: 14, color: color),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Scopri di piu',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...offer.targetAudience.map((audience) => Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            audience == 'rider' ? 'Rider' : 'Dealer',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openOffer(BuildContext context, WidgetRef ref) async {
    final service = ref.read(partnerBenefitsServiceProvider);
    service.trackClick(offer.id);

    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';
    final url = Uri.parse(offer.referralUrl(userId));

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'insurance':
        return AppColors.routeBlue;
      case 'finance':
        return AppColors.earningsGreen;
      case 'telecom':
        return AppColors.turboOrange;
      case 'tools':
        return AppColors.statsGold;
      case 'mobility':
        return AppColors.bonusPurple;
      default:
        return AppColors.routeBlue;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'insurance':
        return Icons.shield_outlined;
      case 'finance':
        return Icons.account_balance_outlined;
      case 'telecom':
        return Icons.phone_android_outlined;
      case 'tools':
        return Icons.point_of_sale_outlined;
      case 'mobility':
        return Icons.electric_bike_outlined;
      default:
        return Icons.card_giftcard_outlined;
    }
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'insurance':
        return 'Assicurazione';
      case 'finance':
        return 'Finanza';
      case 'telecom':
        return 'Telefonia';
      case 'tools':
        return 'Strumenti';
      case 'mobility':
        return 'Mobilita';
      default:
        return category;
    }
  }
}
