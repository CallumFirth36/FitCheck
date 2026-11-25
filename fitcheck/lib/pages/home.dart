import 'package:flutter/material.dart';
import 'package:fitcheck/widgets/gradient_background.dart';
import 'package:fitcheck/core/app_colours.dart';
import 'package:fitcheck/pages/wardrobe_page.dart';
import 'package:fitcheck/pages/outfit_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // allows the background gradient to extend behind the app bar
      extendBodyBehindAppBar: true,


      // App Bar
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

      // Body 
      body: GradientBackground(

        child: Padding(
          padding: const EdgeInsets.only(top: 115, bottom: 105),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Welcome to FitCheck',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    color: AppColors.textOnDark,
                  ),
                ),
              ),

              
              const Spacer(),

              SizedBox(
                width: 250,
                height: 75,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WardrobePage()),
                    );
                  },
                  child: const Text('Your Wardrobe', style: TextStyle(fontSize: 18)),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: 250,
                height: 75,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OutfitPage()),
                    );
                  },
                  child: const Text('Create Outfits', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
      
    );
  }
}