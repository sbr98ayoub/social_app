import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../models/chat_model.dart';
import 'package:intl/intl.dart';
import 'dart:async';

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

  bool _isTyping = false;
  late Stream<QuerySnapshot> _chatStream;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();

    // Initialize chat stream
    _chatStream = _firestore
        .collection('chats')
        .orderBy('timestamp', descending: false)
        .snapshots();
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
    setState(() {
      _isTyping = false;
    });

    // Update typing status to false
    _firestore
        .collection('typing_status')
        .doc(_auth.currentUser!.uid)
        .set({'isTyping': false}, SetOptions(merge: true));
  }

  void _updateTypingStatus(bool isTyping) {
    if (isTyping) {
      _firestore
          .collection('typing_status')
          .doc(_auth.currentUser!.uid)
          .set({'isTyping': true}, SetOptions(merge: true));

      _typingTimer?.cancel();
      _typingTimer = Timer(Duration(seconds: 3), () {
        _firestore
            .collection('typing_status')
            .doc(_auth.currentUser!.uid)
            .set({'isTyping': false}, SetOptions(merge: true));
      });
    } else {
      _firestore
          .collection('typing_status')
          .doc(_auth.currentUser!.uid)
          .set({'isTyping': false}, SetOptions(merge: true));
      _typingTimer?.cancel();
    }
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
              stream: _chatStream,
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
                        margin:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
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
            ),
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore
                .collection('typing_status')
                .doc(widget.userModel.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                if (data['isTyping'] == true) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${widget.userModel.username} is typing...',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                }
              }
              return SizedBox.shrink();
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: 'Type a message...'),
                    onChanged: (text) {
                      setState(() {
                        _isTyping = text.trim().isNotEmpty;
                      });
                      _updateTypingStatus(_isTyping);
                    },
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
