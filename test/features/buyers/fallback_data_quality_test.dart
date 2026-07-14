// Unit test for the hardcoded fallback seller + fish data.
//
// This is the *runtime* counterpart to the static analyzer checks.
// It verifies that:
//   1. The fallback list produces valid data (no nulls, all coords
//      inside Zanzibar),
//   2. Every fish item maps back to a seller in the same list (the
//      buyer's join key works),
//   3. Each seller's distance from Stone Town falls within a
//      plausible range (< 70 km) — no seller accidentally placed
//      outside the archipelago.
//
// If any of these fail, the buyer's map will show sellers but the
// dashboard numbers will be wrong or the markers will be in the
// middle of the ocean.

import 'package:flutter_test/flutter_test.dart';

import 'package:samakifresh_connect/services/demo_sellers_data.dart';

void main() {
  group('fallbackSellers()', () {
    test('returns 11 sellers across Zanzibar', () {
      final sellers = fallbackSellers();
      expect(sellers.length, 11);
    });

    test('every seller has a name, phone, and coords inside Zanzibar', () {
      for (final s in fallbackSellers()) {
        expect(s.fullName, isNotEmpty, reason: '${s.sellerId} missing name');
        expect(s.phoneNumber, isNotEmpty,
            reason: '${s.sellerId} missing phone');
        expect(s.latitude, inInclusiveRange(-7.0, -5.0),
            reason: '${s.fullName} latitude ${s.latitude} outside Zanzibar');
        expect(s.longitude, inInclusiveRange(39.0, 40.0),
            reason: '${s.fullName} longitude ${s.longitude} outside Zanzibar');
        expect(s.isActive, isTrue,
            reason: '${s.fullName} not marked active');
      }
    });

    test('each seller is within 70 km of Stone Town', () {
      const stLat = -6.1629;
      const stLng = 39.2026;
      for (final s in fallbackSellers()) {
        final d = s.distanceKmFrom(stLat, stLng);
        expect(d, lessThanOrEqualTo(70.0),
            reason: '${s.fullName} is ${d.toStringAsFixed(1)} km from Stone Town');
      }
    });

    test('outer-island sellers are visibly further than Stone Town', () {
      const stLat = -6.1629;
      const stLng = 39.2026;
      final st = fallbackSellers().where((s) => s.marketName == 'Stone Town');
      final outer = fallbackSellers()
          .where((s) => s.marketName != 'Stone Town')
          .toList();
      expect(st, isNotEmpty);
      expect(outer, isNotEmpty);

      final avgSt = st
              .map((s) => s.distanceKmFrom(stLat, stLng))
              .reduce((a, b) => a + b) /
          st.length;
      final avgOuter = outer
              .map((s) => s.distanceKmFrom(stLat, stLng))
              .reduce((a, b) => a + b) /
          outer.length;
      expect(avgOuter, greaterThan(avgSt + 5),
          reason:
              'Outer-island sellers should average >5 km further than Stone Town');
    });
  });

  group('fallbackFish()', () {
    test('produces at least 2 fish per seller', () {
      final sellers = fallbackSellers().map((s) => s.sellerId).toSet();
      final fish = fallbackFish();
      for (final id in sellers) {
        final count = fish.where((f) => f.sellerId == id).length;
        expect(count, greaterThanOrEqualTo(2),
            reason: 'seller $id should have at least 2 fish items');
      }
    });

    test('every fish item joins to a seller in the fallback list', () {
      final sellers = fallbackSellers().map((s) => s.sellerId).toSet();
      final fish = fallbackFish();
      for (final f in fish) {
        expect(sellers.contains(f.sellerId), isTrue,
            reason:
                'fish item ${f.itemId} references seller ${f.sellerId} '
                'which is not in fallbackSellers()');
      }
    });

    test('every fish item has positive quantity and price', () {
      for (final f in fallbackFish()) {
        expect(f.quantityKg, greaterThan(0),
            reason: '${f.itemId} has non-positive quantity');
        expect(f.pricePerKg, greaterThan(0),
            reason: '${f.itemId} has non-positive price');
      }
    });
  });
}