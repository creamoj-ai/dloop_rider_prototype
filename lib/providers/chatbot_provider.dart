import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bot_message.dart';
import '../services/chatbot_service.dart';
import 'earnings_provider.dart';
import 'rider_stats_provider.dart';
import 'user_provider.dart';

/// State for the chatbot screen
class ChatBotState {
  final List<BotMessage> messages;
  final bool isLoading;
  final bool isTyping;
  final String? errorMessage;

  const ChatBotState({
    this.messages = const [],
    this.isLoading = true,
    this.isTyping = false,
    this.errorMessage,
  });

  ChatBotState copyWith({
    List<BotMessage>? messages,
    bool? isLoading,
    bool? isTyping,
    String? errorMessage,
  }) =>
      ChatBotState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        isTyping: isTyping ?? this.isTyping,
        errorMessage: errorMessage,
      );
}

class ChatBotNotifier extends StateNotifier<ChatBotState> {
  final Ref _ref;
  StreamSubscription<List<BotMessage>>? _subscription;

  ChatBotNotifier(this._ref) : super(const ChatBotState()) {
    _initialize();
  }

  void _initialize() {
    _subscription = ChatBotService.subscribeToMessages().listen(
      (messages) {
        state = state.copyWith(
          messages: messages,
          isLoading: false,
        );
      },
      onError: (e) {
        print('❌ ChatBotNotifier stream error: $e');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Errore di connessione',
        );
      },
    );
  }

  /// Send a message to the AI bot
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    state = state.copyWith(isTyping: true, errorMessage: null);

    try {
      // Build system prompt with live rider data
      final systemPrompt = _buildSystemPrompt();

      await ChatBotService.sendMessage(
        text: text.trim(),
        systemPrompt: systemPrompt,
      );

      state = state.copyWith(isTyping: false);
    } catch (e) {
      print('❌ ChatBotNotifier.sendMessage failed: $e');
      state = state.copyWith(
        isTyping: false,
        errorMessage: 'Errore nell\'invio del messaggio. Riprova.',
      );
    }
  }

  /// Build system prompt from live providers
  String _buildSystemPrompt() {
    // Get rider name
    String riderName = 'Rider';
    try {
      final userAsync = _ref.read(currentUserProvider);
      final user = userAsync.valueOrNull;
      if (user != null && user.firstName != null && user.firstName!.isNotEmpty) {
        riderName = user.firstName!;
      }
    } catch (_) {}

    // Get today's earnings
    double todayEarnings = 0;
    int todayOrders = 0;
    try {
      final earnings = _ref.read(earningsProvider);
      todayEarnings = earnings.todayTotal;
      todayOrders = earnings.ordersCount;
    } catch (_) {}

    // Get rider stats
    int streak = 0;
    double rating = 0;
    int level = 1;
    double lifetimeEarnings = 0;
    int lifetimeOrders = 0;
    try {
      final statsAsync = _ref.read(riderStatsProvider);
      final stats = statsAsync.valueOrNull;
      if (stats != null) {
        streak = stats.currentDailyStreak;
        rating = stats.avgRating;
        level = stats.currentLevel;
        lifetimeEarnings = stats.lifetimeEarnings;
        lifetimeOrders = stats.lifetimeOrders;
      }
    } catch (_) {}

    return ChatBotService.buildSystemPrompt(
      riderName: riderName,
      todayEarnings: todayEarnings,
      todayOrders: todayOrders,
      streak: streak,
      rating: rating,
      level: level,
      lifetimeEarnings: lifetimeEarnings,
      lifetimeOrders: lifetimeOrders,
    );
  }

  /// Clear conversation history
  Future<void> clearHistory() async {
    try {
      await ChatBotService.clearHistory();
    } catch (e) {
      print('❌ ChatBotNotifier.clearHistory failed: $e');
      state = state.copyWith(
        errorMessage: 'Errore nella cancellazione. Riprova.',
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final chatBotProvider =
    StateNotifierProvider<ChatBotNotifier, ChatBotState>((ref) {
  return ChatBotNotifier(ref);
});
