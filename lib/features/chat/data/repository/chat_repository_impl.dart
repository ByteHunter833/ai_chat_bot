import 'package:nova_ai/features/chat/data/datasource/chat_remote_datasource.dart';
import 'package:nova_ai/features/chat/data/models/message.dart';
import 'package:nova_ai/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource chatRemoteDataSource;
  ChatRepositoryImpl(this.chatRemoteDataSource);

  @override
  Stream<String> streamMessage(List<Message> messages, {String? model}) {
    return chatRemoteDataSource.streamMessage(messages, model: model);
  }
}
