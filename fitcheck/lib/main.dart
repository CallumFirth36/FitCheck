import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:fitcheck/layouts/auth_layout.dart';
import 'package:fitcheck/services/settings_service.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // loads saved setting (text size)
  await settingsService.load();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextSizeOption>(
      valueListenable: settingsService.textSize,
      builder: (context, textSize, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);

            final systemScale = mediaQuery.textScaler.scale(1.0);

            final scale = (systemScale * textSize.scale).clamp(0.8, 2.0).toDouble();

            return MediaQuery(
              data: mediaQuery.copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            );
          },

          home: const AuthLayout(),
        );
      },
    );
  }
}