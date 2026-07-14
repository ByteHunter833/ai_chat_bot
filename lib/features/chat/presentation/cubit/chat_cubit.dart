import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:nova_ai/features/chat/data/models/message.dart';
import 'package:nova_ai/features/chat/data/models/suggestions.dart';
import 'package:nova_ai/features/chat/domain/repositories/chat_repository.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository chatRepository;
  ChatCubit(this.chatRepository)
    : super(
        ChatState(
          messages: [],
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

  void sendMessage(String content) async {
    final newMessage = Message(content: content, role: MessageType.user);
    final updatedMessages = [...state.messages, newMessage];
    emit(state.copyWith(messages: updatedMessages));
    final response = await chatRepository.sendMessage(updatedMessages);
    final newMessages = [...updatedMessages, response];
    emit(state.copyWith(messages: newMessages));
  }
}
