class DealerPlatform {
  final String id;
  final String riderId;
  final String? contactId;
  final String platformType;
  final String platformName;
  final String? webhookUrl;
  final String? apiKey;
  final String? scrapeUrl;
  final Map<String, dynamic> config;
  final bool isActive;
  final DateTime? lastSyncAt;
  final DateTime createdAt;

  const DealerPlatform({
    required this.id,
    this.riderId = '',
    this.contactId,
    required this.platformType,
    required this.platformName,
    this.webhookUrl,
    this.apiKey,
    this.scrapeUrl,
    this.config = const {},
    this.isActive = true,
    this.lastSyncAt,
    required this.createdAt,
  });

  bool get hasWebhook => webhookUrl != null && webhookUrl!.isNotEmpty;
  bool get hasScrapeUrl => scrapeUrl != null && scrapeUrl!.isNotEmpty;

  String get platformIcon {
    switch (platformType) {
      case 'website':
        return 'web';
      case 'whatsapp':
        return 'whatsapp';
      case 'justeat':
      case 'deliveroo':
      case 'glovo':
      case 'ubereats':
        return 'platform';
      default:
        return 'custom';
    }
  }

  factory DealerPlatform.fromJson(Map<String, dynamic> json) {
    return DealerPlatform(
      id: json['id']?.toString() ?? '',
      riderId: json['rider_id']?.toString() ?? '',
      contactId: json['contact_id']?.toString(),
      platformType: json['platform_type'] as String? ?? 'custom',
      platformName: json['platform_name'] as String? ?? '',
      webhookUrl: json['webhook_url'] as String?,
      apiKey: json['api_key'] as String?,
      scrapeUrl: json['scrape_url'] as String?,
      config: json['config'] is Map<String, dynamic>
          ? json['config'] as Map<String, dynamic>
          : const {},
      isActive: json['is_active'] as bool? ?? true,
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.tryParse(json['last_sync_at'].toString())
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
