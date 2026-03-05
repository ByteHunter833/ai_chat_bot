import '../models/chat.dart';

/// Абстрактный интерфейс репозитория.
/// Когда появится реальный backend — просто создаём новый класс,
/// реализующий этот интерфейс, и меняем одну строку в DI/провайдере.
abstract class ChatRepository {
  /// Загрузить все чаты
  Future<List<Chat>> loadChats();

  /// Сохранить список чатов (в fake DB — no-op или запись в файл)
  Future<void> saveChats(List<Chat> chats);
}
