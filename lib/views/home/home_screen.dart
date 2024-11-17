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

  @override
  void initState() {
    super.initState();
    _setUserStatus('online');
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .where('uid', isNotEqualTo: _auth.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No users found.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((userDoc) {
              var userData = userDoc.data() as Map<String, dynamic>;
              return _buildUserTile(userData);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> userData) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(userData['avatarUrl'] ?? ''),
      ),
      title: Text(userData['username'] ?? 'Unknown User'),
      subtitle: Text(userData['status'] ?? 'offline'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatScreen(userModel: UserModel.fromMap(userData)),
          ),
        );
      },
    );
  }
}
