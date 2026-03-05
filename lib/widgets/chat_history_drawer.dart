import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/chat.dart';

class ChatHistoryDrawer extends StatelessWidget {
  final List<Chat> chats;
  final String? activeChatId;
  final VoidCallback onNewChat;
  final ValueChanged<Chat> onChatSelected;
  final ValueChanged<Chat> onChatDeleted;

  const ChatHistoryDrawer({
    super.key,
    required this.chats,
    required this.activeChatId,
    required this.onNewChat,
    required this.onChatSelected,
    required this.onChatDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Заголовок ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.chat_bubble_2_fill,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Your Chats',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // ── Кнопка нового чата ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: FilledButton.tonalIcon(
                onPressed: onNewChat,
                icon: const Icon(CupertinoIcons.square_pencil_fill, size: 18),
                label: const Text('New Chat'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(height: 1),
            ),

            // ── Список чатов ───────────────────────────────────────
            Expanded(
              child: chats.isEmpty
                  ? Center(
                      child: Text(
                        'No chats yet. Start a new conversation!',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final isActive = chat.id == activeChatId;

                        return _ChatTile(
                          chat: chat,
                          isActive: isActive,
                          onTap: () => onChatSelected(chat),
                          onDelete: () => onChatDeleted(chat),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final Chat chat;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ChatTile({
    required this.chat,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? colorScheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Icon(
          isActive
              ? CupertinoIcons.chat_bubble_fill
              : CupertinoIcons.chat_bubble_2_fill,
          size: 20,
          color: isActive
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          chat.title,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        trailing: isActive
            ? null
            : IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: onDelete,
                tooltip: 'Delete chat',
                style: IconButton.styleFrom(
                  minimumSize: const Size(28, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
      ),
    );
  }
}
