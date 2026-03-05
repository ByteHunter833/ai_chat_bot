import 'package:ai_chat_bot/models/message.dart';
import 'package:ai_chat_bot/widgets/ai_message_buble.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onCopyAll; // копировать весь ответ
  final VoidCallback? onLike; // 👍
  final VoidCallback? onDislike; // 👎
  final bool isLoading; // для отображения индикатора загрузки
  final String? reasoningText;
  final bool isReasoningStreaming;

  const MessageBubble({
    super.key,
    required this.message,
    this.onCopyAll,
    this.onLike,
    this.onDislike,
    required this.isLoading,
    this.reasoningText,
    this.isReasoningStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: isUser
          ? _buildUserBubble()
          : AiMessageBubble(
              text: message.content,
              onCopyAll: onCopyAll,
              onLike: onLike,
              onDislike: onDislike,
              isLoading: isLoading,
              reasoningText: reasoningText,
              isReasoningStreaming: isReasoningStreaming,
            ),
    );
  }

  // Пользовательское сообщение (без кнопок)
  Widget _buildUserBubble() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message.content,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
