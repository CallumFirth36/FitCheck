import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitcheck/models/clothing_item.dart';
import 'package:fitcheck/services/auth_service.dart';

// One shared instance, used anywhere with: wardrobeService.addItem(...)
// (Plain instance, no .value needed, unlike authService.)
final wardrobeService = WardrobeService();

// Every Firestore call for the wardrobe lives in this class, so pages never
// talk to Firestore directly. Each user's items are stored at:
//   users/{uid}/items/{itemId}
// which matches the security rules you published.
//
// Errors (e.g. no internet, permission denied) are NOT caught here. They pass
// up to the page that called the function, which can show a message
// (same approach as your AuthService).
class WardrobeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // The signed-in user's id. Their wardrobe lives under it, so each user
  // only ever sees their own items.
  String get _uid {
    final user = authService.value.currentUser;
    if (user == null) {
      throw StateError('No user is signed in, so there is no wardrobe to use.');
    }
    return user.uid;
  }

  // Shortcut to this user's "items" collection: users/{uid}/items
  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection('users').doc(_uid).collection('items');

  // ---------------------------------------------------------------
  // ADD: saves a new item. Firestore makes the id for us, which is why
  // the item you pass in can have an empty id.
  // ---------------------------------------------------------------
  Future<void> addItem(ClothingItem item) async {
    await _items.add(item.toMap());
  }

  // ---------------------------------------------------------------
  // WATCH: a live list of the user's items, newest first.
  // It's a Stream, so a StreamBuilder on the wardrobe page updates by itself
  // whenever an item is added, changed or deleted. No refresh needed.
  // ---------------------------------------------------------------
  Stream<List<ClothingItem>> watchItems() {
    return _items
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ClothingItem.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // ---------------------------------------------------------------
  // UPDATE: overwrites an existing item's fields.
  // The item must have its id (items read from watchItems already do).
  // ---------------------------------------------------------------
  Future<void> updateItem(ClothingItem item) async {
    await _items.doc(item.id).update(item.toMap());
  }

  // ---------------------------------------------------------------
  // DELETE: removes the item with this id.
  // ---------------------------------------------------------------
  Future<void> deleteItem(String id) async {
    await _items.doc(id).delete();
  }

  // ---------------------------------------------------------------
  // DELETE ALL: removes every item in the user's wardrobe.
  // Used when an account is deleted, because Firestore does not remove a
  // user's data when their account goes. Must run while still signed in,
  // as the security rules only allow a signed in user to touch their items.
  // ---------------------------------------------------------------
  Future<void> deleteAllItems() async {
    final snapshot = await _items.get();

    // A batch can hold at most 500 writes, so delete in chunks of 400
    for (var i = 0; i < snapshot.docs.length; i += 400) {
      final batch = _db.batch();
      for (final doc in snapshot.docs.skip(i).take(400)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}