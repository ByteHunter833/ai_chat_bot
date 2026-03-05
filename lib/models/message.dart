enum MessageRole { user, assistant }

int _messageIdSeed = 0;

String _generateMessageId() {
  _messageIdSeed += 1;
  final micros = DateTime.now().microsecondsSinceEpoch;
  return '${micros}_$_messageIdSeed';
}

class Message {
  final String id;
  final String content;
  final MessageRole role;

  Message({String? id, required this.content, required this.role})
    : id = (id == null || id.isEmpty) ? _generateMessageId() : id;

  bool get isUser => role == MessageRole.user;

  /// Десериализация из JSON (fake DB / backend)
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      content: json['content'] as String,
      role: json['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
    );
  }

  /// Сериализация в JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role == MessageRole.user ? 'user' : 'assistant',
    'content': content,
  };

  /// Удобный конструктор для создания сообщения пользователя
  factory Message.fromUser(String text) =>
      Message(content: text, role: MessageRole.user);

  /// Удобный конструктор для создания сообщения ассистента
  factory Message.fromAssistant(String text) =>
      Message(content: text, role: MessageRole.assistant);

  /// Копирование с изменением полей
  Message copyWith({String? id, String? content, MessageRole? role}) => Message(
    id: id ?? this.id,
    content: content ?? this.content,
    role: role ?? this.role,
  );
}
