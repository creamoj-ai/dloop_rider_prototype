import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../utils/retry.dart';

class SupportChatService {
  static final _client = Supabase.instance.client;

  static String? get _riderId => _client.auth.currentUser?.id;

  /// Get all conversations for the current rider
  static Future<List<SupportConversation>> getConversations() async {
    final riderId = _riderId;
    if (riderId == null) return [];

    return retry(() async {
      final response = await _client
          .from('support_conversations')
          .select()
          .eq('rider_id', riderId)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => SupportConversation.fromJson(json))
          .toList();
    }, onRetry: (attempt, e) {
      print('⚡ SupportChatService.getConversations retry $attempt: $e');
    });
  }

  /// Get existing open conversation or create a new one
  static Future<SupportConversation> getOrCreateConversation({
    String subject = 'Supporto',
  }) async {
    final riderId = _riderId;
    if (riderId == null) throw Exception('Not authenticated');

    return retry(() async {
      // Check for existing open conversation
      final existing = await _client
          .from('support_conversations')
          .select()
          .eq('rider_id', riderId)
          .eq('status', 'open')
          .order('updated_at', ascending: false)
          .limit(1);

      if ((existing as List).isNotEmpty) {
        return SupportConversation.fromJson(existing.first);
      }

      // Create new conversation
      final response = await _client
          .from('support_conversations')
          .insert({
            'rider_id': riderId,
            'subject': subject,
          })
          .select()
          .single();

      return SupportConversation.fromJson(response);
    }, onRetry: (attempt, e) {
      print('⚡ SupportChatService.getOrCreateConversation retry $attempt: $e');
    });
  }

  /// Get messages for a conversation
  static Future<List<ChatMessage>> getMessages(String conversationId) async {
    return retry(() async {
      final response = await _client
          .from('support_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();
    }, onRetry: (attempt, e) {
      print('⚡ SupportChatService.getMessages retry $attempt: $e');
    });
  }

  /// Send a message
  static Future<ChatMessage> sendMessage(String conversationId, String body) async {
    final riderId = _riderId;
    if (riderId == null) throw Exception('Not authenticated');

    return retry(() async {
      final response = await _client
          .from('support_messages')
          .insert({
            'conversation_id': conversationId,
            'sender_type': 'rider',
            'sender_id': riderId,
            'body': body,
          })
          .select()
          .single();

      // Update conversation timestamp
      await _client
          .from('support_conversations')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', conversationId);

      return ChatMessage.fromJson(response);
    }, onRetry: (attempt, e) {
      print('⚡ SupportChatService.sendMessage retry $attempt: $e');
    });
  }

  /// Mark all messages in a conversation as read (for messages from support/system)
  static Future<void> markMessagesAsRead(String conversationId) async {
    try {
      await _client
          .from('support_messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_type', 'rider')
          .eq('is_read', false);
    } catch (e) {
      print('❌ SupportChatService.markMessagesAsRead failed: $e');
    }
  }

  /// Subscribe to real-time messages for a conversation (with auto-reconnect)
  static Stream<List<ChatMessage>> subscribeToMessages(String conversationId) {
    return retryStream(
      () => _client
          .from('support_messages')
          .stream(primaryKey: ['id'])
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .map((data) => data.map((json) => ChatMessage.fromJson(json)).toList()),
      onReconnect: (attempt, e) {
        print('⚡ SupportChatService.subscribeToMessages reconnect $attempt: $e');
      },
    );
  }

  /// Get total unread count across all conversations
  static Future<int> getTotalUnreadCount() async {
    final riderId = _riderId;
    if (riderId == null) return 0;

    try {
      // Get all rider's conversations
      final conversations = await _client
          .from('support_conversations')
          .select('id')
          .eq('rider_id', riderId);

      if ((conversations as List).isEmpty) return 0;

      final conversationIds = conversations.map((c) => c['id'] as String).toList();

      // Count unread messages from support/system
      final unread = await _client
          .from('support_messages')
          .select('id')
          .inFilter('conversation_id', conversationIds)
          .neq('sender_type', 'rider')
          .eq('is_read', false);

      return (unread as List).length;
    } catch (e) {
      return 0;
    }
  }
}
