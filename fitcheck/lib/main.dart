// access to pre-built widgets
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

  // Loads the saved settings (text size) before the first screen is drawn,
  // so the app never flashes up at the wrong size.
  await settingsService.load();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app whenever the text size setting changes.
    return ValueListenableBuilder<TextSizeOption>(
      valueListenable: settingsService.textSize,
      builder: (context, textSize, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          // builder wraps every screen, so this one place sets the text size
          // for the whole app and no page needs to change.
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);

            // the phone's own text size setting (1.0 if it hasn't been changed)
            final systemScale = mediaQuery.textScaler.scale(1.0);

            // the in-app choice stacks on top of it, capped so a large phone
            // setting plus Extra large can't break the layouts
            final scale = (systemScale * textSize.scale).clamp(0.8, 2.0).toDouble();

            return MediaQuery(
              data: mediaQuery.copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            );
          },

          // AuthLayout decides what to show:
          // signed in -> AppNavigationLayout, signed out -> LoginPage
          home: const AuthLayout(),
        );
      },
    );
  }
}