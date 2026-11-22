import 'package:fitcheck/models/clothing_item.dart';

// The result of the outfit logic: which item (if any) was picked for each
// slot, plus plain-English reasons explaining the choices.
class Outfit {
  final ClothingItem? top;
  final ClothingItem? midLayer;    // CHANGED: hoodie/jumper, only picked when it's cold
  final ClothingItem? bottom;
  final ClothingItem? shoes;
  final ClothingItem? outerwear;   // only picked when the weather calls for it
  final ClothingItem? accessory;   // only picked when it's cold
  final List<String> notes;        // the "why this outfit" explanations

  const Outfit({
    this.top,
    this.midLayer, // CHANGED: new slot
    this.bottom,
    this.shoes,
    this.outerwear,
    this.accessory,
    this.notes = const [],
  });

  // The picked items in the order they'd be shown, skipping empty slots.
  // whereType<ClothingItem>() drops the nulls.
  // CHANGED: midLayer added, between the outer layer and the top.
  List<ClothingItem> get items =>
      [outerwear, midLayer, top, bottom, shoes, accessory]
          .whereType<ClothingItem>()
          .toList();

  bool get isEmpty => items.isEmpty;
}