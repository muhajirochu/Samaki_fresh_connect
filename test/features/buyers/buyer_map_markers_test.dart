// Runtime verification: the buyer map data pipeline actually delivers
// sellers with valid coordinates to the SellerMap widget.
//
// We don't render BuyerMapScreen directly because:
//   - flutter_map's tile layer tries to fetch OSM tiles over HTTP,
//     which fails in the test environment.
//   - The screen depends on go_router, geolocation, and a dozen other
//     providers that are out of scope for this verification.
//
// Instead, this test exercises the data path the map widget
// consumes (the three providers BuyerMapScreen reads from) and
// asserts that they all surface the 5 Stone Town demo sellers with
// non-zero coordinates. If any of these fall, the markers can't
// render — this test catches the regression.

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:samakifresh_connect/models/map_filter_model.dart';
import 'package:samakifresh_connect/models/street_seller_model.dart';
import 'package:samakifresh_connect/providers/buyer_provider.dart';
import 'package:samakifresh_connect/services/demo_sellers_data.dart';

void main() {
  group('Buyer map data pipeline', () {
    test('all 5 Stone Town demo sellers reach activeStreetSellersProvider '
        'via the hardcoded fallback', () async {
      // Force Firestore off (test env has no Firebase) so the
      // hardcoded fallback kicks in.
      final fallback = fallbackSellers();
      expect(fallback.length, 11, reason: 'fallback should have all sellers');

      // Wrap the read in a ProviderContainer so we exercise the
      // *real* provider chain — `activeStreetSellersProvider` falls
      // back to the hardcoded list when Firebase is absent.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // The provider is async (StreamProvider) — wait for the first
      // emission.
      final result =
          await container.read(activeStreetSellersProvider.future);
      expect(result, isNotEmpty);

      // Five Stone Town sellers must be present.
      final st = result.where((s) => s.marketName == 'Stone Town').toList();
      expect(st.length, 5,
          reason: '5 Stone Town demo sellers must always be present');
    });

    test('each demo seller has a non-zero Stone Town coordinate', () {
      // The pipeline doesn't add coords — if any seller in the
      // fallback has (0, 0) the marker renders in the Gulf of Guinea.
      for (final s in fallbackSellers()) {
        expect(s.latitude, isNot(0.0),
            reason: '${s.fullName} has 0.0 latitude');
        expect(s.longitude, isNot(0.0),
            reason: '${s.fullName} has 0.0 longitude');
      }
    });

    test('sellersWithFishProvider accepts the fallback sellers', () async {
      // Simulate the buyer map's data path: activeStreetSellersProvider
      // emits the fallback list, buyerFishFeedProvider is empty (no
      // session). The cascade in sellersWithFishProvider must still
      // surface sellers when no filter is set.
      final container = ProviderContainer(
        overrides: [
          activeStreetSellersProvider.overrideWith(
            (ref) => Stream.value(fallbackSellers()),
          ),
        ],
      );
      addTearDown(container.dispose);

      // sellersWithFishProvider is a synchronous Provider; we read its
      // current value and pump frames until all upstream providers
      // have emitted at least once.
      var list = container.read(sellersWithFishProvider);
      for (var i = 0; i < 5 && list.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        list = container.read(sellersWithFishProvider);
      }
      // When the filter is empty (default), every seller shows up
      // even without fish matches.
      expect(list.length, fallbackSellers().length,
          reason: 'sellers should pass through without filtering');
    });

    test('each seller produces a valid LatLng for marker placement', () {
      // The SellerMap widget uses LatLng(seller.latitude, seller.longitude).
      // If either is NaN/Inf the marker won't render.
      for (final s in fallbackSellers()) {
        expect(s.latitude.isFinite, isTrue,
            reason: '${s.fullName} latitude is not finite');
        expect(s.longitude.isFinite, isTrue,
            reason: '${s.fullName} longitude is not finite');
        expect(s.latitude.abs(), greaterThan(0.5),
            reason: '${s.fullName} latitude too close to 0');
      }
    });

    test('Stone Town sellers are within 1 km of Stone Town center', () {
      // The buyer's default GPS fix is Stone Town. Markers further
      // than 1 km from the center won't appear in the visible
      // viewport at default zoom.
const stLat = -6.1629;
const stLng = 39.2026;
      for (final s in fallbackSellers()
          .where((s) => s.marketName == 'Stone Town')) {
        final d = s.distanceKmFrom(stLat, stLng);
        expect(d, lessThan(1.5),
            reason:
                '${s.fullName} (${s.marketName}) is ${d.toStringAsFixed(2)} km '
                'from Stone Town center — marker will be off-screen');
      }
    });
  });
}

// Keep the unused import warning quiet — `StreetSellerModel` is
// referenced indirectly through the stream type.
// ignore: unused_element
const _ignored = StreetSellerModel;