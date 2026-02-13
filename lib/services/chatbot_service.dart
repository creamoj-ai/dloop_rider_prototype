import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bot_message.dart';
import '../utils/logger.dart';
import '../utils/retry.dart';

class ChatBotService {
  static final _client = Supabase.instance.client;

  static String? get _riderId => _client.auth.currentUser?.id;

  static String get _supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  /// Fetch message history from DB
  static Future<List<BotMessage>> getHistory() async {
    final riderId = _riderId;
    if (riderId == null) return [];

    return retry(() async {
      final response = await _client
          .from('bot_messages')
          .select()
          .eq('rider_id', riderId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => BotMessage.fromJson(json))
          .toList();
    }, onRetry: (attempt, e) {
      dlog('⚡ ChatBotService.getHistory retry $attempt: $e');
    });
  }

  /// Real-time stream of messages (auto-reconnect)
  static Stream<List<BotMessage>> subscribeToMessages() {
    final riderId = _riderId;
    if (riderId == null) return Stream.value([]);

    return retryStream(
      () => _client
          .from('bot_messages')
          .stream(primaryKey: ['id'])
          .eq('rider_id', riderId)
          .order('created_at', ascending: true)
          .map((data) => data.map((json) => BotMessage.fromJson(json)).toList()),
      onReconnect: (attempt, e) {
        dlog('⚡ ChatBotService.subscribeToMessages reconnect $attempt: $e');
      },
    );
  }

  /// Send a user message via the chat-bot Edge Function.
  ///
  /// The Edge Function handles:
  /// - Saving user message to DB
  /// - Fetching rider context (stats, earnings, orders)
  /// - OpenAI call with function calling (9 tools)
  /// - Saving assistant response to DB
  ///
  /// Messages appear via real-time subscription (no need to return content).
  static Future<void> sendMessage({required String text}) async {
    final session = _client.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    await retry(() async {
      final response = await http.post(
        Uri.parse('$_supabaseUrl/functions/v1/chat-bot'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({'text': text.trim()}),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Chat bot error ${response.statusCode}: ${response.body}');
      }
    }, onRetry: (attempt, e) {
      dlog('⚡ ChatBotService.sendMessage retry $attempt: $e');
    });
  }

  /// Clear all bot messages for the current rider
  static Future<void> clearHistory() async {
    final riderId = _riderId;
    if (riderId == null) return;

    await retry(() async {
      await _client
          .from('bot_messages')
          .delete()
          .eq('rider_id', riderId);
    }, onRetry: (attempt, e) {
      dlog('⚡ ChatBotService.clearHistory retry $attempt: $e');
    });
  }
}
