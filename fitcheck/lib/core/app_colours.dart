import 'package:flutter/material.dart';

// Collection of colours used in the application
class AppColors {

  AppColors._();

  // Main colours
  static const background1 = Color(0xff2A2438);
  static const background2 = Color(0xff352F44);

  static const primary = Color(0xffDBD8E3);   
  static const accent = Color(0xffF3920A);    

  // Text 
  static const textOnDark = Colors.white;      
  static const textOnLight = Colors.black;     
  static const hint = Colors.grey;             

  // Input fields
  static const inputBackground = Colors.white;
  static const inputBorder = Colors.grey;
  static const inputShadow = Color.fromRGBO(158, 158, 158, 0.5);

  // Gradients (used by GradientBackground)
  static const authGradient = [background1, background2]; 
}