import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nova_ai/features/chat/data/models/message.dart';
import 'package:nova_ai/core/shared_widgets/chat/ai_message_buble.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onCopyAll; // копировать весь ответ
  final VoidCallback? onLike; // 👍
  final VoidCallback? onDislike; // 👎
  final bool isLoading; // для отображения индикатора загрузки

  const MessageBubble({
    super.key,
    required this.message,
    this.onCopyAll,
    this.onLike,
    this.onDislike,
    required this.isLoading,
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
            ),
    );
  }

  // Пользовательское сообщение (без кнопок)
  Widget _buildUserBubble() {
    final hasFile = message.filePath != null && message.filePath!.isNotEmpty;
    final file = hasFile ? File(message.filePath!) : null;
    final showImage = hasFile && message.isImage && file!.existsSync();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                file,
                width: 220,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
            if (message.content.trim().isNotEmpty) const SizedBox(height: 8),
          ],
          if (message.content.trim().isNotEmpty)
            Text(
              message.content,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
        ],
      ),
    );
  }
}
