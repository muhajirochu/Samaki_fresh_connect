// Tests for the cart model and its providers.
//
// The Firestore layer is not exercised here — `CartService` guards on
// `Firebase.apps.isNotEmpty` and returns empty streams in tests. What
// matters and is testable is the arithmetic the checkout total is
// built from, the serialization round-trip that outlives a legacy
// document, and the provider derivations that drive the nav badge.

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:samakifresh_connect/models/cart_model.dart';
import 'package:samakifresh_connect/providers/cart_provider.dart';

CartItem _item({
  String listingId = 'listing-1',
  double pricePerKg = 5000,
  double quantityKg = 3,
}) {
  return CartItem(
    listingId: listingId,
    sellerId: 'seller-1',
    fishType: 'Sangara',
    pricePerKg: pricePerKg,
    quantityKg: quantityKg,
    addedAt: DateTime(2026, 7, 29, 10),
  );
}

void main() {
  group('CartItem', () {
    test('lineTotal multiplies price by quantity', () {
      expect(_item(pricePerKg: 5000, quantityKg: 3).lineTotal, 15000);
    });

    test('lineTotal handles fractional kg', () {
      expect(_item(pricePerKg: 4000, quantityKg: 2.5).lineTotal, 10000);
    });

    test('copyWith changes only the quantity', () {
      final original = _item(quantityKg: 3);
      final updated = original.copyWith(quantityKg: 7);

      expect(updated.quantityKg, 7);
      expect(updated.listingId, original.listingId);
      expect(updated.pricePerKg, original.pricePerKg);
      expect(updated.addedAt, original.addedAt);
    });

    test('round-trips through toMap / fromMap', () {
      final original = _item();
      final restored = CartItem.fromMap(original.toMap());

      expect(restored.listingId, original.listingId);
      expect(restored.sellerId, original.sellerId);
      expect(restored.fishType, original.fishType);
      expect(restored.pricePerKg, original.pricePerKg);
      expect(restored.quantityKg, original.quantityKg);
      expect(restored.addedAt, original.addedAt);
    });

    test('fromMap prefers the document id over an embedded listingId', () {
      // The doc id is the source of truth — `add()` keys the document
      // on it, so a stale embedded field must not win.
      final restored = CartItem.fromMap(
        _item(listingId: 'stale').toMap(),
        docId: 'real-listing-id',
      );
      expect(restored.listingId, 'real-listing-id');
    });

    test('fromMap tolerates a legacy document with missing fields', () {
      // A row written before a field existed must not crash the cart
      // stream — the same defensive posture WishlistEntry takes.
      final restored = CartItem.fromMap(<String, dynamic>{});

      expect(restored.listingId, '');
      expect(restored.pricePerKg, 0);
      expect(restored.quantityKg, 0);
      expect(restored.imageUrl, isNull);
    });

    test('fromMap parses a Timestamp addedAt', () {
      final when = DateTime(2026, 3, 4, 5, 6);
      final restored = CartItem.fromMap({
        'listingId': 'l1',
        'addedAt': Timestamp.fromDate(when),
      });
      expect(restored.addedAt, when);
    });

    test('fromMap falls back to a parseable string addedAt', () {
      final restored = CartItem.fromMap({
        'listingId': 'l1',
        'addedAt': '2026-03-04T05:06:00.000',
      });
      expect(restored.addedAt, DateTime(2026, 3, 4, 5, 6));
    });
  });

  group('cart providers with no signed-in buyer', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('cartProvider yields an empty list rather than hanging', () async {
      // Session is null in a bare container, so the stream must
      // resolve empty — not stay in a permanent loading state that
      // would leave the Cart tab spinning forever.
      final items = await container.read(cartProvider.future);
      expect(items, isEmpty);
    });

    test('cartCountProvider is 0 and cartTotalProvider is 0', () {
      expect(container.read(cartCountProvider), 0);
      expect(container.read(cartTotalProvider), 0);
    });

    test('mutations are a no-op instead of throwing', () async {
      // Guarding on a null buyerId matters: the Cart tab is reachable
      // during the brief window before the profile doc loads.
      final actions = container.read(cartActionsProvider);
      await expectLater(actions.add(_item()), completes);
      await expectLater(actions.remove('listing-1'), completes);
      await expectLater(actions.updateQuantity('listing-1', 2), completes);
      await expectLater(actions.clear(), completes);
      await expectLater(actions.removeMany(const ['a', 'b']), completes);
    });
  });

  group('cart totals derived from items', () {
    test('sums every line total', () {
      final items = [
        _item(listingId: 'a', pricePerKg: 5000, quantityKg: 2), // 10000
        _item(listingId: 'b', pricePerKg: 3000, quantityKg: 1.5), // 4500
        _item(listingId: 'c', pricePerKg: 8000, quantityKg: 0.5), // 4000
      ];
      final total = items.fold<double>(0, (acc, i) => acc + i.lineTotal);
      expect(total, 18500);
    });
  });
}
