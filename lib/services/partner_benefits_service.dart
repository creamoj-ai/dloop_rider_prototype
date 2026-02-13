import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/partner_offer.dart';
import '../utils/logger.dart';

class PartnerBenefitsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PartnerOffer>> getActiveOffers() async {
    try {
      final response = await _supabase
          .from('partner_offers')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => PartnerOffer.fromJson(json))
          .toList();
    } catch (e) {
      dlog('\u274c PartnerBenefits getActiveOffers error: $e');
      return _getDemoOffers();
    }
  }

  Future<void> trackClick(String offerId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('partner_clicks').insert({
        'user_id': userId,
        'offer_id': offerId,
      });
    } catch (e) {
      dlog('\u274c PartnerBenefits trackClick error: $e');
    }
  }

  List<PartnerOffer> _getDemoOffers() {
    final now = DateTime.now();
    return [
      PartnerOffer(
        id: 'demo_qover',
        name: 'Qover',
        slug: 'qover-insurance',
        description:
            'Assicurazione completa per rider: infortuni, RC, malattia. '
            'Usata da Deliveroo, Glovo e Wolt. Nessun deposito cauzionale richiesto.',
        shortDescription: 'Assicurazione rider professionale',
        referralBaseUrl: 'https://www.qover.com',
        commissionType: 'recurring',
        commissionValue: 4.0,
        targetAudience: ['rider'],
        category: 'insurance',
        phase: 1,
        sortOrder: 0,
        createdAt: now,
      ),
      PartnerOffer(
        id: 'demo_fiscozen',
        name: 'Fiscozen',
        slug: 'fiscozen-tax',
        description:
            'Gestione completa della tua Partita IVA: dichiarazioni, fatture, '
            'consulenza fiscale dedicata ai lavoratori gig economy. Sconto esclusivo DLOOP Pro.',
        shortDescription: 'Gestione P.IVA semplificata',
        referralBaseUrl: 'https://www.fiscozen.it',
        commissionType: 'flat_per_lead',
        commissionValue: 50.0,
        targetAudience: ['rider', 'dealer'],
        category: 'finance',
        phase: 1,
        sortOrder: 1,
        createdAt: now,
      ),
      PartnerOffer(
        id: 'demo_finom',
        name: 'Finom',
        slug: 'finom-business',
        description:
            'Conto business gratuito con IBAN italiano, carte virtuali illimitate, '
            'fatturazione integrata. Perfetto per ricevere i pagamenti DLOOP.',
        shortDescription: 'Conto business per freelancer',
        referralBaseUrl: 'https://www.finom.co',
        commissionType: 'flat_per_lead',
        commissionValue: 20.0,
        targetAudience: ['rider', 'dealer'],
        category: 'finance',
        phase: 1,
        sortOrder: 2,
        createdAt: now,
      ),
      PartnerOffer(
        id: 'demo_ho_mobile',
        name: 'ho. Mobile',
        slug: 'ho-mobile-data',
        description:
            'Piano dati illimitato a prezzo speciale per rider DLOOP. '
            'Rete Vodafone, nessun vincolo, attivazione immediata.',
        shortDescription: 'Piano dati per rider',
        referralBaseUrl: 'https://www.ho-mobile.it',
        commissionType: 'flat_per_lead',
        commissionValue: 10.0,
        targetAudience: ['rider'],
        category: 'telecom',
        phase: 2,
        sortOrder: 3,
        createdAt: now,
      ),
      PartnerOffer(
        id: 'demo_sumup',
        name: 'SumUp',
        slug: 'sumup-pos',
        description:
            'Lettore POS portatile senza canone mensile. Accetta pagamenti con carta '
            'direttamente nel tuo negozio. Commissione solo 1.95% per transazione.',
        shortDescription: 'POS senza canone per il tuo negozio',
        referralBaseUrl: 'https://www.sumup.it',
        commissionType: 'flat_per_lead',
        commissionValue: 15.0,
        targetAudience: ['dealer'],
        category: 'tools',
        phase: 2,
        sortOrder: 4,
        createdAt: now,
      ),
    ];
  }
}
