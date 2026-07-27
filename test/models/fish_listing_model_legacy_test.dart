// Regression tests for legacy / partial Firestore documents.
//
// `fishListings/{id}` rows created before some fields were added
// don't carry every required key. The previous model used `required`
// for `listingId` / `sellerId` / `createdAt` / `expiresAt`, which made
// fromJson throw on the first such document — and since the listing
// service maps the entire snapshot at once, one bad row killed the
// whole marketplace stream. The user-visible symptom was "Failed to
// load listings" rendered permanently.
//
// These tests pin the tolerant-deserialization contract so a single
// legacy row can no longer take the marketplace down.

import 'package:flutter_test/flutter_test.dart';
import 'package:samakifresh_connect/models/fish_listing_model.dart';

void main() {
  group('FishListingModel.fromJson — legacy / partial docs', () {
    test('completely empty doc deserializes without throwing', () {
      // The first commit of the marketplace predated the schema
      // entirely — see this in seed data on real Firebase projects.
      final listing = FishListingModel.fromJson(const <String, dynamic>{});
      expect(listing.listingId, '');
      expect(listing.sellerId, '');
      expect(listing.status, 'active');
      expect(listing.quantityKg, 0.0);
      expect(listing.pricePerKg, 0.0);
      expect(listing.totalPrice, 0.0);
      expect(listing.imageUrls, isEmpty);
      expect(listing.createdAt, isNull);
      expect(listing.expiresAt, isNull);
    });

    test('doc missing only createdAt+expiresAt still loads', () {
      // Typical legacy row — has identity / pricing fields but no
      // timestamps because the timestamps landed in a later release.
      final listing = FishListingModel.fromJson(<String, dynamic>{
        'listingId': 'legacy-1',
        'sellerId': 'seller-9',
        'fishType': 'tuna',
        'quantityKg': 5,
        'pricePerKg': 4500,
        'totalPrice': 22500,
        'imageUrls': <String>[],
        'status': 'active',
      });
      expect(listing.listingId, 'legacy-1');
      expect(listing.sellerId, 'seller-9');
      expect(listing.quantityKg, 5.0);
      expect(listing.createdAt, isNull);
      expect(listing.expiresAt, isNull);
    });

    test('doc with proper timestamps loads and exposes them', () {
      final listing = FishListingModel.fromJson(<String, dynamic>{
        'listingId': 'fresh-1',
        'sellerId': 'seller-9',
        'fishType': 'tuna',
        'quantityKg': 5,
        'pricePerKg': 4500,
        'totalPrice': 22500,
        'imageUrls': <String>[],
        'status': 'active',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'expiresAt': '2026-01-08T00:00:00.000Z',
      });
      expect(listing.createdAt, isNotNull);
      expect(listing.expiresAt, isNotNull);
      expect(listing.expiresAt!.year, 2026);
    });
  });
}