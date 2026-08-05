import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:nova_ai/features/chat/data/models/chat.dart';
import 'package:nova_ai/features/chat/data/models/message.dart';
import 'package:nova_ai/features/chat/data/models/open_router_model.dart';
import 'package:nova_ai/features/chat/data/models/suggestions.dart';
import 'package:nova_ai/features/chat/domain/repositories/chat_repository.dart';
import 'package:nova_ai/features/chat/domain/repositories/sql_chat_repository.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository chatRepository;
  final SQLiteChatRepository sqlChatRepository = SQLiteChatRepository();

  static final List<OpenRouterModel> _models = [
    const OpenRouterModel(
      id: 'google/gemma-4-26b-a4b-it:free',
      name: 'Gemma 4.26B',
      description: 'Reasoning and code generation',
      supportsVision: true,
      supportsReasoning: true,
    ),

    const OpenRouterModel(
      id: 'inclusionai/ling-3.0-flash:free',
      name: 'Ling 3.0 Flash',
      description: 'Role Play',
      goodForRoleplay: true,
    ),
    const OpenRouterModel(
      id: 'cohere/north-mini-code:free',
      name: 'North Mini Code',
      description: 'Code generation',
    ),
  ];

  ChatCubit(this.chatRepository)
    : super(
        ChatState(
          models: _models,
          selectedModel: _models.first.id,
          messages: [],
          chats: [],
          suggestions: [
            const Suggestion(
              text: 'Design a database schema',
              description: 'for an online merch store',
            ),
            const Suggestion(
              text: 'Explain airplane',
              description: 'to someone 5 years old',
            ),
            const Suggestion(
              text: 'What is the capital of France?',
              description: 'Learn about the capital city of France.',
            ),
          ],
        ),
      );

  void sendMessage(
    String content, {
    String? imageBase64,
    String? imageMimeType,
    String? imageFilePath,
  }) async {
    final currentChat = _currentChat();
    final newMessage = Message(
      id: _messageId(),
      content: content,
      role: MessageType.user,
      imageBase64: imageBase64,
      imageMimeType: imageMimeType,
      filePath: imageFilePath,
      isImage: imageBase64 != null || imageFilePath != null,
    );
    final userMessages = [...currentChat.messages, newMessage];
    final userChat = currentChat.copyWith(
      title: currentChat.messages.isEmpty
          ? _titleFromMessage(content)
          : currentChat.title,
      messages: userMessages,
    );
    final chatsWithUserMessage = _upsertChat(userChat);
    emit(
      state.copyWith(
        messages: userMessages,
        chats: chatsWithUserMessage,
        currentChatId: userChat.id,
        isLoading: true,
        isStreaming: true,
      ),
    );
    await _persistChats(chatsWithUserMessage);

    final buffer = StringBuffer();
    final assistantMessageId = _messageId();
    try {
      await for (final chunk in chatRepository.streamMessage(
        userMessages,
        model: state.selectedModel,
      )) {
        buffer.write(chunk);
        final streamedMessages = [
          ...userMessages,
          Message(
            id: assistantMessageId,
            content: buffer.toString(),
            role: MessageType.assistant,
          ),
        ];
        emit(
          state.copyWith(
            messages: streamedMessages,
            isLoading: false,
            isStreaming: true,
          ),
        );
      }
      if (buffer.isEmpty) {
        emit(
          state.copyWith(
            messages: userMessages,
            isLoading: false,
            isStreaming: false,
            errorMessage: 'The model returned an empty response.',
          ),
        );
      } else {
        final finalMessages = [
          ...userMessages,
          Message(
            id: assistantMessageId,
            content: buffer.toString(),
            role: MessageType.assistant,
          ),
        ];
        final finalChat = userChat.copyWith(messages: finalMessages);
        final finalChats = _upsertChat(finalChat, state.chats);
        emit(
          state.copyWith(
            messages: finalMessages,
            chats: finalChats,
            isLoading: false,
            isStreaming: false,
          ),
        );
        await _persistChats(finalChats);
      }
    } catch (e) {
      emit(
        state.copyWith(
          messages: userMessages,
          isLoading: false,
          isStreaming: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void saveChats(List<Chat> chats) async {
    await _persistChats(chats);
  }

  Future<void> loadChats() async {
    try {
      final chats = await sqlChatRepository.loadChats();
      if (chats.isNotEmpty) {
        final currentChat = chats.first;
        emit(
          state.copyWith(
            messages: currentChat.messages,
            chats: chats,
            currentChatId: currentChat.id,
          ),
        );
      } else {
        final newChat = Chat.empty();
        emit(
          state.copyWith(
            messages: newChat.messages,
            chats: [newChat],
            currentChatId: newChat.id,
          ),
        );
        await _persistChats([newChat]);
      }
    } catch (e) {
      emit(
        state.copyWith(errorMessage: 'Failed to load chats: ${e.toString()}'),
      );
    }
  }

  void selectChat(String chatId) {
    final chatIndex = state.chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex == -1) return;

    final chat = state.chats[chatIndex];
    emit(
      state.copyWith(
        messages: chat.messages,
        currentChatId: chat.id,
        isLoading: false,
        isStreaming: false,
      ),
    );
  }

  Future<void> startNewChat() async {
    final newChat = Chat.empty();
    final chats = _upsertChat(newChat);
    emit(
      state.copyWith(
        messages: [],
        chats: chats,
        currentChatId: newChat.id,
        isLoading: false,
        isStreaming: false,
      ),
    );
    await _persistChats(chats);
  }

  void clearChat() {
    final chat = _currentChat().copyWith(messages: []);
    final chats = _upsertChat(chat);
    emit(
      state.copyWith(
        messages: [],
        chats: chats,
        currentChatId: chat.id,
        isLoading: false,
        isStreaming: false,
      ),
    );
    _persistChats(chats);
  }

  String _messageId() => DateTime.now().microsecondsSinceEpoch.toString();

  Chat _currentChat() {
    final currentChatId = state.currentChatId;
    final chatIndex = state.chats.indexWhere(
      (chat) => chat.id == currentChatId,
    );
    if (chatIndex != -1) return state.chats[chatIndex];
    if (state.chats.isNotEmpty) return state.chats.first;
    return Chat.empty();
  }

  List<Chat> _upsertChat(Chat chat, [List<Chat>? sourceChats]) {
    final chats = List<Chat>.from(sourceChats ?? state.chats);
    final chatIndex = chats.indexWhere((item) => item.id == chat.id);
    if (chatIndex == -1) {
      return [chat, ...chats];
    }

    chats[chatIndex] = chat;
    return chats;
  }

  Future<void> _persistChats(List<Chat> chats) async {
    try {
      await sqlChatRepository.saveChats(chats);
    } catch (e) {
      emit(
        state.copyWith(errorMessage: 'Failed to save chats: ${e.toString()}'),
      );
    }
  }

  String _titleFromMessage(String content) {
    final normalized = content.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return 'New Chat';
    return normalized.length > 42
        ? '${normalized.substring(0, 42)}...'
        : normalized;
  }

  void setSelectedModel(String id) {
    emit(state.copyWith(selectedModel: id));
    debugPrint('Selected model updated to: $id');
  }
}
