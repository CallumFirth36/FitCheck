import 'package:cloud_firestore/cloud_firestore.dart';

// Clothing items used in outfit logic
enum ClothingCategory {
  top,
  midLayer,
  bottom,
  outerwear,
  shoes,
  accessory;


 
  String get label => switch (this) {
        ClothingCategory.top => 'Top',
        ClothingCategory.midLayer => 'Mid layer',
        ClothingCategory.bottom => 'Bottom',
        ClothingCategory.outerwear => 'Outerwear',
        ClothingCategory.shoes => 'Shoes',
        ClothingCategory.accessory => 'Accessory',
      };

  
  // converts name of to category
  static ClothingCategory fromName(String? value) {
    return ClothingCategory.values.firstWhere(
      
      (c) => c.name.toLowerCase() == value?.toLowerCase().trim(),
      orElse: () => ClothingCategory.top,
    );
  }
}

class ClothingItem {
  // Warmth from 1 (cold) - 5 (warm).
  static const int minWarmth = 1;
  static const int maxWarmth = 5;

  final String id; // firestore
  final String name;             
  final ClothingCategory category;
  final String colour;           
  final int warmth;              
  final bool waterproof;
  final DateTime createdAt;

  const ClothingItem({
    this.id = '',
    required this.name,
    required this.category,
    required this.colour,
    required this.warmth,
    required this.waterproof,
    required this.createdAt,
  });

  // Converts item into a map to store in firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category.name,
      'colour': colour,
      'warmth': warmth,
      'waterproof': waterproof,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Converts firestore map to item
  factory ClothingItem.fromMap(String id, Map<String, dynamic> map) {
    return ClothingItem(
      id: id,
      name: (map['name'] as String?) ?? 'Unnamed item',
      category: ClothingCategory.fromName(map['category'] as String?),
      colour: (map['colour'] as String?) ?? '',
      // clamp keeps the number between 1 and 5, even if the AI says 9
      warmth: ((map['warmth'] as num?) ?? 3).toInt().clamp(minWarmth, maxWarmth),
      waterproof: (map['waterproof'] as bool?) ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}