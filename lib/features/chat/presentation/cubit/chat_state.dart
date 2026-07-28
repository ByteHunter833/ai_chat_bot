part of 'chat_cubit.dart';

class ChatState extends Equatable {
  final List<Message> messages;
  final List<Suggestion> suggestions;
  final bool isLoading;
  final String? errorMessage;

  ChatState({
    required this.messages,
    required this.suggestions,
    this.isLoading = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<Message>? messages,
    List<Suggestion>? suggestions,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [messages, suggestions, isLoading, errorMessage];
}
