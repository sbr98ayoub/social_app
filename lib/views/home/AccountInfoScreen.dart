import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountInfoScreen extends StatefulWidget {
  @override
  _AccountInfoScreenState createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isEditing = false;

  Future<Map<String, dynamic>> _getUserInfo() async {
    final user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      return userDoc.data() as Map<String, dynamic>;
    }
    return {};
  }

  Future<void> _updateUserInfo(String field, String value) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({field: value});
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Image.asset(
          'assets/fireLogo.jpg',
          height: 80, // Make the logo bigger
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error loading account info.'));
          }

          final userData = snapshot.data!;
          _usernameController.text = userData['username'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Center the avatar
                  Center(
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(userData['avatarUrl'] ?? ''),
                      radius: 50,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Display user info
                  _buildInfoField(label: 'Username', controller: _usernameController, enabled: _isEditing),
                  SizedBox(height: 10),
                  _buildInfoField(label: 'Email', controller: _emailController, enabled: false),
                  SizedBox(height: 10),
                  _buildInfoField(label: 'Phone', controller: _phoneController, enabled: _isEditing),
                  SizedBox(height: 20),

                  // Password field and Confirm Password field only available when editing
                  if (_isEditing) ...[
                    _buildInfoField(
                      label: 'New Password',
                      controller: _passwordController,
                      enabled: _isEditing,
                      obscureText: true,
                    ),
                    SizedBox(height: 10),
                    _buildInfoField(
                      label: 'Confirm Password',
                      controller: _confirmPasswordController,
                      enabled: _isEditing,
                      obscureText: true,
                    ),
                  ],
                  
                  // Edit/Save buttons beneath
                  SizedBox(height: 20), // Space before buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isEditing = !_isEditing;
                          });
                          if (!_isEditing) {
                            _updateUserInfo('username', _usernameController.text);
                            _updateUserInfo('phone', _phoneController.text);
                            if (_passwordController.text.isNotEmpty && _passwordController.text == _confirmPasswordController.text) {
                              _auth.currentUser?.updatePassword(_passwordController.text);
                            } else {
                              // Show an error if passwords don't match
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Passwords don't match")));
                            }
                          }
                        },
                        icon: Icon(_isEditing ? Icons.save : Icons.edit),
                        label: Text(_isEditing ? 'Save' : 'Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isEditing ? Colors.green : Colors.orange,
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _auth.signOut();
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.exit_to_app),
                        label: Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }
}
