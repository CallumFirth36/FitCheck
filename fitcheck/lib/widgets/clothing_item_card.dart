import 'package:flutter/material.dart';
import 'package:fitcheck/core/app_colours.dart';
import 'package:fitcheck/core/clothing_colours.dart';
import 'package:fitcheck/models/clothing_item.dart';

// Icon shown for each category. Change them here if you prefer others.
// (An unnamed-style private extension: only usable inside this file.)
extension _CategoryIcon on ClothingCategory {
  IconData get icon {
    switch (this) {
      case ClothingCategory.top:
        return Icons.checkroom;
      case ClothingCategory.midLayer: // CHANGED: new category needs an icon
        return Icons.layers;
      case ClothingCategory.bottom:
        return Icons.accessibility_new;
      case ClothingCategory.outerwear:
        return Icons.dry_cleaning;
      case ClothingCategory.shoes:
        return Icons.hiking;
      case ClothingCategory.accessory:
        return Icons.watch;
    }
  }
}

// A card showing one clothing item: colour swatch with a category icon,
// the name, and the key details. There are no photos, so the swatch
// does the job of showing what the item looks like.
class ClothingItemCard extends StatelessWidget {
  const ClothingItemCard({super.key, required this.item, this.onDelete});

  final ClothingItem item;

  // Optional: if given, a delete icon appears. The page decides what
  // happens (e.g. show a confirmation), the card only reports the tap.
  final VoidCallback? onDelete;

  // "navy" -> "Navy"
  String _capitalise(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

  @override
  Widget build(BuildContext context) {
    final swatch = ClothingColours.colorFor(item.colour);

    // Dark icon on a light swatch, light icon on a dark swatch
    final iconColor =
        ThemeData.estimateBrightnessForColor(swatch) == Brightness.light
            ? Colors.black87
            : Colors.white;

    // Skip the colour part of the subtitle if no colour was saved
    final subtitle = item.colour.isEmpty
        ? item.category.label
        : '${item.category.label} · ${_capitalise(item.colour)}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // white at about 15% opacity, so the gradient shows through
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Colour swatch with the category icon on top
          CircleAvatar(
            radius: 26,
            backgroundColor: swatch,
            child: Icon(item.category.icon, color: iconColor),
          ),
          const SizedBox(width: 14),

          // Name and details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),

                // Warmth and waterproof badges (Wrap moves to a new line
                // instead of overflowing on narrow screens)
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.thermostat,
                            size: 16, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          'Warmth ${item.warmth}/${ClothingItem.maxWarmth}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    if (item.waterproof)
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.water_drop,
                              size: 16, color: Colors.lightBlueAccent),
                          SizedBox(width: 4),
                          Text(
                            'Waterproof',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Delete icon, only shown if the page passed an onDelete
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white70),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}