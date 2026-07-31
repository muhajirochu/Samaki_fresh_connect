// A buyer's shopping cart — listings they intend to order, held until
// they check out. Persisted under `users/{buyerId}/cart/{listingId}`,
// mirroring the private-subcollection shape already used by
// `users/{buyerId}/wishlist` (see `wishlist_model.dart`).
//
// Keying the document on `listingId` makes "add to cart" idempotent:
// tapping add twice updates the quantity instead of creating a second
// row, and removal never needs a query.
//
// The cart snapshots `fishType`, `pricePerKg` and `imageUrl` off the
// listing at add-time. That is deliberate: it keeps the cart readable
// without an N-way join against `fishListings`, and it lets the UI
// show what the buyer *thought* they were buying. `CartScreen`
// re-reads the live listing at checkout, so a stale snapshot can never
// turn into a wrongly-priced order.

import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  /// Firestore document id — always the listing id.
  final String listingId;
  final String sellerId;

  /// Snapshot of the listing at the time it was added to the cart.
  final String fishType;
  final double pricePerKg;
  final String? imageUrl;

  /// How much the buyer wants. Independent of the listing's available
  /// `quantityKg`, which is re-checked at checkout.
  final double quantityKg;

  final DateTime addedAt;

  const CartItem({
    required this.listingId,
    required this.sellerId,
    required this.fishType,
    required this.pricePerKg,
    required this.quantityKg,
    required this.addedAt,
    this.imageUrl,
  });

  /// Line total for this row, using the snapshotted price.
  double get lineTotal => pricePerKg * quantityKg;

  CartItem copyWith({double? quantityKg}) {
    return CartItem(
      listingId: listingId,
      sellerId: sellerId,
      fishType: fishType,
      pricePerKg: pricePerKg,
      quantityKg: quantityKg ?? this.quantityKg,
      addedAt: addedAt,
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toMap() => {
        'listingId': listingId,
        'sellerId': sellerId,
        'fishType': fishType,
        'pricePerKg': pricePerKg,
        'quantityKg': quantityKg,
        'imageUrl': imageUrl,
        'addedAt': Timestamp.fromDate(addedAt),
      };

  factory CartItem.fromMap(Map<String, dynamic> data, {String? docId}) {
    return CartItem(
      listingId: docId ?? (data['listingId'] as String? ?? ''),
      sellerId: data['sellerId'] as String? ?? '',
      fishType: data['fishType'] as String? ?? '',
      pricePerKg: (data['pricePerKg'] as num?)?.toDouble() ?? 0,
      quantityKg: (data['quantityKg'] as num?)?.toDouble() ?? 0,
      imageUrl: data['imageUrl'] as String?,
      // Same defensive parse as WishlistEntry: tolerate a legacy row
      // that stored a string, and never crash the cart stream on one
      // bad document.
      addedAt: data['addedAt'] is Timestamp
          ? (data['addedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['addedAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}
