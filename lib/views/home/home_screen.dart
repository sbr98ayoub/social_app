import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import '../auth/login_screen.dart';
import 'package:social_app/models/user_model.dart';
import 'package:social_app/views/home/AccountInfoScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _username;
  String _searchQuery = "";
  bool _hasSeenWelcomeCard = false; // Track if user has seen the welcome card
  List<String> _notifications = []; // List of notifications

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _setUserStatus('online');
    _loadNotifications();
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

  Future<void> _loadNotifications() async {
    // Simulate loading notifications from Firestore
    _notifications = [
      'New message from John Doe.',
      'Your profile was viewed by Jane.',
      'A new comment was posted on your photo.',
    ];
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
        child: SafeArea(
          child: Column(
            children: [
              // Display the welcome card only if it hasn't been seen yet
              if (!_hasSeenWelcomeCard)
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Card(
                    color: Colors.tealAccent.withOpacity(0.7),
                    margin: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello ${_username ?? "User"}!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Welcome to our community. If you have any questions or need help, feel free to reach out. The society community is here to work with you!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _hasSeenWelcomeCard = true; // Mark the card as seen
                                });
                              },
                              child: Text(
                                'Dismiss',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 20),
              Text(
                'Welcome, ${_username ?? "User"}!',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.tealAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 20),
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
        ),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Image.asset(
          'assets/logo1.png',
          height: 40,
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
            icon: Icon(Icons.notifications),
            onPressed: () => _showNotifications(context),
          ),
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AccountInfoScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => _signOut(context),
          ),
          // Notification Icon with Dropdown
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> userData) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      color: Colors.black.withOpacity(0.6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: userData['avatarUrl'] != null && userData['avatarUrl'].isNotEmpty
              ? NetworkImage(userData['avatarUrl'])
              : AssetImage('assets/default_avatar.png') as ImageProvider,
          radius: 25,
        ),
        title: Text(
          userData['username'] ?? 'Unknown User',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.tealAccent,
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
            Text(
              userData['status'] ?? 'offline',
              style: TextStyle(color: Colors.tealAccent),
            ),
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
          title: Text('Search for a User', style: TextStyle(color: Colors.tealAccent)),
          content: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Enter username',
              hintStyle: TextStyle(color: Colors.tealAccent),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close', style: TextStyle(color: Colors.tealAccent)),
            ),
          ],
        );
      },
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: Colors.black.withOpacity(0.7),
          child: ListView.builder(
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  _notifications[index],
                  style: TextStyle(color: Colors.tealAccent),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
