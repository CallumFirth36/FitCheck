// access to pre-built widgets
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:fitcheck/layouts/auth_layout.dart'; // CHANGED: replaces the three page imports
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,

      // CHANGED: AuthLayout decides what to show.
      // Signed in -> AppNavigationLayout (home + footer)
      // Signed out -> LoginPage
      home: AuthLayout(),
    );
  }
}