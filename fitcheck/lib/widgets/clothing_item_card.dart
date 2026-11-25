import 'package:flutter/material.dart';
import 'package:fitcheck/core/app_colours.dart';
import 'package:fitcheck/core/clothing_colours.dart';
import 'package:fitcheck/models/clothing_item.dart';

// Icon for categories
extension _CategoryIcon on ClothingCategory {
  IconData get icon {
    switch (this) {
      case ClothingCategory.top:
        return Icons.checkroom;
      case ClothingCategory.midLayer:
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

// clothing item card
class ClothingItemCard extends StatelessWidget {
  const ClothingItemCard({super.key, required this.item, this.onDelete});

  final ClothingItem item;

  final VoidCallback? onDelete;

  String _capitalise(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

  @override
  Widget build(BuildContext context) {
    final swatch = ClothingColours.colorFor(item.colour);

    final iconColor =
        ThemeData.estimateBrightnessForColor(swatch) == Brightness.light
            ? Colors.black87
            : Colors.white;

    final subtitle = item.colour.isEmpty
        ? item.category.label
        : '${item.category.label} · ${_capitalise(item.colour)}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
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

          // Delete icon
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