import 'package:nova_ai/features/chat/data/models/message.dart';

abstract class ChatRemoteDataSource {
  Future<Message> sendMessage(List<Message> messages);
}
