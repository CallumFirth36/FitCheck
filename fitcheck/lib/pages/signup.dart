import 'package:flutter/material.dart';
import 'package:fitcheck/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcheck/pages/home.dart'; // CHANGE: needed so popPage() can open HomePage
import 'package:fitcheck/widgets/gradient_background.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Used to run the validators on the email and password fields
  final _formKey = GlobalKey<FormState>();

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

  // ---------------------------------------------------------------
  // Your register function.
  // 1. Sends the email and password to Firebase to create the account.
  // 2. If that works, Firebase also signs the new user in automatically.
  // 3. popPage() then closes this page (see below).
  // 4. If Firebase rejects it (email already used, bad email, etc.)
  //    the error message is printed to the debug console.
  // ---------------------------------------------------------------
  void register() async{
    try {
      await authService.value.signUp(email: _emailController.text.trim(), password: _passwordController.text);
      popPage(); // CHANGE: this line was commented out, now it runs after a successful sign-up
    } on FirebaseAuthException catch (e) {
      print(e.message);
    }

    

   
  }

   // ---------------------------------------------------------------
  // popPage: closes the sign-up page. AuthLayout (the first screen) then
  // shows AppNavigationLayout by itself, because the new account is
  // already signed in.
  // ---------------------------------------------------------------
  void popPage() {
    if (!mounted) return;

    // Keeps closing pages until only the first screen (AuthLayout) is left
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ---------------------------------------------------------------
  // Runs when "Create Account" is pressed.
  // CHANGE: this used to show a test snackbar. Now it checks the form
  // and, if it's valid, calls your register() function.
  // ---------------------------------------------------------------
  void _submit() {
    // If any validator fails, the error shows under the field and we stop
    if (!_formKey.currentState!.validate()) return;

    // Form is valid, so create the account
    register();
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
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GradientBackground(
        
        child: SafeArea(
          // scrollable so the keyboard never causes an overflow error
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 30),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  const _SignUpHeader(),
                  const SizedBox(height: 40),

                  // Email field
                  _inputField(
                    controller: _emailController,
                    hint: 'Enter Your Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Please enter your email';
                      if (!text.contains('@') || !text.contains('.')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password field
                  _inputField(
                    controller: _passwordController,
                    hint: 'Create A Password',
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // Create Account button: runs _submit when pressed
                  SizedBox(
                    width: 250,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text(
                        'Create Account',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // input field widget (same look as the login page)
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(158, 158, 158, 0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}

// sign up header
class _SignUpHeader extends StatelessWidget {
  const _SignUpHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Already have an account?',
              style: TextStyle(color: Colors.white),
            ),
            // "Sign In" link: goes back to the login page
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Sign In',
                style: TextStyle(
                  color: Color.fromARGB(255, 243, 184, 33),
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