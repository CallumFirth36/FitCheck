import 'package:flutter/material.dart';
import 'package:fitcheck/core/app_colours.dart';
import 'package:fitcheck/pages/home.dart';
import 'package:fitcheck/pages/account.dart';

// The "shell" shown once the user is logged in.
// It owns the bottom navigation bar (written once, here) and swaps the
// page shown above it when a button is tapped. HomePage and AccountPage
// don't need to know the bar exists.
class AppNavigationLayout extends StatefulWidget {
  const AppNavigationLayout({super.key});

  @override
  State<AppNavigationLayout> createState() => _AppNavigationLayoutState();
}

class _AppNavigationLayoutState extends State<AppNavigationLayout> {
  // Which button is selected: 0 = left button, 1 = right button
  int _currentIndex = 0;

  // The pages, in the same order as the buttons below
  final List<Widget> _pages = const [
    HomePage(),     // left button
    AccountPage(),  // right button
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack shows one page at a time but keeps the others alive,
      // so switching tabs doesn't reset a page (scroll position, text, etc.)
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // The footer: two buttons, left and right
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,

        // When a button is tapped, remember which one and rebuild
        onTap: (index) => setState(() => _currentIndex = index),

        backgroundColor: AppColors.background1,
        selectedItemColor: AppColors.accent,   // the active button
        unselectedItemColor: AppColors.hint,   // the inactive button

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}