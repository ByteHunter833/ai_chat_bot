import 'package:nova_ai/features/chat/data/datasource/chat_remote_datasource.dart';
import 'package:nova_ai/features/chat/data/models/message.dart';
import 'package:nova_ai/features/chat/data/open_router_client.dart';

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final OpenRouterClient _client;

  ChatRemoteDataSourceImpl({required String apiKey})
    : _client = OpenRouterClient(false, apiKey);

  @override
  Stream<String> streamMessage(List<Message> messages) {
    return _client.streamChatCompletion(
      messages.map((message) => message.toJson()).toList(),
    );
  }
}
