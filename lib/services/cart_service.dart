// Cart CRUD + stream. Subcollection under `users/{buyerId}/cart`.
// Shape mirrors `WishlistService` — same private-subcollection model,
// same `Firebase.apps.isNotEmpty` guard so widget tests that never
// initialise Firebase get an empty stream instead of an exception.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/cart_model.dart';
import '../utils/logger.dart';

class CartService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  bool get _isAvailable => Firebase.apps.isNotEmpty;

  CollectionReference<Map<String, dynamic>> _cartRef(String buyerId) =>
      _firestore.collection('users').doc(buyerId).collection('cart');

  Stream<List<CartItem>> streamFor(String buyerId) {
    if (!_isAvailable || buyerId.isEmpty) return Stream.value(const []);
    return _cartRef(buyerId).snapshots().map(
          (snap) => snap.docs
              .map((d) => CartItem.fromMap(d.data(), docId: d.id))
              .toList()
            // Newest first, so a just-added item is visible without
            // scrolling.
            ..sort((a, b) => b.addedAt.compareTo(a.addedAt)),
        );
  }

  /// Adds an item, or overwrites the quantity if that listing is
  /// already in the cart. Keyed on `listingId`, so this is idempotent
  /// — tapping "add to cart" twice never creates a duplicate row.
  Future<void> add(String buyerId, CartItem item) async {
    if (!_isAvailable || buyerId.isEmpty) return;
    await _cartRef(buyerId).doc(item.listingId).set(item.toMap());
    AppLogger.info('Cart added: ${item.listingId} for $buyerId');
  }

  Future<void> updateQuantity(
    String buyerId,
    String listingId,
    double quantityKg,
  ) async {
    if (!_isAvailable || buyerId.isEmpty) return;
    // Removing at zero keeps the cart free of empty rows, which would
    // otherwise render as "0 kg — TZS 0" lines.
    if (quantityKg <= 0) {
      await remove(buyerId, listingId);
      return;
    }
    await _cartRef(buyerId).doc(listingId).update({'quantityKg': quantityKg});
  }

  Future<void> remove(String buyerId, String listingId) async {
    if (!_isAvailable || buyerId.isEmpty) return;
    await _cartRef(buyerId).doc(listingId).delete();
  }

  /// Empties the cart. Called after a successful checkout.
  ///
  /// Batched rather than looped so a partially-failed clear cannot
  /// leave the buyer with a cart that is half checked-out.
  Future<void> clear(String buyerId) async {
    if (!_isAvailable || buyerId.isEmpty) return;
    final snap = await _cartRef(buyerId).get();
    if (snap.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    AppLogger.info('Cart cleared for $buyerId (${snap.docs.length} items)');
  }

  /// Removes only the listings that were successfully ordered, leaving
  /// anything that failed (sold out, price changed) in the cart so the
  /// buyer can see what did not go through.
  Future<void> removeMany(String buyerId, List<String> listingIds) async {
    if (!_isAvailable || buyerId.isEmpty || listingIds.isEmpty) return;
    final batch = _firestore.batch();
    for (final id in listingIds) {
      batch.delete(_cartRef(buyerId).doc(id));
    }
    await batch.commit();
  }
}
