import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore package
import '../auth/login_screen.dart';

class HomeScreen extends StatelessWidget {
  final _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<void> _signOut(BuildContext context) async {
  // Set user status to offline before logging out
  await _setUserOffline(_auth.currentUser);

  // Sign out the user
  await _auth.signOut();

  // Navigate to the login screen
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => LoginScreen()),
  );
}


  // Update the user's status in Firestore to 'online'
  Future<void> _setUserOnline(User? user) async {
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'status': 'online',
      });
    }
  }

  // Set user status to 'offline' when they log out or app goes background
  Future<void> _setUserOffline(User? user) async {
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'status': 'offline',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    // Set the user online when the app is opened
    _setUserOnline(user);

    return Scaffold(
      appBar: AppBar(
        title: Text('Accueil'),
        actions: [
          // Notification icon on the right
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications action
            },
          ),
          // Log out button
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => _signOut(context), // Call signOut on press
          ),
        ],
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo.png', fit: BoxFit.cover), // Insert your logo here
        ),
      ),
      body: Column(
        children: [
          // Online users section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          // Fetch and display users dynamically excluding the current user
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(), // Firestore stream
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

                // List of users from Firestore
                List<DocumentSnapshot> users = snapshot.data!.docs;

                // Filter out the current user based on user ID
                users = users.where((userDoc) {
                  var userData = userDoc.data() as Map<String, dynamic>;
                  return userData['uid'] != user?.uid; // Exclude the current user
                }).toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: users.map((userDoc) {
                      // Get user data
                      var userData = userDoc.data() as Map<String, dynamic>;
                      String userName = userData['username'] ?? 'Unknown User'; // Username field
                      String userAvatarUrl = userData['avatarUrl'] ?? '';
                      String userStatus = userData['status'] ?? 'offline'; // User's status

                      // Set the color of the online indicator (green for online, grey for offline)
                      Color onlineStatusColor = userStatus == 'online' ? Colors.green : Colors.grey;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: userAvatarUrl.isNotEmpty
                                      ? NetworkImage(userAvatarUrl) as ImageProvider
                                      : AssetImage('assets/default_avatar.png') as ImageProvider,
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
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          // Chats section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.chat, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Chats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          // List of chats (for now just a placeholder)
          Expanded(
            child: ListView.builder(
              itemCount: 5, // Replace with dynamic count
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(child: Icon(Icons.chat_bubble)),
                  title: Text('Chat with User ${index + 1}'),
                  subtitle: Text('Last message'),
                  onTap: () {
                    // Handle chat item tap
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
