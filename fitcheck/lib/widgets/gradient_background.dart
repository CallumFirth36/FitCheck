import 'package:flutter/material.dart';
import 'package:fitcheck/core/app_colours.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.colours = AppColors.authGradient, // default to auth gradient
  });

  final Widget child;  // the content to display on top of the gradient
  final List<Color> colours; // gradient colours

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colours,
        ),
      ),
      child: child,
    );
  }
}