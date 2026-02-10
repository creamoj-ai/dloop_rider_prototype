enum SenderType { rider, support, system }

class ChatMessage {
  final String id;
  final String conversationId;
  final SenderType senderType;
  final String? senderId;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderType,
    this.senderId,
    required this.body,
    this.isRead = false,
    required this.createdAt,
  });

  bool get isFromRider => senderType == SenderType.rider;
  bool get isFromSupport => senderType == SenderType.support;
  bool get isSystemMessage => senderType == SenderType.system;

  Map<String, dynamic> toJson() => {
    'conversation_id': conversationId,
    'sender_type': senderType.name,
    'sender_id': senderId,
    'body': body,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id']?.toString() ?? '',
    conversationId: json['conversation_id']?.toString() ?? '',
    senderType: SenderType.values.firstWhere(
      (s) => s.name == json['sender_type'],
      orElse: () => SenderType.system,
    ),
    senderId: json['sender_id'] as String?,
    body: json['body'] as String? ?? '',
    isRead: json['is_read'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}

class SupportConversation {
  final String id;
  final String riderId;
  final String subject;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ChatMessage? lastMessage;
  final int unreadCount;

  const SupportConversation({
    required this.id,
    required this.riderId,
    this.subject = 'Supporto',
    this.status = 'open',
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
  });

  bool get isOpen => status == 'open';

  Map<String, dynamic> toJson() => {
    'rider_id': riderId,
    'subject': subject,
    'status': status,
  };

  factory SupportConversation.fromJson(Map<String, dynamic> json) => SupportConversation(
    id: json['id']?.toString() ?? '',
    riderId: json['rider_id']?.toString() ?? '',
    subject: json['subject'] as String? ?? 'Supporto',
    status: json['status'] as String? ?? 'open',
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
  );
}
