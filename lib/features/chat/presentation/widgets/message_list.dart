import 'package:flutter/widgets.dart';
import 'package:nova_ai/core/shared_widgets/chat/ai_message_buble.dart';
import 'package:nova_ai/core/shared_widgets/chat/ai_typing_buble.dart';
import 'package:nova_ai/core/shared_widgets/chat/user_message_buble.dart';
import 'package:nova_ai/features/chat/data/models/message.dart';

class MessageList extends StatelessWidget {
  final List<Message> messages;
  final bool isLoading;
  final bool isStreaming;
  final ScrollController scrollController;
  const MessageList({
    super.key,
    required this.messages,
    required this.isLoading,
    required this.isStreaming,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = messages.length + (isLoading ? 1 : 0);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: itemCount,
      controller: scrollController,
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return const AiTypingBuble();
        }
        final message = messages[index];
        final isUserMessage = message.role == MessageType.user;
        final isStreamingMessage =
            isStreaming && index == messages.length - 1 && !isUserMessage;

        return Align(
          alignment: isUserMessage
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: isUserMessage
              ? UserMessageBubble(message: message)
              : AiMessageBubble(
                  text: message.content,
                  showActions: !isStreamingMessage,
                ),
        );
      },
    );
  }
}
