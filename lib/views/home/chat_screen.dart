import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../models/chat_model.dart';
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
  String? _pinnedMessage;
  late Stream<QuerySnapshot> _chatStream;
  Timer? _typingTimer;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();

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

  void _showMessageOptions(BuildContext context, String messageId,
      String message, bool isEdited, bool isMe) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            // Delete option should be available for all users
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(messageId);
              },
            ),
            // Edit option only for the message sender
            if (isMe)
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(context, messageId, message);
                },
              ),
            // Pin option should be available for all users
            ListTile(
              leading: Icon(Icons.push_pin, color: Colors.orange),
              title: Text('Pin'),
              onTap: () {
                Navigator.pop(context);
                _pinMessage(message);
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteMessage(String messageId) async {
    try {
      await _firestore.collection('chats').doc(messageId).update({
        'message': 'This message was deleted',
        'isDeleted': true,
      });
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  void _editMessage(BuildContext context, String messageId, String oldMessage) {
    TextEditingController _editController =
        TextEditingController(text: oldMessage);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Message'),
          content: TextField(
            controller: _editController,
            decoration: InputDecoration(
              hintText: 'Enter new message',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _firestore.collection('chats').doc(messageId).update({
                  'message': _editController.text.trim(),
                  'isEdited': true,
                });
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _pinMessage(String message) {
    setState(() {
      _pinnedMessage = message;
    });
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.7),
              Color(0xFF044F48),
              Color(0xFF2A7561),
            ],
            stops: [0.0, 0.3, 1.0],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userModel.username,
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_pinnedMessage != null)
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.push_pin, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _pinnedMessage!,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages found.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final chatDocs = snapshot.data!.docs.map((doc) {
                    return {
                      'id': doc.id,
                      ...doc.data() as Map<String, dynamic>
                    };
                  }).toList();

                  _scrollToBottom();

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: chatDocs.length,
                    itemBuilder: (context, index) {
                      final chat = chatDocs[index];
                      final isMe = chat['senderId'] == _auth.currentUser!.uid;
                      final isDeleted = chat['isDeleted'] ?? false;
                      final isEdited = chat['isEdited'] ?? false;

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: GestureDetector(
                          onLongPress: () => _showMessageOptions(context,
                              chat['id'], chat['message'], isEdited, isMe),
                          child: Container(
                            margin: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            padding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.teal : Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isDeleted
                                      ? 'This message was deleted'
                                      : chat['message'],
                                  style: TextStyle(
                                    color: isDeleted
                                        ? Colors.red.shade300
                                        : (isMe
                                            ? Colors.white
                                            : Colors.white70),
                                    fontSize: 16,
                                    fontStyle: isDeleted
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                                if (isEdited && !isDeleted)
                                  Text(
                                    '(edited)',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                      ),
                      onChanged: (text) {
                        setState(() {
                          _isTyping = text.trim().isNotEmpty;
                        });
                        _updateTypingStatus(_isTyping);
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.tealAccent),
                    onPressed: _sendMessage,
                    padding: EdgeInsets.all(0),
                    splashRadius: 20,
                    iconSize: 30,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}