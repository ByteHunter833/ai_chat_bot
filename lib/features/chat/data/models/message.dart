enum MessageType { user, assistant }

class Message {
  final String content;
  final MessageType role;
  final String? imageBase64;
  final String? imageMimeType;

  Message({
    required this.content,
    required this.role,
    this.imageBase64,
    this.imageMimeType,
  });

  Message.fromJson(Map<String, dynamic> json)
    : content = json['content'] is String ? json['content'] as String : '',
      role = json['role'] == 'user' ? MessageType.user : MessageType.assistant,
      imageBase64 = null,
      imageMimeType = null;

  Map<String, dynamic> toJson() {
    final roleName = role == MessageType.user ? 'user' : 'assistant';
    if (imageBase64 == null) {
      return {'content': content, 'role': roleName};
    }
    return {
      'role': roleName,
      'content': [
        if (content.isNotEmpty) {'type': 'text', 'text': content},
        {
          'type': 'image_url',
          'image_url': {
            'url': 'data:${imageMimeType ?? 'image/jpeg'};base64,$imageBase64',
          },
        },
      ],
    };
  }
}
