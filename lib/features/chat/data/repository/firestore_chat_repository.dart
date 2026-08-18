import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nova_ai/features/chat/data/models/chat.dart';
import 'package:nova_ai/features/chat/data/models/message.dart';

class FirestoreChatRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  FirestoreChatRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : firestore = firestore ?? FirebaseFirestore.instance,
       firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Future<List<Chat>> loadChats() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return [Chat.empty()];

    final snapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .orderBy('createdAt', descending: true)
        .get();

    final chats = snapshot.docs.map(_chatFromDoc).toList();
    if (chats.isEmpty) return [Chat.empty()];
    return chats;
  }

  Future<void> saveChats(List<Chat> chats) async {
    final user = firebaseAuth.currentUser;
    if (user == null) return;

    final batch = firestore.batch();
    final collection = firestore
        .collection('users')
        .doc(user.uid)
        .collection('chats');

    for (final chat in chats) {
      batch.set(
        collection.doc(chat.id),
        {
          'title': chat.title,
          'createdAt': Timestamp.fromDate(chat.createdAt),
          'messages': chat.messages.map((m) => m.toJson()).toList(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> deleteChat(String chatId) async {
    final user = firebaseAuth.currentUser;
    if (user == null) return;
    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .doc(chatId)
        .delete();
  }

  Chat _chatFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final messages = (data['messages'] as List<dynamic>?)
            ?.map((m) => Message.fromJson(m as Map<String, dynamic>))
            .toList() ??
        <Message>[];
    return Chat(
      id: doc.id,
      title: data['title'] as String? ?? 'New Chat',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messages: messages,
    );
  }
}