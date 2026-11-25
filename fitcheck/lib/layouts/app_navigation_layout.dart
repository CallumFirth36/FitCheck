import 'package:flutter/material.dart';
import 'package:fitcheck/core/app_colours.dart';
import 'package:fitcheck/pages/home.dart';
import 'package:fitcheck/pages/account.dart';

// App bottom nav bar
class AppNavigationLayout extends StatefulWidget {
  const AppNavigationLayout({super.key});

  @override
  State<AppNavigationLayout> createState() => _AppNavigationLayoutState();
}

class _AppNavigationLayoutState extends State<AppNavigationLayout> {
  // Which button is selected: 0 = left button, 1 = right button
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),     // left button
    AccountPage(),  // right button
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // The footer has two buttons, left and right
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,

        // When a button is tapped, remember which one and rebuild
        onTap: (index) => setState(() => _currentIndex = index),

        backgroundColor: AppColors.background1,
        selectedItemColor: AppColors.accent,   // active button
        unselectedItemColor: AppColors.hint,   // inactive button

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