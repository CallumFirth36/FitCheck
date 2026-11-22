import 'package:flutter/material.dart';
import 'package:fitcheck/core/app_colours.dart';
import 'package:fitcheck/models/clothing_item.dart';
import 'package:fitcheck/pages/add_item_page.dart';
import 'package:fitcheck/services/wardrobe_service.dart';
import 'package:fitcheck/widgets/clothing_item_card.dart';
import 'package:fitcheck/widgets/gradient_background.dart';

// Shows the user's wardrobe as a list of cards, live from Firestore.
class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  // Created once here, not inside build(), so the page doesn't re-subscribe
  // to Firestore every time it rebuilds.
  late final Stream<List<ClothingItem>> _itemsStream =
      wardrobeService.watchItems();

  // Asks "are you sure?", then deletes the item if the user confirms.
  Future<void> _confirmDelete(ClothingItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${item.name}" from your wardrobe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // Cancelled (or dialog dismissed), so do nothing
    if (confirmed != true) return;

    try {
      await wardrobeService.deleteItem(item.id);
      // No need to refresh: the stream sends the new list by itself
    } catch (e) {
      print(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't delete that item. Please try again."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Your Wardrobe',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textOnDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        // makes the back arrow white
        iconTheme: const IconThemeData(color: AppColors.textOnDark),
      ),

      // The round "+" button in the bottom corner: opens the add-item form
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddItemPage()),
          );
        },
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add),
      ),

      body: GradientBackground(
        child: SafeArea(
          child: StreamBuilder<List<ClothingItem>>(
            stream: _itemsStream,
            builder: (context, snapshot) {
              // 1. Something went wrong (no permission, no connection...)
              if (snapshot.hasError) {
                print(snapshot.error);
                return const _Message(
                  icon: Icons.error_outline,
                  title: "Couldn't load your wardrobe",
                  subtitle: 'Check your connection and try again.',
                );
              }

              // 2. Still waiting for the first batch of data
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              final items = snapshot.data!;

              // 3. Loaded, but nothing in it yet
              if (items.isEmpty) {
                return const _Message(
                  icon: Icons.checkroom,
                  title: 'Your wardrobe is empty',
                  subtitle: 'Items you add will show up here.',
                );
              }

              // 4. Loaded: one card per item
              return ListView.separated(
                // top padding keeps the first card below the app bar
                padding:
                    const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 88),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ClothingItemCard(
                    item: item,
                    onDelete: () => _confirmDelete(item),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// Centred icon + text, used for the empty and error states.
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}