enum MessageType { user, assistant }

class Message {
  final String content;
  final MessageType role;

  Message({required this.content, required this.role});

  Message.fromJson(Map<String, dynamic> json)
    : content = json['content'],
      role = json['role'] == 'user' ? MessageType.user : MessageType.assistant;

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'role': role == MessageType.user ? 'user' : 'assistant',
    };
  }
}
