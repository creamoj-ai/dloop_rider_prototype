import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bot_message.dart';
import '../utils/retry.dart';

class ChatBotService {
  static final _client = Supabase.instance.client;
  static const _model = 'gpt-4o-mini';
  static const _maxTokens = 256;
  static const _temperature = 0.7;
  static const _historyLimit = 20;

  static String? get _riderId => _client.auth.currentUser?.id;

  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

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
      print('⚡ ChatBotService.getHistory retry $attempt: $e');
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
        print('⚡ ChatBotService.subscribeToMessages reconnect $attempt: $e');
      },
    );
  }

  /// Send a user message and get an AI response
  ///
  /// 1. Saves user message to DB (appears immediately via real-time)
  /// 2. Calls OpenAI API with history + system prompt
  /// 3. Saves assistant response to DB (appears via real-time)
  static Future<void> sendMessage({
    required String text,
    required String systemPrompt,
  }) async {
    final riderId = _riderId;
    if (riderId == null) throw Exception('Not authenticated');

    // 1. Save user message to DB
    await retry(() async {
      await _client.from('bot_messages').insert({
        'rider_id': riderId,
        'role': 'user',
        'content': text,
      });
    });

    // 2. Fetch recent history for context
    final history = await retry(() async {
      final response = await _client
          .from('bot_messages')
          .select()
          .eq('rider_id', riderId)
          .order('created_at', ascending: false)
          .limit(_historyLimit);

      return (response as List)
          .map((json) => BotMessage.fromJson(json))
          .toList()
          .reversed
          .toList();
    });

    // 3. Build messages array for OpenAI
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...history.map((m) => m.toOpenAiMessage()),
    ];

    // 4. Call OpenAI API
    final apiResponse = await retry(() async {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': _maxTokens,
          'temperature': _temperature,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('OpenAI API error ${response.statusCode}: ${response.body}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    }, onRetry: (attempt, e) {
      print('⚡ ChatBotService.sendMessage OpenAI retry $attempt: $e');
    });

    // 5. Extract response
    final choices = apiResponse['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('No response from OpenAI');
    }

    final assistantContent =
        choices[0]['message']['content'] as String? ?? '';
    final usage = apiResponse['usage'] as Map<String, dynamic>?;
    final totalTokens = usage?['total_tokens'] as int? ?? 0;

    // 6. Save assistant response to DB
    await retry(() async {
      await _client.from('bot_messages').insert({
        'rider_id': riderId,
        'role': 'assistant',
        'content': assistantContent.trim(),
        'tokens_used': totalTokens,
        'model': _model,
      });
    });
  }

  /// Build a personalized system prompt with rider context
  static String buildSystemPrompt({
    required String riderName,
    double todayEarnings = 0,
    int todayOrders = 0,
    int streak = 0,
    double rating = 0,
    int level = 1,
    double lifetimeEarnings = 0,
    int lifetimeOrders = 0,
  }) {
    return '''Sei l'assistente AI di dloop, la piattaforma di delivery.
Parli in italiano, in modo amichevole e motivante.
Rispondi in massimo 2-3 frasi, brevi e dirette.

Il rider si chiama $riderName.
Dati di oggi: €${todayEarnings.toStringAsFixed(2)} guadagnati, $todayOrders ordini completati.
Statistiche: streak $streak giorni, rating ${rating.toStringAsFixed(1)}⭐, livello $level.
Totale carriera: €${lifetimeEarnings.toStringAsFixed(0)}, $lifetimeOrders ordini.

Puoi aiutare con:
- Consigli su come guadagnare di più (ore di punta, zone calde)
- Spiegare il sistema di livelli, XP e badge
- FAQ su guadagni, commissioni, bonus rete, mance
- Motivazione e obiettivi giornalieri
- Come funziona il costo di hold e le zone calde
- Consigli per migliorare il rating

Se non sai qualcosa, suggerisci di contattare il supporto umano.
Non inventare dati o numeri che non conosci.''';
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
      print('⚡ ChatBotService.clearHistory retry $attempt: $e');
    });
  }
}
