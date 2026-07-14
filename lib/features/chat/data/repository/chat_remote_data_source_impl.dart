import 'package:nova_ai/features/chat/data/datasource/chat_remote_datasource.dart';
import 'package:nova_ai/features/chat/data/models/message.dart';

class ChatRemoteDataSourceImpl extends ChatRemoteDataSource {
  @override
  Future<Message> sendMessage(String content) async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate network delay
    return Message(
      content: 'Response to: $content',
      role: MessageType.assistant,
    );
  }
}
