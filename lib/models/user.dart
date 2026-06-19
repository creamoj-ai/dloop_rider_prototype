class User {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? avatarUrl;
  final bool isOnline;
  final bool isActive;
  final double? currentLat;
  final double? currentLng;
  final DateTime? lastLocationUpdate;
  final double totalEarnings;
  final double rating;
  final int totalOrders;
  final String? referralCode;
  final String? referredBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.avatarUrl,
    required this.isOnline,
    required this.isActive,
    this.currentLat,
    this.currentLng,
    this.lastLocationUpdate,
    required this.totalEarnings,
    required this.rating,
    required this.totalOrders,
    this.referralCode,
    this.referredBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // Da JSON (Supabase → Flutter)
  // Supporta sia tabella 'riders' che vecchia 'users'
  factory User.fromJson(Map<String, dynamic> json) {
    // Parse name: riders ha 'name' (full), users aveva 'first_name'/'last_name'
    String? firstName = json['first_name'] as String?;
    String? lastName = json['last_name'] as String?;
    if (firstName == null && json['name'] != null) {
      final fullName = json['name'] as String;
      final parts = fullName.split(' ');
      firstName = parts.isNotEmpty ? parts[0] : null;
      lastName = parts.length > 1 ? parts.sublist(1).join(' ') : null;
    }

    return User(
      id: json['id'] as String,
      email: (json['email'] as String?) ?? '',
      firstName: firstName,
      lastName: lastName,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      // riders: status='online'/'offline', users: is_online bool
      isOnline: json['is_online'] as bool? ?? (json['status'] == 'online'),
      isActive: json['is_active'] as bool? ?? json['active'] as bool? ?? true,
      currentLat: json['current_lat'] != null ? (json['current_lat'] as num).toDouble() : null,
      currentLng: json['current_lng'] != null ? (json['current_lng'] as num).toDouble() : null,
      lastLocationUpdate: json['last_location_update'] != null
          ? DateTime.parse(json['last_location_update'] as String)
          : null,
      // riders: earnings_week, users: total_earnings
      totalEarnings: (json['total_earnings'] as num?)?.toDouble()
          ?? (json['earnings_week'] as num?)?.toDouble() ?? 0.0,
      // riders: reputation_score (0-100), users: rating (1-5)
      rating: (json['rating'] as num?)?.toDouble()
          ?? ((json['reputation_score'] as num?)?.toDouble() ?? 50.0) / 10.0,
      // riders: total_deliveries, users: total_orders
      totalOrders: json['total_orders'] as int?
          ?? json['total_deliveries'] as int? ?? 0,
      referralCode: json['referral_code'] as String?,
      referredBy: json['referred_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.parse(json['created_at'] as String),
    );
  }

  // A JSON (Flutter → Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'is_online': isOnline,
      'is_active': isActive,
      'current_lat': currentLat,
      'current_lng': currentLng,
      'last_location_update': lastLocationUpdate?.toIso8601String(),
      'total_earnings': totalEarnings,
      'rating': rating,
      'total_orders': totalOrders,
      'referral_code': referralCode,
      'referred_by': referredBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper: nome completo
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? email.split('@').first;
  }

  // Helper: iniziali
  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    return email[0].toUpperCase();
  }

  // CopyWith per aggiornamenti immutabili
  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
    bool? isOnline,
    bool? isActive,
    double? currentLat,
    double? currentLng,
    DateTime? lastLocationUpdate,
    double? totalEarnings,
    double? rating,
    int? totalOrders,
    String? referralCode,
    String? referredBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      isActive: isActive ?? this.isActive,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      rating: rating ?? this.rating,
      totalOrders: totalOrders ?? this.totalOrders,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
