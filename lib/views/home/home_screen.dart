import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import '../auth/login_screen.dart';
import 'package:social_app/models/user_model.dart';
import 'package:social_app/models/chat_model.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all users excluding the logged-in user
  Future<List<UserModel>> _fetchUsers() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final userCollection = await firestore.collection('users').get();

    final String currentUserUid = _auth.currentUser!.uid;

    return userCollection.docs
        .where((doc) => doc['uid'] != currentUserUid)
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList();
  }

  // Fetch last message sent between the current user and the target user
  Future<String> _getLastMessage(String userId) async {
    final chatSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('senderId', isEqualTo: _auth.currentUser!.uid)
        .where('receiverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (chatSnapshot.docs.isNotEmpty) {
      final chat = ChatModel.fromMap(chatSnapshot.docs.first.data());
      return chat.message;
    } else {
      return "No messages yet";
    }
  }

  // Sign out function
  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Users',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text('No users found.');
                }

                List<DocumentSnapshot> users = snapshot.data!.docs;
                users = users.where((userDoc) {
                  var userData = userDoc.data() as Map<String, dynamic>;
                  return userData['uid'] != _auth.currentUser!.uid;
                }).toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: users.map((userDoc) {
                      var userData = userDoc.data() as Map<String, dynamic>;
                      String userName = userData['username'] ?? 'Unknown User';
                      String userAvatarUrl = userData['avatarUrl'] ?? '';
                      String userStatus = userData['status'] ?? 'offline';

                      Color onlineStatusColor =
                          userStatus == 'online' ? Colors.green : Colors.grey;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                    userModel: UserModel.fromMap(userData)),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: userAvatarUrl.isNotEmpty
                                        ? NetworkImage(userAvatarUrl)
                                        : AssetImage(
                                                'assets/default_avatar.png')
                                            as ImageProvider,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      height: 10,
                                      width: 10,
                                      decoration: BoxDecoration(
                                        color: onlineStatusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(userName, style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.chat, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Chats',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .where('senderId', isEqualTo: _auth.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text('No chats found.');
                }

                List<DocumentSnapshot> chatDocs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    var chatData =
                        chatDocs[index].data() as Map<String, dynamic>;
                    String receiverId = chatData['receiverId'];
                    return FutureBuilder<String>(
                      future: _getLastMessage(receiverId),
                      builder: (context, lastMessageSnapshot) {
                        if (!lastMessageSnapshot.hasData) {
                          return ListTile(
                            leading:
                                CircleAvatar(child: Icon(Icons.chat_bubble)),
                            title: Text('Loading...'),
                            subtitle: Text('Loading...'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                      userModel: UserModel.fromMap(chatData)),
                                ),
                              );
                            },
                          );
                        }

                        return ListTile(
                          leading: CircleAvatar(child: Icon(Icons.chat_bubble)),
                          title: Text('Chat with ${receiverId}'),
                          subtitle: Text(lastMessageSnapshot.data!),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                    userModel: UserModel.fromMap(chatData)),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
