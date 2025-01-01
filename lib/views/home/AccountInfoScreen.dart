import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data'; // For handling web image data
import 'package:flutter/foundation.dart' show kIsWeb; // To check platform

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

  bool _isEditing = false;
  File? _selectedImageFile; // For mobile
  Uint8List? _selectedImageBytes; // For web
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        final data = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _usernameController.text = data['username'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _currentAvatarUrl = data['avatarUrl'];
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Future<void> _updateUserInfo() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Update username and phone
        await _firestore.collection('users').doc(user.uid).update({
          'username': _usernameController.text.trim(),
          'phone': _phoneController.text.trim(),
        });

        // If a new image is selected, upload and update Firestore
        if (_selectedImageFile != null || _selectedImageBytes != null) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('profile_pictures')
              .child('${user.uid}.jpg');

          if (kIsWeb) {
            // Upload web image bytes
            await ref.putData(_selectedImageBytes!);
          } else {
            // Upload mobile file
            await ref.putFile(_selectedImageFile!);
          }

          final avatarUrl = await ref.getDownloadURL();

          await _firestore.collection('users').doc(user.uid).update({
            'avatarUrl': avatarUrl,
          });

          setState(() {
            _currentAvatarUrl = avatarUrl; // Update the displayed image
            _selectedImageFile = null;
            _selectedImageBytes = null;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account information updated successfully')),
        );
      } catch (e) {
        print("Error updating user info: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update account info')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;

    if (kIsWeb) {
      // Web: Use ImagePicker for web
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageFile = null; // Ensure file is not used
        });
      }
    } else {
      // Mobile: Use ImagePicker for mobile
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _selectedImageBytes = null; // Ensure bytes are not used
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Account Info"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                backgroundImage: _selectedImageBytes != null
                    ? MemoryImage(_selectedImageBytes!)
                    : (_selectedImageFile != null
                            ? FileImage(_selectedImageFile!)
                            : (_currentAvatarUrl != null &&
                                    _currentAvatarUrl!.isNotEmpty
                                ? NetworkImage(_currentAvatarUrl!)
                                : AssetImage('assets/default_avatar.png')))
                        as ImageProvider,
                radius: 50,
              ),
            ),
            SizedBox(height: 20),
            _buildInfoField('Username', _usernameController, _isEditing),
            SizedBox(height: 10),
            _buildInfoField('Email', _emailController, false),
            SizedBox(height: 10),
            _buildInfoField('Phone', _phoneController, _isEditing),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_isEditing) {
                  // Save changes
                  await _updateUserInfo();
                }
                setState(() {
                  _isEditing = !_isEditing; // Toggle edit mode
                });
              },
              child: Text(_isEditing ? 'Save' : 'Edit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(
      String label, TextEditingController controller, bool enabled) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration:
          InputDecoration(labelText: label, border: OutlineInputBorder()),
    );
  }
}
