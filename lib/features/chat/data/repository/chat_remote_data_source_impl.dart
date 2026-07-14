import 'package:nova_ai/core/network/dio_client.dart';
import 'package:nova_ai/features/chat/data/datasource/chat_remote_datasource.dart';
import 'package:nova_ai/features/chat/data/models/message.dart';

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final String apiKey;
  final DioClient dioClient;

  ChatRemoteDataSourceImpl({required this.apiKey})
    : dioClient = DioClient(apiKey);
  @override
  Future<Message> sendMessage(List<Message> messages) async {
    final response = await dioClient.post(
      '/chat/completions',
      data: {
        'model': 'google/gemma-4-26b-a4b-it:free',
        'messages': messages.map((message) => message.toJson()).toList(),
      },
    );
    return Message.fromJson(response.data['choices'][0]['message']);
  }
}
