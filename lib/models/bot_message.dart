class BotMessage {
  final String id;
  final String riderId;
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  final int tokensUsed;
  final String model;
  final DateTime createdAt;

  const BotMessage({
    required this.id,
    required this.riderId,
    required this.role,
    required this.content,
    this.tokensUsed = 0,
    this.model = 'gpt-4o-mini',
    required this.createdAt,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory BotMessage.fromJson(Map<String, dynamic> json) => BotMessage(
        id: json['id']?.toString() ?? '',
        riderId: json['rider_id']?.toString() ?? '',
        role: json['role'] as String? ?? 'user',
        content: json['content'] as String? ?? '',
        tokensUsed: int.tryParse(json['tokens_used']?.toString() ?? '0') ?? 0,
        model: json['model'] as String? ?? 'gpt-4o-mini',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      );

  /// For OpenAI API messages array
  Map<String, String> toOpenAiMessage() => {
        'role': role,
        'content': content,
      };
}
