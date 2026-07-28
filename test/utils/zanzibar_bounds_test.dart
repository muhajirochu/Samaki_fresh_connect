// Unit tests for [ZanzibarBounds].
//
// Pure-Dart — no Flutter binding required. Covers the canonical
// "Mountain View / (0,0) / NaN" rejection cases that motivated this
// module, plus the standard Zanzibar acceptance points.

import 'package:flutter_test/flutter_test.dart';
import 'package:samakifresh_connect/utils/zanzibar_bounds.dart';

void main() {
  group('ZanzibarBounds.isValidCoord', () {
    test('accepts a normal coord', () {
      expect(ZanzibarBounds.isValidCoord(-6.1629, 39.2026), isTrue);
    });

    test('rejects (0, 0) — the GPS-not-ready sentinel', () {
      expect(ZanzibarBounds.isValidCoord(0.0, 0.0), isFalse);
    });

    test('rejects NaN latitude', () {
      expect(ZanzibarBounds.isValidCoord(double.nan, 39.2026), isFalse);
    });

    test('rejects NaN longitude', () {
      expect(ZanzibarBounds.isValidCoord(-6.1629, double.nan), isFalse);
    });

    test('rejects positive infinity', () {
      expect(ZanzibarBounds.isValidCoord(double.infinity, 39.2026), isFalse);
    });

    test('rejects negative infinity', () {
      expect(ZanzibarBounds.isValidCoord(-6.1629, double.negativeInfinity),
          isFalse);
    });
  });

  group('ZanzibarBounds.isWithinZanzibar', () {
    test('accepts Stone Town (the fallback)', () {
      expect(
        ZanzibarBounds.isWithinZanzibar(
          ZanzibarBounds.stoneTownLat,
          ZanzibarBounds.stoneTownLng,
        ),
        isTrue,
      );
    });

    test('accepts Zanzibar City (Forodhani)', () {
      expect(ZanzibarBounds.isWithinZanzibar(-6.1650, 39.2027), isTrue);
    });

    test('accepts the north tip of Pemba', () {
      expect(ZanzibarBounds.isWithinZanzibar(-4.85, 39.85), isTrue);
    });

    test('accepts Chake-Chake (Pemba)', () {
      expect(ZanzibarBounds.isWithinZanzibar(-5.20, 39.77), isTrue);
    });

    test('accepts Nungwi (northernmost Unguja)', () {
      expect(ZanzibarBounds.isWithinZanzibar(-5.7265, 39.2967), isTrue);
    });

    test('accepts Mchangani (mid-east coast Unguja)', () {
      expect(ZanzibarBounds.isWithinZanzibar(-5.8528, 39.3667), isTrue);
    });

    test('accepts Makunduchi (southernmost Unguja)', () {
      expect(ZanzibarBounds.isWithinZanzibar(-6.3675, 39.5567), isTrue);
    });

    test('accepts the edge of the Unguja box (inclusive)', () {
      expect(
        ZanzibarBounds.isWithinZanzibar(
          ZanzibarBounds.ungujaMinLat,
          ZanzibarBounds.ungujaMinLng,
        ),
        isTrue,
      );
    });

    test('rejects Dar es Salaam (mainland Tanzania)', () {
      expect(ZanzibarBounds.isWithinZanzibar(-6.79, 39.28), isFalse);
    });

    test('rejects Mountain View, CA', () {
      expect(ZanzibarBounds.isWithinZanzibar(37.42, -122.08), isFalse);
    });

    test('rejects the gap between the two islands (open ocean)', () {
      // Lat -5.62 sits between Unguja's north edge (-5.70) and
      // Pemba's south edge (-5.55). Lng 39.7 is in Pemba's lng
      // range. A GPS anchor in the channel could plausibly
      // return this, but it isn't on either island.
      expect(ZanzibarBounds.isWithinZanzibar(-5.62, 39.7), isFalse);
    });

    test('rejects (0, 0)', () {
      expect(ZanzibarBounds.isWithinZanzibar(0.0, 0.0), isFalse);
    });

    test('rejects NaN', () {
      expect(ZanzibarBounds.isWithinZanzibar(double.nan, 39.2026), isFalse);
    });

    test('rejects a point just south of Unguja', () {
      expect(ZanzibarBounds.isWithinZanzibar(-6.51, 39.2026), isFalse);
    });

    test('rejects a point just east of Pemba', () {
      expect(ZanzibarBounds.isWithinZanzibar(-5.20, 39.86), isFalse);
    });
  });

  group('ZanzibarBounds.isValidZanzibarCoord', () {
    test('is an alias for isWithinZanzibar', () {
      expect(
        ZanzibarBounds.isValidZanzibarCoord(
          ZanzibarBounds.stoneTownLat,
          ZanzibarBounds.stoneTownLng,
        ),
        ZanzibarBounds.isWithinZanzibar(
          ZanzibarBounds.stoneTownLat,
          ZanzibarBounds.stoneTownLng,
        ),
      );
      expect(
        ZanzibarBounds.isValidZanzibarCoord(37.42, -122.08),
        ZanzibarBounds.isWithinZanzibar(37.42, -122.08),
      );
    });
  });
}
