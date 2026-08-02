import 'package:nova_ai/features/chat/data/models/chat.dart';
import 'package:nova_ai/features/chat/data/models/message.dart';
import 'package:nova_ai/service/data_base_service.dart';
import 'package:sqflite/sqflite.dart';

class SQLiteChatRepository {
  final dbProvider = AppDatabase.instance;

  Future<List<Chat>> loadChats() async {
    final db = await dbProvider.database;

    final chatMaps = await db.query('chats', orderBy: 'created_at DESC');

    List<Chat> chats = [];

    for (final chatMap in chatMaps) {
      final messages = await db.query(
        'messages',
        where: 'chat_id = ?',
        whereArgs: [chatMap['id']],
        orderBy: 'created_at ASC',
      );

      chats.add(
        Chat(
          id: chatMap['id'] as String,
          title: chatMap['title'] as String,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            (chatMap['created_at'] as int?) ?? 0,
          ),
          messages: messages
              .map(
                (m) => Message(
                  id: m['id'] as String,
                  content: m['content'] as String,
                  role: (m['is_user'] as int) == 1
                      ? MessageType.user
                      : MessageType.assistant,
                  filePath: m['file_path'] as String?,
                  isImage: ((m['is_image'] as int?) ?? 0) == 1,
                ),
              )
              .toList(),
        ),
      );
    }

    return chats;
  }

  Future<void> saveChats(List<Chat> chats) async {
    final db = await dbProvider.database;
    await db.transaction((txn) async {
      final batch = txn.batch();

      await txn.delete('messages');
      await txn.delete('chats');

      for (final chat in chats) {
        batch.insert('chats', {
          'id': chat.id,
          'title': chat.title,
          'created_at': chat.createdAt.millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        for (var i = 0; i < chat.messages.length; i++) {
          final message = chat.messages[i];
          batch.insert('messages', {
            'id': message.id,
            'chat_id': chat.id,
            'content': message.content,
            'file_path': message.filePath,
            'is_image': message.isImage ? 1 : 0,
            'is_user': message.isUser ? 1 : 0,
            // Keep deterministic message order inside each chat.
            'created_at': chat.createdAt.millisecondsSinceEpoch + i,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      await batch.commit(noResult: true);
    });
  }
}
