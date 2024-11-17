import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import '../auth/login_screen.dart';
import 'package:social_app/models/user_model.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _username;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _setUserStatus('online');
  }

  Future<void> _fetchUsername() async {
    final user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _username = userDoc.get('username') ?? 'User';
      });
    }
  }

  @override
  void dispose() {
    _setUserStatus('offline');
    super.dispose();
  }

  Future<void> _setUserStatus(String status) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'status': status,
      });
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await _setUserStatus('offline');
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    return Scaffold(
      backgroundColor: Colors.white, // White background for the full page
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Image.asset(
          'assets/fireLogo.jpg',
          height: 50,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Text(
                'Welcome, ${_username ?? "User"}!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('uid', isNotEqualTo: currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No users found.'));
                }

                var filteredUsers = snapshot.data!.docs.where((userDoc) {
                  var userData = userDoc.data() as Map<String, dynamic>;
                  return userData['username']
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                }).toList();

                return ListView(
                  children: filteredUsers.map((userDoc) {
                    var userData = userDoc.data() as Map<String, dynamic>;
                    return _buildUserTile(userData);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> userData) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(userData['avatarUrl'] ?? ''),
          radius: 25,
        ),
        title: Text(
          userData['username'] ?? 'Unknown User',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              userData['status'] == 'online'
                  ? Icons.circle
                  : Icons.circle_outlined,
              color: userData['status'] == 'online' ? Colors.green : Colors.red,
              size: 12,
            ),
            SizedBox(width: 5),
            Text(userData['status'] ?? 'offline'),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ChatScreen(userModel: UserModel.fromMap(userData)),
            ),
          );
        },
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Search for a User'),
          content: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Enter username',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
