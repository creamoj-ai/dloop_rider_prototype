/// Immutable audit trail for per-transaction fee splits.
class FeeAudit {
  final String id;
  final String orderId;
  final String? relayId;
  final String? dealerContactId;
  final String? riderId;
  final int totalAmountCents;
  final int dealerAmountCents;
  final int riderDeliveryFeeCents;
  final int platformFeeCents;
  final int stripeFeeCents;
  final String? dealerTier;
  final bool perOrderFeeApplied;
  final DateTime createdAt;

  const FeeAudit({
    required this.id,
    required this.orderId,
    this.relayId,
    this.dealerContactId,
    this.riderId,
    required this.totalAmountCents,
    this.dealerAmountCents = 0,
    this.riderDeliveryFeeCents = 0,
    this.platformFeeCents = 0,
    this.stripeFeeCents = 0,
    this.dealerTier,
    this.perOrderFeeApplied = false,
    required this.createdAt,
  });

  double get totalEur => totalAmountCents / 100.0;
  double get dealerEur => dealerAmountCents / 100.0;
  double get riderEur => riderDeliveryFeeCents / 100.0;
  double get platformEur => platformFeeCents / 100.0;
  double get stripeEur => stripeFeeCents / 100.0;

  /// Percentage of total that goes to the dealer.
  double get dealerPercent =>
      totalAmountCents > 0 ? dealerAmountCents / totalAmountCents * 100 : 0;

  /// Percentage of total that DLOOP keeps.
  double get platformPercent =>
      totalAmountCents > 0 ? platformFeeCents / totalAmountCents * 100 : 0;

  factory FeeAudit.fromJson(Map<String, dynamic> json) {
    return FeeAudit(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      relayId: json['relay_id']?.toString(),
      dealerContactId: json['dealer_contact_id']?.toString(),
      riderId: json['rider_id']?.toString(),
      totalAmountCents: (json['total_amount_cents'] as num?)?.toInt() ?? 0,
      dealerAmountCents: (json['dealer_amount_cents'] as num?)?.toInt() ?? 0,
      riderDeliveryFeeCents:
          (json['rider_delivery_fee_cents'] as num?)?.toInt() ?? 0,
      platformFeeCents: (json['platform_fee_cents'] as num?)?.toInt() ?? 0,
      stripeFeeCents: (json['stripe_fee_cents'] as num?)?.toInt() ?? 0,
      dealerTier: json['dealer_tier'] as String?,
      perOrderFeeApplied: json['per_order_fee_applied'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
