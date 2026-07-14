part of 'chat_cubit.dart';

class ChatState extends Equatable {
  final List<Message> messages;
  final List<Suggestion> suggestions;

  ChatState({required this.messages, required this.suggestions});

  ChatState copyWith({
    List<Message>? messages,
    List<Suggestion>? suggestions,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      suggestions: suggestions ?? this.suggestions,
    );
  }

  @override
  List<Object?> get props => [messages, suggestions];
}
