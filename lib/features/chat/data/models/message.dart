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
  final String? filePath;
  final bool isImage;
  final MessageRole role;

  Message({
    String? id,
    required this.content,
    required this.role,
    this.filePath,
    this.isImage = false,
  }) : id = (id == null || id.isEmpty) ? _generateMessageId() : id;

  bool get isUser => role == MessageRole.user;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      content: json['content'],
      role: json['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
      filePath: json['filePath'],
      isImage: json['isImage'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role == MessageRole.user ? 'user' : 'assistant',
    'content': content,
    'filePath': filePath,
    'isImage': isImage,
  };

  factory Message.fromUser(
    String text, {
    String? filePath,
    bool isImage = false,
  }) => Message(
    content: text,
    role: MessageRole.user,
    filePath: filePath,
    isImage: isImage,
  );

  factory Message.fromAssistant(String text) =>
      Message(content: text, role: MessageRole.assistant);

  Message copyWith({
    String? id,
    String? content,
    String? filePath,
    bool? isImage,
    MessageRole? role,
  }) => Message(
    id: id ?? this.id,
    content: content ?? this.content,
    filePath: filePath ?? this.filePath,
    isImage: isImage ?? this.isImage,
    role: role ?? this.role,
  );
}
