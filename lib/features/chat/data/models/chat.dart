// import 'message.dart';

// class Chat {
//   final String id;
//   final String title;
//   final DateTime createdAt;
//   final List<Message> messages;

//   const Chat({
//     required this.id,
//     required this.title,
//     required this.createdAt,
//     required this.messages,
//   });

//   /// Десериализация из JSON (fake DB / backend)
//   factory Chat.fromJson(Map<String, dynamic> json) {
//     return Chat(
//       id: json['id'] as String,
//       title: json['title'] as String,
//       createdAt: DateTime.parse(json['createdAt'] as String),
//       messages: (json['messages'] as List<dynamic>)
//           .map((m) => Message.fromJson(m as Map<String, dynamic>))
//           .toList(),
//     );
//   }

//   /// Сериализация в JSON
//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'title': title,
//     'createdAt': createdAt.toIso8601String(),
//     'messages': messages.map((m) => m.toJson()).toList(),
//   };

//   /// Копирование с изменением полей — основной способ обновлять чат иммутабельно
//   Chat copyWith({
//     String? id,
//     String? title,
//     DateTime? createdAt,
//     List<Message>? messages,
//   }) {
//     return Chat(
//       id: id ?? this.id,
//       title: title ?? this.title,
//       createdAt: createdAt ?? this.createdAt,
//       messages: messages ?? this.messages,
//     );
//   }

//   /// Первое сообщение для превью в списке чатов
//   String get preview {
//     if (messages.isEmpty) return 'No messages';
//     return messages.first.content.length > 60
//         ? '${messages.first.content.substring(0, 60)}…'
//         : messages.first.content;
//   }

//   /// Фабрика для создания нового пустого чата
//   factory Chat.empty() => Chat(
//     id: DateTime.now().millisecondsSinceEpoch.toString(),
//     title: 'New Chat',
//     createdAt: DateTime.now(),
//     messages: [],
//   );
// }
