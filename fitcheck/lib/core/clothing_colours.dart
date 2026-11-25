import 'package:flutter/material.dart';

// clothing colour
class ClothingColour {
  final String name;
  final Color color;
  const ClothingColour(this.name, this.color);
}

// The fixed list of clothing colours.
class ClothingColours {
  ClothingColours._();

  static const List<ClothingColour> all = [
    ClothingColour('black', Color(0xFF000000)),
    ClothingColour('white', Color(0xFFFFFFFF)),
    ClothingColour('grey', Color(0xFF9E9E9E)),
    ClothingColour('navy', Color(0xFF1F2A44)),
    ClothingColour('blue', Color(0xFF2196F3)),
    ClothingColour('green', Color(0xFF4CAF50)),
    ClothingColour('red', Color(0xFFE53935)),
    ClothingColour('pink', Color(0xFFF48FB1)),
    ClothingColour('yellow', Color(0xFFFDD835)),
    ClothingColour('orange', Color(0xFFFB8C00)),
    ClothingColour('purple', Color(0xFF8E24AA)),
    ClothingColour('brown', Color(0xFF795548)),
    ClothingColour('beige', Color(0xFFD7C4A3)),
  ];


  // Finds the on-screen colour for a stored name.
  static Color colorFor(String name) {
    final wanted = name.toLowerCase().trim();
    for (final c in all) {
      if (c.name == wanted) return c.color;
    }
    return const Color(0xFF9E9E9E); // return grey if cant find colour
  }
}