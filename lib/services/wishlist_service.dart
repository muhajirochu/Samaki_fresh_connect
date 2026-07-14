// Wishlist CRUD + stream. Subcollection under `users/{buyerId}/wishlist`.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/wishlist_model.dart';
import '../utils/logger.dart';

class WishlistService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  bool get _isAvailable => Firebase.apps.isNotEmpty;

  Stream<List<WishlistEntry>> streamFor(String buyerId) {
    if (!_isAvailable) return Stream.value(const []);
    return _firestore
        .collection('users')
        .doc(buyerId)
        .collection('wishlist')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WishlistEntry.fromMap(d.data(), docId: d.id))
            .toList());
  }

  Future<void> add(String buyerId, WishlistEntry entry) async {
    if (!_isAvailable) return;
    await _firestore
        .collection('users')
        .doc(buyerId)
        .collection('wishlist')
        .doc(entry.id)
        .set(entry.toMap());
    AppLogger.info('Wishlist added: ${entry.id} for $buyerId');
  }

  Future<void> remove(String buyerId, String entryId) async {
    if (!_isAvailable) return;
    await _firestore
        .collection('users')
        .doc(buyerId)
        .collection('wishlist')
        .doc(entryId)
        .delete();
  }

  Future<void> markNotified({
    required String buyerId,
    required String entryId,
    required String listingId,
  }) async {
    if (!_isAvailable) return;
    await _firestore
        .collection('users')
        .doc(buyerId)
        .collection('wishlist')
        .doc(entryId)
        .update({
      'lastNotifiedAt': FieldValue.serverTimestamp(),
      'lastNotifiedListingId': listingId,
    });
  }
}
