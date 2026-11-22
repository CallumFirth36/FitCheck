import 'package:flutter/material.dart';
import 'package:fitcheck/core/app_colours.dart';

// The white rounded text box used on the login and sign-up pages.
// Written once here, so a change to its look updates every page.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller; // holds what the user types
  final String hint;                      // placeholder text shown when empty
  final bool isPassword;                  // true hides the characters
  final TextInputType? keyboardType;      // e.g. the email keyboard
  final String? Function(String?)? validator; // optional: only used inside a Form

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.inputShadow,
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
        style: const TextStyle(color: AppColors.textOnLight),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.hint),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}