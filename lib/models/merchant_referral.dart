/// Merchant Referral System
///
/// Modello SaaS puro: rider segnala dealer, riceve bonus FISSO una tantum
/// dopo attivazione (NO legame con fatturato dealer).

/// Stato del referral merchant
enum MerchantReferralStatus {
  pending,   // Segnalato, dealer non ha ancora fatto ordini
  active,    // Dealer ha fatto primo ordine, soglia in progresso
  completed, // Soglia raggiunta, bonus erogato
  expired,   // Scaduto (oltre expires_at)
  cancelled, // Annullato dal rider
}

/// Tipo di soglia di attivazione
enum ActivationThresholdType {
  firstOrders, // Primi N ordini (default)
  timeBased,   // Tempo (es. 30 giorni attivo)
  manual,      // Attivazione manuale admin
}

/// Merchant Referral: rider segnala dealer, riceve bonus fisso
class MerchantReferral {
  final String id;
  final String referrerRiderId;
  final String? dealerContactId; // FK a rider_contacts
  final String dealerName;
  final String? dealerPhone;
  final String? dealerEmail;
  final MerchantReferralStatus status;
  final ActivationThresholdType thresholdType;
  final int thresholdValue; // es. 10 ordini
  final int bonusAmountCents;
  final int currentOrderCount;
  final DateTime createdAt;
  final DateTime? activatedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final DateTime? cancelledAt;
  final DateTime? bonusPaidAt;
  final String? bonusTransactionId;
  final String? notes;

  const MerchantReferral({
    required this.id,
    required this.referrerRiderId,
    this.dealerContactId,
    required this.dealerName,
    this.dealerPhone,
    this.dealerEmail,
    required this.status,
    this.thresholdType = ActivationThresholdType.firstOrders,
    this.thresholdValue = 10,
    this.bonusAmountCents = 5000, // €50 default
    this.currentOrderCount = 0,
    required this.createdAt,
    this.activatedAt,
    this.completedAt,
    this.expiresAt,
    this.cancelledAt,
    this.bonusPaidAt,
    this.bonusTransactionId,
    this.notes,
  });

  // ============================================================
  // COMPUTED PROPERTIES
  // ============================================================

  /// Bonus in euro
  double get bonusEur => bonusAmountCents / 100.0;

  /// Progress percentage (0-100)
  double get progressPercent {
    if (thresholdValue == 0) return 0;
    return (currentOrderCount / thresholdValue * 100).clamp(0, 100);
  }

  /// Remaining orders to complete
  int get remainingOrders =>
      (thresholdValue - currentOrderCount).clamp(0, thresholdValue);

  /// Is referral pending?
  bool get isPending => status == MerchantReferralStatus.pending;

  /// Is referral active?
  bool get isActive => status == MerchantReferralStatus.active;

  /// Is referral completed?
  bool get isCompleted => status == MerchantReferralStatus.completed;

  /// Is referral expired?
  bool get isExpired => status == MerchantReferralStatus.expired;

  /// Is referral cancelled?
  bool get isCancelled => status == MerchantReferralStatus.cancelled;

  /// Can be cancelled? (only pending/active)
  bool get canBeCancelled => isPending || isActive;

  /// Days until expiry (null if no expiry or already expired)
  int? get daysUntilExpiry {
    if (expiresAt == null) return null;
    if (isExpired || isCompleted || isCancelled) return null;
    final now = DateTime.now();
    if (expiresAt!.isBefore(now)) return 0;
    return expiresAt!.difference(now).inDays;
  }

  /// Status label in Italian
  String get statusLabel {
    switch (status) {
      case MerchantReferralStatus.pending:
        return 'In attesa';
      case MerchantReferralStatus.active:
        return 'Attivo';
      case MerchantReferralStatus.completed:
        return 'Completato';
      case MerchantReferralStatus.expired:
        return 'Scaduto';
      case MerchantReferralStatus.cancelled:
        return 'Annullato';
    }
  }

  /// Progress label (es. "7/10 ordini")
  String get progressLabel => '$currentOrderCount/$thresholdValue ordini';

  // ============================================================
  // JSON SERIALIZATION
  // ============================================================

  factory MerchantReferral.fromJson(Map<String, dynamic> json) {
    return MerchantReferral(
      id: json['id'] as String,
      referrerRiderId: json['referrer_rider_id'] as String,
      dealerContactId: json['dealer_contact_id'] as String?,
      dealerName: json['dealer_name'] as String,
      dealerPhone: json['dealer_phone'] as String?,
      dealerEmail: json['dealer_email'] as String?,
      status: _statusFromString(json['status'] as String),
      thresholdType: _thresholdTypeFromString(
        json['activation_threshold_type'] as String? ?? 'first_orders',
      ),
      thresholdValue: json['activation_threshold_value'] as int? ?? 10,
      bonusAmountCents: json['bonus_amount_cents'] as int? ?? 5000,
      currentOrderCount: json['current_order_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      activatedAt: json['activated_at'] != null
          ? DateTime.parse(json['activated_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      bonusPaidAt: json['bonus_paid_at'] != null
          ? DateTime.parse(json['bonus_paid_at'] as String)
          : null,
      bonusTransactionId: json['bonus_transaction_id'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referrer_rider_id': referrerRiderId,
      'dealer_contact_id': dealerContactId,
      'dealer_name': dealerName,
      'dealer_phone': dealerPhone,
      'dealer_email': dealerEmail,
      'status': _statusToString(status),
      'activation_threshold_type': _thresholdTypeToString(thresholdType),
      'activation_threshold_value': thresholdValue,
      'bonus_amount_cents': bonusAmountCents,
      'current_order_count': currentOrderCount,
      'created_at': createdAt.toIso8601String(),
      'activated_at': activatedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'bonus_paid_at': bonusPaidAt?.toIso8601String(),
      'bonus_transaction_id': bonusTransactionId,
      'notes': notes,
    };
  }

  /// For INSERT (exclude id, timestamps auto-set by DB)
  Map<String, dynamic> toInsertJson() {
    return {
      'referrer_rider_id': referrerRiderId,
      'dealer_contact_id': dealerContactId,
      'dealer_name': dealerName,
      'dealer_phone': dealerPhone,
      'dealer_email': dealerEmail,
      'activation_threshold_type': _thresholdTypeToString(thresholdType),
      'activation_threshold_value': thresholdValue,
      'bonus_amount_cents': bonusAmountCents,
      'notes': notes,
    };
  }

  // ============================================================
  // ENUM CONVERTERS
  // ============================================================

  static MerchantReferralStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return MerchantReferralStatus.pending;
      case 'active':
        return MerchantReferralStatus.active;
      case 'completed':
        return MerchantReferralStatus.completed;
      case 'expired':
        return MerchantReferralStatus.expired;
      case 'cancelled':
        return MerchantReferralStatus.cancelled;
      default:
        return MerchantReferralStatus.pending;
    }
  }

  static String _statusToString(MerchantReferralStatus status) {
    switch (status) {
      case MerchantReferralStatus.pending:
        return 'pending';
      case MerchantReferralStatus.active:
        return 'active';
      case MerchantReferralStatus.completed:
        return 'completed';
      case MerchantReferralStatus.expired:
        return 'expired';
      case MerchantReferralStatus.cancelled:
        return 'cancelled';
    }
  }

  static ActivationThresholdType _thresholdTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'first_orders':
        return ActivationThresholdType.firstOrders;
      case 'time_based':
        return ActivationThresholdType.timeBased;
      case 'manual':
        return ActivationThresholdType.manual;
      default:
        return ActivationThresholdType.firstOrders;
    }
  }

  static String _thresholdTypeToString(ActivationThresholdType type) {
    switch (type) {
      case ActivationThresholdType.firstOrders:
        return 'first_orders';
      case ActivationThresholdType.timeBased:
        return 'time_based';
      case ActivationThresholdType.manual:
        return 'manual';
    }
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  MerchantReferral copyWith({
    String? id,
    String? referrerRiderId,
    String? dealerContactId,
    String? dealerName,
    String? dealerPhone,
    String? dealerEmail,
    MerchantReferralStatus? status,
    ActivationThresholdType? thresholdType,
    int? thresholdValue,
    int? bonusAmountCents,
    int? currentOrderCount,
    DateTime? createdAt,
    DateTime? activatedAt,
    DateTime? completedAt,
    DateTime? expiresAt,
    DateTime? cancelledAt,
    DateTime? bonusPaidAt,
    String? bonusTransactionId,
    String? notes,
  }) {
    return MerchantReferral(
      id: id ?? this.id,
      referrerRiderId: referrerRiderId ?? this.referrerRiderId,
      dealerContactId: dealerContactId ?? this.dealerContactId,
      dealerName: dealerName ?? this.dealerName,
      dealerPhone: dealerPhone ?? this.dealerPhone,
      dealerEmail: dealerEmail ?? this.dealerEmail,
      status: status ?? this.status,
      thresholdType: thresholdType ?? this.thresholdType,
      thresholdValue: thresholdValue ?? this.thresholdValue,
      bonusAmountCents: bonusAmountCents ?? this.bonusAmountCents,
      currentOrderCount: currentOrderCount ?? this.currentOrderCount,
      createdAt: createdAt ?? this.createdAt,
      activatedAt: activatedAt ?? this.activatedAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      bonusPaidAt: bonusPaidAt ?? this.bonusPaidAt,
      bonusTransactionId: bonusTransactionId ?? this.bonusTransactionId,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'MerchantReferral(id: $id, dealer: $dealerName, status: ${statusLabel}, progress: $progressLabel, bonus: €${bonusEur.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MerchantReferral && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
