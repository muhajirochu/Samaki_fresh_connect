// Integration tests for fish_search_provider that simulate the real
// Firestore data shape — listings stored with `status='active'` in the
// `fishListings` collection and sellers in the `streetSellers`
// collection. We exercise the actual provider pipeline (without
// Firebase) by overriding `activeListingsProvider` and
// `activeStreetSellersProviderRemote` with canned data.
//
// The previous failure mode — "No sellers have Tuna right now" even
// when sellers exist — was caused by `fishSearchProvider` watching
// `liveSellersProvider` (which only includes sellers that are
// currently `isOnline == true`). These tests pin the fix: search
// must surface any seller whose listing matches, online or offline.
//
// We also pin the second fix: `fishSearchProvider` is now a single
// `StreamProvider` (not a family). Setting `searchQueryProvider`
// re-filters against already-loaded listings+sellers buffers — no
// extra Firestore subscription per query.

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:samakifresh_connect/models/fish_listing_model.dart';
import 'package:samakifresh_connect/models/fish_search_result.dart';
import 'package:samakifresh_connect/models/street_seller_model.dart';
import 'package:samakifresh_connect/providers/fish_search_provider.dart';
import 'package:samakifresh_connect/providers/listing_provider.dart';
import 'package:samakifresh_connect/providers/seller_location_provider.dart';
import 'package:samakifresh_connect/services/location_service.dart';

FishListingModel _listing({
  required String id,
  required String sellerId,
  required String fishType,
  String status = 'active',
  double quantityKg = 5.0,
  DateTime? expiresAt,
}) {
  return FishListingModel(
    listingId: id,
    sellerId: sellerId,
    fishType: fishType,
    quantityKg: quantityKg,
    pricePerKg: 1000,
    totalPrice: quantityKg * 1000,
    imageUrls: const [],
    status: status,
    createdAt: DateTime.now(),
    // Always a fresh, in-window expiry so `listingIsSearchable`
    // accepts the test fixture regardless of the wall-clock date.
    expiresAt: expiresAt ?? DateTime.now().add(const Duration(hours: 24)),
  );
}

StreetSellerModel _seller({
  required String id,
  bool isActive = true,
  bool isOnline = false,
}) {
  return StreetSellerModel(
    sellerId: id,
    fullName: 'Test Seller $id',
    phoneNumber: '+255000000000',
    latitude: -6.20,
    longitude: 39.20,
    isOnline: isOnline,
    isActive: isActive,
    isVerified: true,
    createdAt: DateTime(2026, 7, 3, 12),
    updatedAt: DateTime(2026, 7, 3, 12),
  );
}

const _fallbackLocation = BuyerLocation(
  latitude: -6.20,
  longitude: 39.20,
  source: 'profile',
);

Future<List<FishSearchResult>> _runSearch(
  ProviderContainer container,
  String query,
) async {
  // Set the shared query.
  container.read(searchQueryProvider.notifier).state = query;

  // Wait for the singleton provider to emit at least one tick.
  final sub = container.listen<AsyncValue<List<FishSearchResult>>>(
    fishSearchProvider,
    (_, __) {},
    fireImmediately: true,
  );
  var async = container.read(fishSearchProvider);
  for (var i = 0; i < 200 && !async.hasValue; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 25));
    async = container.read(fishSearchProvider);
  }
  // Give the upstream listeners one more tick to land.
  await Future<void>.delayed(const Duration(milliseconds: 100));
  async = container.read(fishSearchProvider);
  sub.close();
  return async.valueOrNull ?? const [];
}

void main() {
  group('fishSearchProvider integration', () {
    test(
      'returns tuna listings even when the seller is offline',
      () async {
        final container = ProviderContainer(
          overrides: [
            activeListingsProvider.overrideWith(
              (ref) => Stream.value([
                _listing(id: 'l1', sellerId: 's1', fishType: 'tuna'),
              ]),
            ),
            activeStreetSellersProviderRemote.overrideWith(
              (ref) => Stream.value([_seller(id: 's1', isOnline: false)]),
            ),
            currentBuyerLocationProvider
                .overrideWith((ref) async => _fallbackLocation),
          ],
        );
        addTearDown(container.dispose);

        final results = await _runSearch(container, 'tuna');

        expect(results, hasLength(1),
            reason: 'offline-but-registered seller must appear in search');
        expect(results.first.fishType, 'tuna');
        expect(results.first.listings, hasLength(1));
        expect(results.first.listings.first.seller.sellerId, 's1');
        expect(results.first.listings.first.seller.isOnline, isFalse);
      },
    );

    test('returns tuna listings from multiple sellers at once', () async {
      final container = ProviderContainer(
        overrides: [
          activeListingsProvider.overrideWith(
            (ref) => Stream.value([
              _listing(id: 'l1', sellerId: 's1', fishType: 'tuna'),
              _listing(id: 'l2', sellerId: 's2', fishType: 'tuna'),
            ]),
          ),
          activeStreetSellersProviderRemote.overrideWith(
            (ref) => Stream.value([
              _seller(id: 's1', isOnline: false),
              _seller(id: 's2', isOnline: true),
            ]),
          ),
          currentBuyerLocationProvider
              .overrideWith((ref) async => _fallbackLocation),
        ],
      );
      addTearDown(container.dispose);

      final results = await _runSearch(container, 'tuna');
      expect(results, hasLength(1));
      expect(results.first.listings, hasLength(2));
    });

    test('drops listings whose seller is inactive', () async {
      final container = ProviderContainer(
        overrides: [
          activeListingsProvider.overrideWith(
            (ref) => Stream.value([
              _listing(id: 'l1', sellerId: 's1', fishType: 'tuna'),
              _listing(id: 'l2', sellerId: 's2', fishType: 'tuna'),
            ]),
          ),
          activeStreetSellersProviderRemote.overrideWith(
            (ref) => Stream.value([
              _seller(id: 's1', isActive: true, isOnline: false),
              _seller(id: 's2', isActive: false, isOnline: true),
            ]),
          ),
          currentBuyerLocationProvider
              .overrideWith((ref) async => _fallbackLocation),
        ],
      );
      addTearDown(container.dispose);

      final results = await _runSearch(container, 'tuna');
      expect(results.first.listings.map((p) => p.seller.sellerId),
          equals(['s1']));
    });

    test('drops listings whose seller is missing from the sellers map',
        () async {
      final container = ProviderContainer(
        overrides: [
          activeListingsProvider.overrideWith(
            (ref) => Stream.value([
              _listing(id: 'l1', sellerId: 'orphan', fishType: 'tuna'),
            ]),
          ),
          activeStreetSellersProviderRemote.overrideWith(
            (ref) => Stream.value(const <StreetSellerModel>[]),
          ),
          currentBuyerLocationProvider
              .overrideWith((ref) async => _fallbackLocation),
        ],
      );
      addTearDown(container.dispose);

      final results = await _runSearch(container, 'tuna');
      expect(results, isEmpty,
          reason:
              'orphan listings (no matching seller) must not surface');
    });

    test('returns empty list when no listings match', () async {
      final container = ProviderContainer(
        overrides: [
          activeListingsProvider.overrideWith(
            (ref) => Stream.value([
              _listing(id: 'l1', sellerId: 's1', fishType: 'mackerel'),
            ]),
          ),
          activeStreetSellersProviderRemote.overrideWith(
            (ref) => Stream.value([_seller(id: 's1')]),
          ),
          currentBuyerLocationProvider
              .overrideWith((ref) async => _fallbackLocation),
        ],
      );
      addTearDown(container.dispose);

      final results = await _runSearch(container, 'tuna');
      expect(results, isEmpty);
    });

    test('changing the query refilters against already-loaded buffers',
        () async {
      // This test pins the "singleton, not family" architecture:
      // flipping the shared query must NOT create a new Firestore
      // subscription. We can't directly observe Firestore from a
      // unit test, but we can prove the provider emits within one
      // tick of the query flip — no cold-start delay.
      final container = ProviderContainer(
        overrides: [
          activeListingsProvider.overrideWith(
            (ref) => Stream.value([
              _listing(id: 'l1', sellerId: 's1', fishType: 'tuna'),
              _listing(id: 'l2', sellerId: 's1', fishType: 'mackerel'),
            ]),
          ),
          activeStreetSellersProviderRemote.overrideWith(
            (ref) => Stream.value([_seller(id: 's1')]),
          ),
          currentBuyerLocationProvider
              .overrideWith((ref) async => _fallbackLocation),
        ],
      );
      addTearDown(container.dispose);

      // Wait for the first emission so the buffers are warm.
      var async = container.read(fishSearchProvider);
      for (var i = 0; i < 200 && !async.hasValue; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        async = container.read(fishSearchProvider);
      }
      // Empty query → empty results.
      container.read(searchQueryProvider.notifier).state = '';
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(container.read(fishSearchProvider).valueOrNull, isEmpty);

      // Tuna query → tuna result.
      container.read(searchQueryProvider.notifier).state = 'tuna';
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final tuna = container.read(fishSearchProvider).valueOrNull!;
      expect(tuna, hasLength(1));
      expect(tuna.first.fishType, 'tuna');

      // Switch to mackerel — same provider, no fresh subscription.
      container.read(searchQueryProvider.notifier).state = 'mackerel';
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final mackerel = container.read(fishSearchProvider).valueOrNull!;
      expect(mackerel, hasLength(1));
      expect(mackerel.first.fishType, 'mackerel');
    });
  });
}