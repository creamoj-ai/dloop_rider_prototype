import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/retry.dart';

class Referral {
  final String id;
  final String referredName;
  final String? referredEmail;
  final String status; // pending, active, expired
  final double bonusAmount;
  final DateTime createdAt;
  final DateTime? activatedAt;

  Referral({
    required this.id,
    required this.referredName,
    this.referredEmail,
    required this.status,
    required this.bonusAmount,
    required this.createdAt,
    this.activatedAt,
  });

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['id'] as String,
      referredName: json['referred_name'] as String? ?? 'Sconosciuto',
      referredEmail: json['referred_email'] as String?,
      status: json['status'] as String? ?? 'pending',
      bonusAmount: (json['bonus_amount'] is num)
          ? (json['bonus_amount'] as num).toDouble()
          : double.tryParse(json['bonus_amount']?.toString() ?? '10') ?? 10.0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      activatedAt: json['activated_at'] != null
          ? DateTime.tryParse(json['activated_at'].toString())
          : null,
    );
  }
}

class ReferralService {
  static final _client = Supabase.instance.client;

  /// Get all referrals for current rider
  static Future<List<Referral>> getReferrals() async {
    return retry(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final data = await _client
          .from('referrals')
          .select()
          .eq('referrer_id', userId)
          .order('created_at', ascending: false);

      return (data as List).map((r) => Referral.fromJson(r)).toList();
    });
  }

  /// Subscribe to referrals stream
  static Stream<List<Referral>> subscribeToReferrals() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _client
        .from('referrals')
        .stream(primaryKey: ['id'])
        .eq('referrer_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => Referral.fromJson(r)).toList());
  }

  /// Generate referral code from user data
  static String generateReferralCode(String? firstName, String? lastName, String? userId) {
    final name = (lastName ?? firstName ?? 'DLOOP').toUpperCase().replaceAll(' ', '');
    final prefix = name.length >= 4 ? name.substring(0, 4) : name.padRight(4, 'X');
    final suffix = (userId ?? '0000').replaceAll('-', '').substring(0, 4).toUpperCase();
    return '$prefix$suffix';
  }
}
