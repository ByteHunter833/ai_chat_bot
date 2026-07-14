import 'package:nova_ai/features/chat/data/models/message.dart';

abstract class ChatRepository {
  Future<Message> sendMessage(List<Message> messages);
}
