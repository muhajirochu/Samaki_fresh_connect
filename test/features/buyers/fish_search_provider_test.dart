// Unit tests for the pure helpers inside the fish-search provider.
//
// The full provider composes three upstream streams and is exercised
// end-to-end by the widget test (`buyer_fish_search_screen_test.dart`).
// Here we test the testable units: query normalization, the
// case-insensitive match against `fishType` + `description`, and the
// haversine distance used for sorting.

import 'package:flutter_test/flutter_test.dart';
import 'package:samakifresh_connect/models/fish_listing_model.dart';
import 'package:samakifresh_connect/models/fish_search_result.dart';
import 'package:samakifresh_connect/models/street_seller_model.dart';
import 'package:samakifresh_connect/providers/fish_search_provider.dart';

FishListingModel _listing({
  required String id,
  required String sellerId,
  required String fishType,
  String? description,
  double qty = 5.0,
  double price = 1000,
}) {
  return FishListingModel(
    listingId: id,
    sellerId: sellerId,
    fishType: fishType,
    quantityKg: qty,
    pricePerKg: price,
    totalPrice: qty * price,
    imageUrls: const [],
    status: 'active',
    description: description,
    createdAt: DateTime(2026, 7, 3, 12),
    expiresAt: DateTime(2026, 7, 4, 12),
  );
}

StreetSellerModel _seller({
  required String id,
  String name = 'Test Seller',
  double lat = -6.20,
  double lng = 39.20,
  bool isOnline = false,
}) {
  return StreetSellerModel(
    sellerId: id,
    fullName: name,
    phoneNumber: '+255000000000',
    latitude: lat,
    longitude: lng,
    isOnline: isOnline,
    isActive: true,
    isVerified: true,
    createdAt: DateTime(2026, 7, 3, 12),
    updatedAt: DateTime(2026, 7, 3, 12),
  );
}

void main() {
  group('normalizeSearchQuery', () {
    test('returns null for an empty query', () {
      expect(normalizeSearchQuery(''), isNull);
      expect(normalizeSearchQuery('   '), isNull);
    });

    test('trims and lowercases', () {
      expect(normalizeSearchQuery('  Tuna  '), 'tuna');
      expect(normalizeSearchQuery('FILLET'), 'fillet');
    });
  });

  group('listingMatchesSearchQuery', () {
    test('matches against fishType case-insensitively', () {
      final l = _listing(
        id: '1',
        sellerId: 's1',
        fishType: 'Tuna',
      );
      // `q` is expected to be already lowercased (the caller is
      // `normalizeSearchQuery`).
      expect(listingMatchesSearchQuery(l, 'tuna'), isTrue);
      expect(listingMatchesSearchQuery(l, 'un'), isTrue);
      expect(listingMatchesSearchQuery(l, 'tun'), isTrue);
    });

    test('matches against description text', () {
      final l = _listing(
        id: '1',
        sellerId: 's1',
        fishType: 'Other',
        description: 'Large fresh fillet',
      );
      expect(listingMatchesSearchQuery(l, 'fillet'), isTrue);
      expect(listingMatchesSearchQuery(l, 'fresh'), isTrue);
    });

    test('returns false when neither field matches', () {
      final l = _listing(
        id: '1',
        sellerId: 's1',
        fishType: 'Tuna',
        description: 'Fresh catch',
      );
      expect(listingMatchesSearchQuery(l, 'mackerel'), isFalse);
    });

    test('handles listings with no description gracefully', () {
      final l = _listing(id: '1', sellerId: 's1', fishType: 'Tuna');
      // Should not throw on null description.
      expect(() => listingMatchesSearchQuery(l, 'mackerel'), returnsNormally);
    });
  });

  group('haversineKm', () {
    test('returns 0 for the same point', () {
      expect(haversineKm(-6.20, 39.20, -6.20, 39.20), 0.0);
    });

    test('returns a small value for nearby points (~1 km)', () {
      // 0.01 degree latitude ≈ 1.11 km.
      final km = haversineKm(-6.20, 39.20, -6.21, 39.20);
      expect(km, closeTo(1.11, 0.05));
    });

    test('is symmetric', () {
      final a = haversineKm(-6.20, 39.20, -6.30, 39.30);
      final b = haversineKm(-6.30, 39.30, -6.20, 39.20);
      expect(a, closeTo(b, 0.0001));
    });
  });

  group('FishSearchResult aggregation', () {
    test('anyOnline reflects the underlying sellers', () {
      final s1 = _seller(id: 's1', isOnline: true);
      final s2 = _seller(id: 's2', isOnline: false);
      final result = FishSearchResult(
        fishType: 'tuna',
        displayName: 'Tuna',
        listings: [
          FishListingWithSeller(
            listing: _listing(id: 'l1', sellerId: 's1', fishType: 'tuna'),
            seller: s1,
            distanceKm: 0.5,
          ),
          FishListingWithSeller(
            listing: _listing(id: 'l2', sellerId: 's2', fishType: 'tuna'),
            seller: s2,
            distanceKm: 1.5,
          ),
        ],
      );
      expect(result.anyOnline, isTrue);
      expect(result.closestDistanceKm, 0.5);
      expect(result.listingCount, 2);
    });

    test('min/max price reflects every listing', () {
      final s = _seller(id: 's1');
      final result = FishSearchResult(
        fishType: 'tuna',
        displayName: 'Tuna',
        listings: [
          FishListingWithSeller(
            listing: _listing(
              id: 'l1', sellerId: 's1', fishType: 'tuna', price: 1500,
            ),
            seller: s,
            distanceKm: 1.0,
          ),
          FishListingWithSeller(
            listing: _listing(
              id: 'l2', sellerId: 's1', fishType: 'tuna', price: 2000,
            ),
            seller: s,
            distanceKm: 2.0,
          ),
        ],
      );
      expect(result.minPricePerKg, 1500);
      expect(result.maxPricePerKg, 2000);
      expect(result.totalKgAvailable, 10.0);
    });
  });
}
