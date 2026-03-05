import 'package:ai_chat_bot/repository/chat_repository.dart';

import '../models/chat.dart';
import '../models/message.dart';

class ChatService {
  final ChatRepository _repository;

  ChatService(this._repository);

  List<Chat> _chats = [];

  List<Chat> get chats => List.unmodifiable(_chats);

  /// Загрузка чатов при старте приложения
  Future<void> init() async {
    _chats = await _repository.loadChats();
  }

  /// Создать новый пустой чат и добавить его в начало списка
  Chat createChat() {
    final chat = Chat.empty();
    _chats = [chat, ..._chats];
    persist();
    return chat;
  }

  /// Добавить сообщение пользователя в указанный чат
  /// Возвращает обновлённый чат
  Chat addUserMessage(
    String chatId,
    String text, {
    String? filePath,
    bool isImage = false,
  }) {
    return _addMessage(
      chatId,
      Message.fromUser(text, filePath: filePath, isImage: isImage),
    );
  }

  /// Добавить сообщение ассистента в указанный чат
  Chat addAssistantMessage(String chatId, String text) {
    return _addMessage(chatId, Message.fromAssistant(text));
  }

  /// Обновить последнее сообщение ассистента (для стриминга)
  Chat updateLastAssistantMessage(String chatId, String fullText) {
    final index = _indexOf(chatId);
    if (index == -1) throw StateError('Chat $chatId not found');

    final chat = _chats[index];
    final messages = List<Message>.from(chat.messages);

    if (messages.isNotEmpty && !messages.last.isUser) {
      messages[messages.length - 1] = messages.last.copyWith(content: fullText);
    }

    // Обновляем title чата по первому сообщению пользователя
    final updatedChat = chat.copyWith(
      messages: messages,
      title: _deriveTitleFromMessages(messages, chat.title),
    );

    _chats[index] = updatedChat;
    persist();
    return updatedChat;
  }

  /// Очистить историю сообщений в чате
  Chat clearChat(String chatId) {
    final index = _indexOf(chatId);
    if (index == -1) throw StateError('Chat $chatId not found');

    final cleared = _chats[index].copyWith(messages: []);
    _chats[index] = cleared;
    persist();
    return cleared;
  }

  /// Получить чат по ID
  Chat? findById(String chatId) {
    final index = _indexOf(chatId);
    return index != -1 ? _chats[index] : null;
  }

  /// Получить историю в формате, ожидаемом LLM API
  List<Map<String, dynamic>> buildApiHistory(String chatId) {
    final chat = findById(chatId);
    if (chat == null) return [];
    return chat.messages
        .where((m) => m.content.isNotEmpty)
        .map(
          (m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.content,
          },
        )
        .toList();
  }

  // ─── Вспомогательные методы ───────────────────────────────────────────────

  Chat _addMessage(String chatId, Message message) {
    final index = _indexOf(chatId);
    if (index == -1) throw StateError('Chat $chatId not found');

    final chat = _chats[index];
    final updatedMessages = [...chat.messages, message];
    final updatedChat = chat.copyWith(
      messages: updatedMessages,
      title: _deriveTitleFromMessages(updatedMessages, chat.title),
    );

    _chats[index] = updatedChat;
    persist();
    return updatedChat;
  }

  int _indexOf(String chatId) => _chats.indexWhere((c) => c.id == chatId);

  /// Автоматически называем чат по первому сообщению пользователя
  String _deriveTitleFromMessages(List<Message> messages, String currentTitle) {
    if (currentTitle != 'New Chat') return currentTitle;
    final firstUserMsg = messages.firstWhere(
      (m) => m.isUser,
      orElse: () => Message.fromUser(''),
    );
    if (firstUserMsg.content.isEmpty) return currentTitle;
    final title = firstUserMsg.content;
    return title.length > 40 ? '${title.substring(0, 40)}…' : title;
  }

  Future<void> persist() => _repository.saveChats(_chats);

  void deleteChat(String id) {
    _chats.removeWhere((chat) => chat.id == id);
    persist();
  }
}
