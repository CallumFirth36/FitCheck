import 'package:cloud_firestore/cloud_firestore.dart';

// The types of clothing the app knows about.
// Using an enum means you can't mistype a category: ClothingCategory.tpo
// would be a red underline, whereas the string 'tpo' would sneak through.
enum ClothingCategory {
  top,
  midLayer,
  bottom,
  outerwear,
  shoes,
  accessory;

  // Nice text for showing on screen: ClothingCategory.top -> "Top"
  // CHANGED: written out in full, because the old shortcut would have shown
  // midLayer as "MidLayer". (A switch must cover every value, so adding a new
  // category later gives a red underline here until you add its label.)
  String get label => switch (this) {
        ClothingCategory.top => 'Top',
        ClothingCategory.midLayer => 'Mid layer',
        ClothingCategory.bottom => 'Bottom',
        ClothingCategory.outerwear => 'Outerwear',
        ClothingCategory.shoes => 'Shoes',
        ClothingCategory.accessory => 'Accessory',
      };

  // Turns the text stored in Firestore (or returned by the AI) back into an
  // enum value. If the text isn't recognised, falls back to "top" so one bad
  // value can never crash the app.
  static ClothingCategory fromName(String? value) {
    return ClothingCategory.values.firstWhere(
      // CHANGED: both sides are lowercased. Before, only the stored text was,
      // so "midLayer" never matched and silently turned back into "top".
      (c) => c.name.toLowerCase() == value?.toLowerCase().trim(),
      orElse: () => ClothingCategory.top,
    );
  }
}

// One item of clothing in the user's wardrobe.
// Every page (wardrobe list, add form, AI scan, outfit logic) uses this
// same class, so they all agree on what a clothing item is.
class ClothingItem {
  // Warmth runs from 1 (very light) to 5 (very warm). Kept here so the form
  // slider and the data checks use the same numbers.
  static const int minWarmth = 1;
  static const int maxWarmth = 5;

  final String id;               // the Firestore document id ('' until saved)
  final String name;             // e.g. "Navy rain jacket"
  final ClothingCategory category;
  final String colour;           // e.g. "navy"
  final int warmth;              // 1 to 5
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

  // Turns this item into a Map that Firestore can store.
  // The id isn't included: Firestore keeps it as the document's name.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category.name, // stored as text, e.g. "outerwear"
      'colour': colour,
      'warmth': warmth,
      'waterproof': waterproof,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Builds an item from a Firestore document (or from the AI's JSON reply).
  // Every field has a safe default, so missing or odd values don't crash.
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