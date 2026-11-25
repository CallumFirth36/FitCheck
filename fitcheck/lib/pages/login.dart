import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fitcheck/core/app_colours.dart';
import 'package:fitcheck/pages/signup.dart';
import 'package:fitcheck/services/auth_service.dart';
import 'package:fitcheck/widgets/auth_text_field.dart';
import 'package:fitcheck/widgets/gradient_background.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // These hold whatever the user types into each field
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Frees up the controllers' memory when this page is closed
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Shows a short message at the bottom of the screen
  void _showMessage(String message) {
    if (!mounted) return; // page may have closed while we were waiting
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Turns Firebase's error codes into messages a person can understand
  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return "That email address isn't valid.";
      case 'missing-password':
        return 'Please enter your password.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No connection. Check your internet.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  // sign in
  void signIn() async {
    try {
      await authService.value.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      print(e.message);
      _showMessage(_messageFor(e));
    }
  }

  // forgot password
  void forgotPassword() async {
    final email = _emailController.text.trim();

    // Nothing to send the link to yet
    if (email.isEmpty) {
      _showMessage('Enter your email above first.');
      return;
    }

    try {
      await authService.value.resetPassword(email: email);
      // Worded this way so it doesn't reveal whether the email has an account
      _showMessage('If an account exists for that email, a reset link has been sent.');
    } on FirebaseAuthException catch (e) {
      _showMessage(_messageFor(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'FitCheck',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: AppColors.textOnDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: GradientBackground(
        child: SafeArea(
          // scrollable so the keyboard never causes an overflow error
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              children: [
                const SizedBox(height: 80),
                const _LoginHeader(),
                const SizedBox(height: 40),

                // Email field
                AuthTextField(
                  controller: _emailController,
                  hint: 'Enter Your Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // Password field
                AuthTextField(
                  controller: _passwordController,
                  hint: 'Enter Your Password',
                  isPassword: true,
                ),

                // Forgot password link
                TextButton(
                  onPressed: forgotPassword,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Sign In button: runs your signIn function
                SizedBox(
                  width: 250,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: signIn,
                    child: const Text('Sign In', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// login header: title plus the "Sign Up" link
class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Welcome Back!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textOnDark,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Don't have an account?",
              style: TextStyle(color: AppColors.textOnDark),
            ),
            TextButton(
              // CHANGE: opens the sign-up page on top of this one
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignUpPage()),
                );
              },
              child: const Text(
                'Sign Up',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}