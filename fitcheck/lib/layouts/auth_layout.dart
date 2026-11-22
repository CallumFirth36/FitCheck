import 'package:flutter/material.dart';
import 'package:fitcheck/services/auth_service.dart';
import 'package:fitcheck/pages/app_loading_page.dart';
//import 'package:fitcheck/pages/home.dart';
import 'package:fitcheck/pages/login.dart';
import 'package:fitcheck/layouts/app_navigation_layout.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, this.pageIfNotConnected,});

final Widget? pageIfNotConnected;  // the page to show if the user is not logged in

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: authService,
      builder: (context, authService, child) {
        return StreamBuilder(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            Widget widget;
            if (snapshot.connectionState == ConnectionState.waiting) {
              widget = AppLoadingPage();
            } else if (snapshot.hasData) {
              // user is logged in
              widget = const AppNavigationLayout();
            } else {
              // user is not logged in
              widget = pageIfNotConnected ?? const LoginPage();
            }

            return widget;
          },
        );
      },
    );
  }
}