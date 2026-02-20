/// Dealer subscription tier and billing info.
class DealerSubscription {
  final String id;
  final String dealerContactId;
  final String riderId;
  final String tier;
  final int monthlyFeeCents;
  final double commissionRate;
  final int perOrderFeeCents;
  final DateTime startedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final String? stripeSubscriptionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DealerSubscription({
    required this.id,
    required this.dealerContactId,
    required this.riderId,
    this.tier = 'starter',
    this.monthlyFeeCents = 0,
    this.commissionRate = 0.0,
    this.perOrderFeeCents = 50,
    required this.startedAt,
    this.expiresAt,
    this.isActive = true,
    this.stripeSubscriptionId,
    required this.createdAt,
    required this.updatedAt,
  });

  double get monthlyFeeEur => monthlyFeeCents / 100.0;
  double get perOrderFeeEur => perOrderFeeCents / 100.0;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  String get tierLabel {
    switch (tier) {
      case 'starter':
        return 'Starter';
      case 'pro':
        return 'Pro';
      case 'business':
        return 'Business';
      case 'enterprise':
        return 'Enterprise';
      default:
        return tier;
    }
  }

  /// Tier configuration defaults.
  static const Map<String, TierConfig> tierConfigs = {
    'starter': TierConfig(
        monthlyFeeCents: 0, perOrderFeeCents: 50, commissionRate: 0.0),
    'pro': TierConfig(
        monthlyFeeCents: 4900, perOrderFeeCents: 0, commissionRate: 0.0),
    'business': TierConfig(
        monthlyFeeCents: 7900, perOrderFeeCents: 0, commissionRate: 0.0),
    'enterprise': TierConfig(
        monthlyFeeCents: 14900, perOrderFeeCents: 0, commissionRate: 0.0),
  };

  factory DealerSubscription.fromJson(Map<String, dynamic> json) {
    return DealerSubscription(
      id: json['id']?.toString() ?? '',
      dealerContactId: json['dealer_contact_id']?.toString() ?? '',
      riderId: json['rider_id']?.toString() ?? '',
      tier: json['tier'] as String? ?? 'starter',
      monthlyFeeCents: (json['monthly_fee_cents'] as num?)?.toInt() ?? 0,
      commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 0.0,
      perOrderFeeCents: (json['per_order_fee_cents'] as num?)?.toInt() ?? 50,
      startedAt: DateTime.tryParse(json['started_at']?.toString() ?? '') ??
          DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      isActive: json['is_active'] as bool? ?? true,
      stripeSubscriptionId: json['stripe_subscription_id'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dealer_contact_id': dealerContactId,
        'rider_id': riderId,
        'tier': tier,
        'monthly_fee_cents': monthlyFeeCents,
        'commission_rate': commissionRate,
        'per_order_fee_cents': perOrderFeeCents,
        'started_at': startedAt.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'is_active': isActive,
        'stripe_subscription_id': stripeSubscriptionId,
      };
}

/// Static tier configuration.
class TierConfig {
  final int monthlyFeeCents;
  final int perOrderFeeCents;
  final double commissionRate;

  const TierConfig({
    required this.monthlyFeeCents,
    required this.perOrderFeeCents,
    required this.commissionRate,
  });

  double get monthlyFeeEur => monthlyFeeCents / 100.0;
  double get perOrderFeeEur => perOrderFeeCents / 100.0;
}
