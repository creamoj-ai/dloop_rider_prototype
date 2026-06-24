class RiderContact {
  final String id;
  final String riderId;
  final String name;
  final String contactType; // 'dealer' | 'client'
  final String status; // 'active' | 'potential' | 'vip'
  final String? phone;
  final String? email;
  final int totalOrders;
  final DateTime createdAt;
  final String? referralId; // FK to merchant_referrals

  const RiderContact({
    required this.id,
    required this.riderId,
    required this.name,
    required this.contactType,
    this.status = 'active',
    this.phone,
    this.email,
    this.totalOrders = 0,
    required this.createdAt,
    this.referralId,
  });

  bool get isDealer => contactType == 'dealer';
  bool get isClient => contactType == 'client';
  bool get isVip => status == 'vip';
  bool get isActive => status == 'active' || status == 'vip';
  bool get isPotential => status == 'potential';

  factory RiderContact.fromJson(Map<String, dynamic> json) => RiderContact(
        id: json['id']?.toString() ?? '',
        riderId: json['rider_id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        contactType: json['contact_type'] as String? ?? 'client',
        status: json['status'] as String? ?? 'active',
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        totalOrders: int.tryParse(json['total_orders']?.toString() ?? '0') ?? 0,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        referralId: json['referral_id'] as String?,
      );

  Map<String, dynamic> toInsertJson(String riderId) => {
        'rider_id': riderId,
        'name': name,
        'contact_type': contactType,
        'status': status,
        'phone': phone,
        'email': email,
        'total_orders': totalOrders,
      };
}
