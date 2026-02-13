import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/support_chat_service.dart';
import '../utils/logger.dart';

class SupportChatState {
  final SupportConversation? activeConversation;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final int totalUnreadCount;

  const SupportChatState({
    this.activeConversation,
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.totalUnreadCount = 0,
  });

  SupportChatState copyWith({
    SupportConversation? activeConversation,
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    int? totalUnreadCount,
  }) => SupportChatState(
    activeConversation: activeConversation ?? this.activeConversation,
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    isSending: isSending ?? this.isSending,
    totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
  );
}

class SupportChatNotifier extends StateNotifier<SupportChatState> {
  StreamSubscription<List<ChatMessage>>? _messagesSub;

  SupportChatNotifier() : super(const SupportChatState());

  /// Open or create a support conversation and subscribe to messages
  Future<void> openOrCreateConversation() async {
    state = state.copyWith(isLoading: true);

    try {
      final conversation = await SupportChatService.getOrCreateConversation();
      state = state.copyWith(
        activeConversation: conversation,
        isLoading: false,
      );

      _subscribeToMessages(conversation.id);
      await SupportChatService.markMessagesAsRead(conversation.id);
    } catch (e) {
      dlog('❌ SupportChatNotifier.openOrCreateConversation failed: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void _subscribeToMessages(String conversationId) {
    _messagesSub?.cancel();
    _messagesSub = SupportChatService.subscribeToMessages(conversationId).listen(
      (messages) {
        state = state.copyWith(messages: messages);
      },
      onError: (e) {
        dlog('❌ SupportChatNotifier messages stream error: $e');
      },
    );
  }

  /// Send a message in the active conversation
  Future<void> sendMessage(String body) async {
    final conversation = state.activeConversation;
    if (conversation == null || body.trim().isEmpty) return;

    state = state.copyWith(isSending: true);

    try {
      await SupportChatService.sendMessage(conversation.id, body.trim());
      state = state.copyWith(isSending: false);
    } catch (e) {
      dlog('❌ SupportChatNotifier.sendMessage failed: $e');
      state = state.copyWith(isSending: false);
    }
  }

  /// Mark all messages as read
  Future<void> markAsRead() async {
    final conversation = state.activeConversation;
    if (conversation == null) return;

    await SupportChatService.markMessagesAsRead(conversation.id);
    state = state.copyWith(totalUnreadCount: 0);
  }

  /// Load total unread count
  Future<void> loadUnreadCount() async {
    final count = await SupportChatService.getTotalUnreadCount();
    state = state.copyWith(totalUnreadCount: count);
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    super.dispose();
  }
}

final supportChatProvider =
    StateNotifierProvider<SupportChatNotifier, SupportChatState>(
  (ref) => SupportChatNotifier(),
);

final supportUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(supportChatProvider).totalUnreadCount;
});
