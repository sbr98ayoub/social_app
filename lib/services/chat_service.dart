import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send message to Firestore
  Future<void> sendMessage(ChatModel chat) async {
    try {
      await _firestore.collection('chats').add(chat.toMap());
    } catch (e) {
      throw Exception("Error sending message: $e");
    }
  }

  // Get chat messages between two users
  Stream<List<ChatModel>> getMessages(String user1Id, String user2Id) {
    return _firestore
        .collection('chats')
        .where('senderId', whereIn: [user1Id, user2Id])
        .where('receiverId', whereIn: [user1Id, user2Id])
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatModel.fromMap(doc.data() as Map<String, dynamic>);
          }).where((chat) {
            return (chat.senderId == user1Id && chat.receiverId == user2Id) ||
                (chat.senderId == user2Id && chat.receiverId == user1Id);
          }).toList();
        });
  }

  // Get the list of chats for a user
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('senderId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatModel.fromMap(doc.data())).toList();
    });
  }

  // Update read status of a message
  Future<void> markMessageAsRead(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({'read': true});
    } catch (e) {
      throw Exception("Error updating message status: $e");
    }
  }
}
