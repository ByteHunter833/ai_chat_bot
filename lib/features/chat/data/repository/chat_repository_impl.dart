import 'package:nova_ai/features/chat/data/datasource/chat_remote_datasource.dart';
import 'package:nova_ai/features/chat/data/models/message.dart';
import 'package:nova_ai/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl extends ChatRepository {
  final ChatRemoteDataSource chatRemoteDataSource;
  ChatRepositoryImpl(this.chatRemoteDataSource);

  @override
  Future<Message> sendMessage(String message) async {
    return await chatRemoteDataSource.sendMessage(message);
  }
}
