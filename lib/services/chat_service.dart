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
  Stream<List<ChatModel>> getMessages(String senderId, String receiverId) {
    return _firestore
        .collection('chats')
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: receiverId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      // Ensure no null ChatModel is returned
      return snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data()))
          .where((chatModel) => chatModel != null)
          .toList() as List<ChatModel>;
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
