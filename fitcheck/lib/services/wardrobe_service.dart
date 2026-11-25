import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitcheck/models/clothing_item.dart';
import 'package:fitcheck/services/auth_service.dart';

final wardrobeService = WardrobeService();

// only page that talks to firestore
class WardrobeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Signed in user ID
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


  // saves new item
  Future<void> addItem(ClothingItem item) async {
    await _items.add(item.toMap());
  }

  // wardrobe page updates itself
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

  // overwite item if already in databse
  Future<void> updateItem(ClothingItem item) async {
    await _items.doc(item.id).update(item.toMap());
  }

  // deletes item
  Future<void> deleteItem(String id) async {
    await _items.doc(id).delete();
  }

  // deletes all items
  Future<void> deleteAllItems() async {
    final snapshot = await _items.get();

    for (var i = 0; i < snapshot.docs.length; i += 400) {
      final batch = _db.batch();
      for (final doc in snapshot.docs.skip(i).take(400)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}