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
  late Stream<QuerySnapshot> _chatStream;
  Timer? _typingTimer;

  // Add a ScrollController to manage scrolling
  final ScrollController _scrollController = ScrollController();

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

  // Scroll to the bottom
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
                  StreamBuilder<DocumentSnapshot>(
                    stream: _firestore
                        .collection('typing_status')
                        .doc(widget.userModel.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        if (data['isTyping'] == true) {
                          return AnimatedDots(); // Animated dots widget
                        }
                      }
                      return SizedBox.shrink();
                    },
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

                  final chatDocs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['senderId'] == _auth.currentUser!.uid &&
                            data['receiverId'] == widget.userModel.uid) ||
                        (data['senderId'] == widget.userModel.uid &&
                            data['receiverId'] == _auth.currentUser!.uid);
                  }).map((doc) {
                    return ChatModel.fromMap(
                        doc.data() as Map<String, dynamic>);
                  }).toList();

                  _scrollToBottom();

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: chatDocs.length,
                    itemBuilder: (context, index) {
                      final chat = chatDocs[index];
                      final isMe = chat.senderId == _auth.currentUser!.uid;

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.teal : Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            chat.message,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.white70,
                              fontSize: 16,
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

class AnimatedDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Dot(),
        SizedBox(width: 4),
        Dot(),
        SizedBox(width: 4),
        Dot(),
      ],
    );
  }
}

class Dot extends StatefulWidget {
  @override
  _DotState createState() => _DotState();
}

class _DotState extends State<Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 + _controller.value,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.tealAccent,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}