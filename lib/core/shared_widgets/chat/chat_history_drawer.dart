import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nova_ai/features/chat/data/models/chat.dart';
import 'package:nova_ai/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:quick_action_menu/quick_action_menu.dart';

class ChatHistoryDrawer extends StatefulWidget {
  const ChatHistoryDrawer({super.key});

  @override
  State<ChatHistoryDrawer> createState() => _ChatHistoryDrawerState();
}

class _ChatHistoryDrawerState extends State<ChatHistoryDrawer> {
  final TextEditingController searchController = TextEditingController();
  String query = '';

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() => query = searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _showQuickActions(BuildContext context, Chat chat) {
    final menu = QuickActionMenu.of(context);
    if (menu.isMenuDisplayed) {
      menu.hideMenu();
      return;
    }
    menu.showMenu(
      tag: 'chat_${chat.id}',
      bottomMenuWidget: _QuickActionsMenu(
        chat: chat,
        onRename: () => _renameChat(context, chat),
        onDelete: () => _confirmDelete(context, chat),
        onClear: () => _clearChat(context, chat),
      ),
      bottomMenuAlignment: OverlayMenuHorizontalAlignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Future<void> _renameChat(BuildContext context, Chat chat) async {
    await QuickActionMenu.of(context).hideMenu();
    if (!mounted) return;
    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) => _RenameChatDialog(initialTitle: chat.title),
    );
    if (newTitle != null && newTitle.trim().isNotEmpty) {
      context.read<ChatCubit>().renameChat(chat.id, newTitle);
    }
  }

  Future<void> _confirmDelete(BuildContext context, Chat chat) async {
    await QuickActionMenu.of(context).hideMenu();
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete chat?'),
        content: Text('"${chat.title}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<ChatCubit>().deleteChat(chat.id);
    }
  }

  Future<void> _clearChat(BuildContext context, Chat chat) async {
    await QuickActionMenu.of(context).hideMenu();
    if (!mounted) return;
    context.read<ChatCubit>().selectChat(chat.id);
    context.read<ChatCubit>().clearChat();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Nova AI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search chats',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Recent chats',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: QuickActionMenu(
                  child: BlocBuilder<ChatCubit, ChatState>(
                    builder: (context, state) {
                      final filtered = _filterChats(state.chats);
                      // Empty State
                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'No chats found',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      // displaying chats
                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final chat = filtered[index];
                          final isSelected = chat.id == state.currentChatId;
                          return QuickActionAnchor(
                            tag: 'chat_${chat.id}',
                            child: GestureDetector(
                              onLongPress: () =>
                                  _showQuickActions(context, chat),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: ListTile(
                                  selected: isSelected,
                                  selectedTileColor:
                                      colorScheme.primaryContainer,
                                  leading: Icon(
                                    CupertinoIcons.chat_bubble_2_fill,
                                    size: 20,
                                    color: isSelected
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  title: Text(
                                    chat.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    chat.preview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      CupertinoIcons.ellipsis,
                                      size: 18,
                                      color: isSelected
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () =>
                                        _showQuickActions(context, chat),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  onTap: () {
                                    context.read<ChatCubit>().selectChat(
                                      chat.id,
                                    );
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Chat> _filterChats(List<Chat> chats) {
    if (query.isEmpty) return chats;
    return chats.where((chat) {
      final title = chat.title.toLowerCase();
      final preview = chat.preview.toLowerCase();
      return title.contains(query) || preview.contains(query);
    }).toList();
  }
}

class _RenameChatDialog extends StatefulWidget {
  const _RenameChatDialog({required this.initialTitle});

  final String initialTitle;

  @override
  State<_RenameChatDialog> createState() => _RenameChatDialogState();
}

class _RenameChatDialogState extends State<_RenameChatDialog> {
  late final TextEditingController controller = TextEditingController(
    text: widget.initialTitle,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename chat'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Enter new chat name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _QuickActionsMenu extends StatelessWidget {
  const _QuickActionsMenu({
    required this.chat,
    required this.onRename,
    required this.onDelete,
    required this.onClear,
  });

  final Chat chat;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QuickActionItem(
              icon: Icons.edit_outlined,
              label: 'Rename',
              onTap: onRename,
            ),
            _QuickActionItem(
              icon: Icons.delete_outline,
              label: 'Delete',
              iconColor: colorScheme.error,
              labelColor: colorScheme.error,
              onTap: onDelete,
            ),
            _QuickActionItem(
              icon: Icons.cleaning_services_outlined,
              label: 'Clear',
              onTap: onClear,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: iconColor ?? colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: labelColor ?? colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
