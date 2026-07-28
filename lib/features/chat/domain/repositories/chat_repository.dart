import 'package:nova_ai/features/chat/data/models/message.dart';

abstract class ChatRepository {
  Stream<String> streamMessage(List<Message> messages);
}
