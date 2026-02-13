class PartnerOffer {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String description;
  final String shortDescription;
  final String referralBaseUrl;
  final String commissionType; // 'percentage', 'flat_per_lead', 'recurring'
  final double? commissionValue;
  final List<String> targetAudience; // ['rider', 'dealer', 'both']
  final String category; // 'insurance', 'finance', 'telecom', 'tools', 'mobility'
  final int phase;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  PartnerOffer({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    required this.description,
    required this.shortDescription,
    required this.referralBaseUrl,
    required this.commissionType,
    this.commissionValue,
    this.targetAudience = const [],
    required this.category,
    this.phase = 1,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory PartnerOffer.fromJson(Map<String, dynamic> json) {
    return PartnerOffer(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      logoUrl: json['logo_url'] as String?,
      description: json['description'] as String,
      shortDescription: json['short_description'] as String,
      referralBaseUrl: json['referral_base_url'] as String,
      commissionType: json['commission_type'] as String? ?? 'flat_per_lead',
      commissionValue: (json['commission_value'] as num?)?.toDouble(),
      targetAudience: json['target_audience'] != null
          ? List<String>.from(json['target_audience'] as List)
          : [],
      category: json['category'] as String,
      phase: json['phase'] as int? ?? 1,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'logo_url': logoUrl,
      'description': description,
      'short_description': shortDescription,
      'referral_base_url': referralBaseUrl,
      'commission_type': commissionType,
      'commission_value': commissionValue,
      'target_audience': targetAudience,
      'category': category,
      'phase': phase,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  String referralUrl(String userId) {
    final separator = referralBaseUrl.contains('?') ? '&' : '?';
    return '$referralBaseUrl${separator}ref=dloop_$userId';
  }
}
