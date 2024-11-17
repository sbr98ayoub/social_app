import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../models/chat_model.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final UserModel userModel;

  ChatScreen({required this.userModel});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  void _markMessagesAsRead() {
    _firestore
        .collection('chats')
        .where('receiverId', isEqualTo: _auth.currentUser!.uid)
        .where('senderId', isEqualTo: widget.userModel.uid)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'read': true});
      }
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final chat = ChatModel(
      senderId: _auth.currentUser!.uid,
      receiverId: widget.userModel.uid,
      message: _messageController.text.trim(),
      timestamp: Timestamp.now(),
      read: false,
    );

    await _firestore.collection('chats').add(chat.toMap());

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.userModel.username}'),
      ),
      body: Column(
        children: [
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('chats')
                .orderBy('timestamp', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No messages found.'));
              }

              final chatDocs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return (data['senderId'] == _auth.currentUser!.uid &&
                        data['receiverId'] == widget.userModel.uid) ||
                    (data['senderId'] == widget.userModel.uid &&
                        data['receiverId'] == _auth.currentUser!.uid);
              }).map((doc) {
                return ChatModel.fromMap(doc.data() as Map<String, dynamic>);
              }).toList();

              return ListView.builder(
                itemCount: chatDocs.length,
                itemBuilder: (context, index) {
                  final chat = chatDocs[index];
                  final isMe = chat.senderId == _auth.currentUser!.uid;

                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        chat.message,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          )),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
