import 'package:fitcheck/models/clothing_item.dart';

// finished outfit
class Outfit {
  final ClothingItem? top;
  final ClothingItem? midLayer;
  final ClothingItem? bottom;
  final ClothingItem? shoes;
  final ClothingItem? outerwear;
  final ClothingItem? accessory;
  final List<String> notes;

  const Outfit({
    this.top,
    this.midLayer,
    this.bottom,
    this.shoes,
    this.outerwear,
    this.accessory,
    this.notes = const [],
  });

  // display order
  List<ClothingItem> get items =>
      [outerwear, midLayer, top, bottom, shoes, accessory]
          .whereType<ClothingItem>()
          .toList();

  bool get isEmpty => items.isEmpty;
}