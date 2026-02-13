import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bot_message.dart';
import '../services/chatbot_service.dart';
import '../utils/logger.dart';

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
  StreamSubscription<List<BotMessage>>? _subscription;

  ChatBotNotifier() : super(const ChatBotState()) {
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
        dlog('❌ ChatBotNotifier stream error: $e');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Errore di connessione',
        );
      },
    );
  }

  /// Send a message to the AI bot via Edge Function.
  /// Context (rider stats, earnings, etc.) is fetched server-side.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    state = state.copyWith(isTyping: true, errorMessage: null);

    try {
      await ChatBotService.sendMessage(text: text.trim());
      state = state.copyWith(isTyping: false);
    } catch (e) {
      dlog('❌ ChatBotNotifier.sendMessage failed: $e');
      state = state.copyWith(
        isTyping: false,
        errorMessage: 'Errore nell\'invio del messaggio. Riprova.',
      );
    }
  }

  /// Clear conversation history
  Future<void> clearHistory() async {
    try {
      await ChatBotService.clearHistory();
    } catch (e) {
      dlog('❌ ChatBotNotifier.clearHistory failed: $e');
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
  return ChatBotNotifier();
});
