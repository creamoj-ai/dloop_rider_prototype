import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/partner_offer.dart';
import '../services/partner_benefits_service.dart';

final partnerBenefitsServiceProvider = Provider<PartnerBenefitsService>((ref) {
  return PartnerBenefitsService();
});

final partnerOffersProvider = FutureProvider<List<PartnerOffer>>((ref) async {
  final service = ref.read(partnerBenefitsServiceProvider);
  return service.getActiveOffers();
});
