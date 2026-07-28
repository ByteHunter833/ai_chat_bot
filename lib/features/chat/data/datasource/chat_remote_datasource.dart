import 'package:nova_ai/features/chat/data/models/message.dart';

abstract class ChatRemoteDataSource {
  Stream<String> streamMessage(List<Message> messages);
}
