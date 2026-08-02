part of 'chat_cubit.dart';

class ChatState extends Equatable {
  final List<Message> messages;
  final List<Suggestion> suggestions;
  final bool isLoading;
  final bool isStreaming;
  final String? errorMessage;
  final List<Chat> chats;
  final String? currentChatId;

  ChatState({
    required this.messages,
    required this.suggestions,
    this.isLoading = false,
    this.isStreaming = false,
    this.errorMessage,
    required this.chats,
    this.currentChatId,
  });

  ChatState copyWith({
    List<Message>? messages,
    List<Suggestion>? suggestions,
    bool? isLoading,
    bool? isStreaming,
    String? errorMessage,
    List<Chat>? chats,
    String? currentChatId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      errorMessage: errorMessage,
      chats: chats ?? this.chats,
      currentChatId: currentChatId ?? this.currentChatId,
    );
  }

  @override
  List<Object?> get props => [
    messages,
    suggestions,
    isLoading,
    isStreaming,
    errorMessage,
    chats,
    currentChatId,
  ];
}
