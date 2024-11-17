import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social_app/views/auth/signup_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  Future<void> _login() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set the background to a gradient similar to fire colors
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Add the fire logo (keeping it as it is in your app)
                Image.asset(
                  'assets/fireLogo.jpg', // Path to your logo image
                  height: 120,
                  width: 120,
                ),
                SizedBox(height: 40),
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 30,
                    color: Colors.orangeAccent, // Change color to fiery orange
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  obscureText: false,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, // Match the fiery color
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5, // Add a subtle shadow for better visibility
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: TextStyle(color: Colors.black),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignupScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.orange, // Match the button color
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.orangeAccent), // Match label color to theme
        enabledBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: Colors.orangeAccent), // Fiery border color
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: Colors.orange), // Focused border with brighter orange
        ),
        filled: true,
        fillColor:
            Colors.orange[50], // Light orange background to match the theme
      ),
      obscureText: obscureText,
    );
  }
}
