enum MessageType { user, assistant }

class Message {
  final String id;
  final String content;
  final MessageType role;
  final String? imageBase64;
  final String? imageMimeType;
  final String? filePath;
  final bool isImage;

  Message({
    required this.id,
    required this.content,
    required this.role,
    this.imageBase64,
    this.imageMimeType,
    this.filePath,
    this.isImage = false,
  });

  Message.fromJson(Map<String, dynamic> json)
    : content = json['content'] is String ? json['content'] as String : '',
      filePath = (json['filePath'] ?? json['file_path']) as String?,
      isImage = _readBool(json['isImage'] ?? json['is_image']),
      id = json['id'] as String? ?? '',
      role = json['role'] == 'user' ? MessageType.user : MessageType.assistant,
      imageBase64 = null,
      imageMimeType = null;

  bool get isUser => role == MessageType.user;

  Map<String, dynamic> toJson() {
    final roleName = role == MessageType.user ? 'user' : 'assistant';
    return {
      'id': id,
      'content': content,
      'role': roleName,
      'filePath': filePath,
      'isImage': isImage,
    };
  }

  Map<String, dynamic> toApiJson() {
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

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return false;
  }
}
