enum MessageType { user, assistant }

class Message {
  final String content;
  final MessageType role;

  Message({required this.content, required this.role});
}
