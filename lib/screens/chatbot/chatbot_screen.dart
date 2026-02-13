import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/bot_message.dart';
import '../../providers/chatbot_provider.dart';
import '../../theme/tokens.dart';

class ChatBotScreen extends ConsumerStatefulWidget {
  const ChatBotScreen({super.key});

  @override
  ConsumerState<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends ConsumerState<ChatBotScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  static const _suggestions = [
    'Come posso guadagnare di più?',
    'Quali sono le ore di punta?',
    'Come funzionano i livelli?',
    'Cos\'è il costo di hold?',
    'Come migliorare il rating?',
    'Quali bonus posso ottenere?',
    'Come funziona la consegna luxury?',
    'Cos\'è la cauzione di €250?',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? text]) {
    final msg = text ?? _textController.text.trim();
    if (msg.isEmpty) return;

    ref.read(chatBotProvider.notifier).sendMessage(msg);
    _textController.clear();
    _scrollToBottom();
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Cancella conversazione',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Vuoi eliminare tutta la cronologia chat con l\'assistente?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annulla', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(chatBotProvider.notifier).clearHistory();
            },
            child: Text(
              'Cancella',
              style: GoogleFonts.inter(color: AppColors.urgentRed),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatBotProvider);
    final cs = Theme.of(context).colorScheme;

    // Auto-scroll when messages change
    ref.listen(chatBotProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.earningsGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 18,
                color: AppColors.earningsGreen,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assistente dloop',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.earningsGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Online',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.earningsGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') _clearHistory();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: cs.onSurface),
                    const SizedBox(width: 8),
                    Text('Cancella conversazione',
                        style: GoogleFonts.inter(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.turboOrange))
          : Column(
              children: [
                // Error banner
                if (state.errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: AppColors.urgentRed.withOpacity(0.1),
                    child: Text(
                      state.errorMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.urgentRed,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: state.messages.isEmpty
                      ? _buildEmptyState(cs)
                      : _buildMessagesList(state.messages, cs),
                ),
                // Suggestion chips (only when empty or few messages)
                if (state.messages.length < 3 && !state.isTyping)
                  _buildSuggestionChips(cs),
                // Typing indicator
                if (state.isTyping) _buildTypingIndicator(cs),
                _buildInputBar(state, cs),
              ],
            ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.earningsGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(36),
            ),
            child: const Icon(
              Icons.smart_toy,
              size: 36,
              color: AppColors.earningsGreen,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ciao! Sono l\'assistente dloop',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Posso aiutarti con consigli su guadagni, zone calde, livelli e molto altro!',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<BotMessage> messages, ColorScheme cs) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final showDate = index == 0 ||
            !_isSameDay(messages[index - 1].createdAt, msg.createdAt);

        return Column(
          children: [
            if (showDate) _buildDateSeparator(msg.createdAt, cs),
            _BotMessageBubble(message: msg),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date, ColorScheme cs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    String label;
    if (messageDate == today) {
      label = 'Oggi';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      label = 'Ieri';
    } else {
      label = DateFormat('d MMMM yyyy', 'it_IT').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChips(ColorScheme cs) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(
              _suggestions[index],
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.turboOrange,
              ),
            ),
            backgroundColor: AppColors.turboOrange.withOpacity(0.08),
            side: BorderSide(color: AppColors.turboOrange.withOpacity(0.2)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => _sendMessage(_suggestions[index]),
          );
        },
      ),
    );
  }

  Widget _buildTypingIndicator(ColorScheme cs) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.earningsGreen.withOpacity(0.08),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smart_toy,
                size: 14, color: AppColors.earningsGreen),
            const SizedBox(width: 8),
            Text(
              'dloop sta scrivendo...',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.earningsGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(ChatBotState state, ColorScheme cs) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.onSurfaceVariant.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: GoogleFonts.inter(color: cs.onSurface, fontSize: 14),
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              enabled: !state.isTyping,
              decoration: InputDecoration(
                hintText: state.isTyping
                    ? 'Attendere la risposta...'
                    : 'Chiedi qualcosa...',
                hintStyle: GoogleFonts.inter(
                    color: cs.onSurfaceVariant, fontSize: 14),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: state.isTyping ? null : () => _sendMessage(),
            icon: state.isTyping
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.earningsGreen),
                  )
                : const Icon(Icons.send, color: AppColors.turboOrange),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _BotMessageBubble extends StatelessWidget {
  final BotMessage message;

  const _BotMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.turboOrange
              : AppColors.earningsGreen.withOpacity(0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight:
                isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.smart_toy,
                        size: 12, color: AppColors.earningsGreen),
                    const SizedBox(width: 4),
                    Text(
                      'dloop AI',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.earningsGreen,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              message.content,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isUser ? Colors.white : cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.createdAt),
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isUser
                    ? Colors.white60
                    : cs.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
