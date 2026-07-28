// Zanzibar-only GPS bounds.
//
// The app is a Zanzibar fish marketplace — every coordinate the user
// sees, every coordinate we write to Firestore, must be inside one of
// the two islands (Unguja or Pemba). Anything else is treated as a
// bad fix and rejected, so a device whose GPS thinks it's in Mountain
// View (or anywhere outside Zanzibar) silently falls back to the
// buyer's saved profile, then to Stone Town.
//
// This module is pure-Dart (no `geolocator`, no Flutter) so it can be
// unit-tested in isolation. All bounds are inclusive — a point on a
// box edge is considered inside Zanzibar.

class ZanzibarBounds {
  // ── Unguja (main island) ───────────────────────────────────────────
  // Lat range derived from the seller fleet already in production:
  // Nungwi sits at the northern tip (~-5.73) and Makunduchi /
  // Jambiani at the southern end (~-6.37). Lng range spans Fumba
  // (~39.13) on the west coast to the east-coast dive beaches
  // (~39.55).
  static const double ungujaMinLat = -6.50;
  static const double ungujaMaxLat = -5.70;
  static const double ungujaMinLng = 39.10;
  static const double ungujaMaxLng = 39.60;

  // ── Pemba (smaller island, ~50 km north of Unguja) ─────────────────
  // Chake-Chake sits at (-5.20, 39.77); the island's southern coast
  // is around -5.55 and the northern tip around -4.85. East/west
  // spans are roughly 39.60..39.85 — anything beyond 39.85 is open
  // Indian Ocean.
  static const double pembaMinLat = -5.55;
  static const double pembaMaxLat = -4.85;
  static const double pembaMinLng = 39.60;
  static const double pembaMaxLng = 39.85;

  // ── Last-resort fallback for buyers / listings ─────────────────────
  // Surfaces as "Stone Town" on the map. Used both by the buyer
  // location service and the listing-create coord resolver so the two
  // share a single source of truth.
  static const double stoneTownLat = -6.1629;
  static const double stoneTownLng = 39.2026;

  /// Reject degenerate coordinates: NaN, ±Infinity, and the canonical
  /// GPS-not-ready sentinel of (0, 0). Use this before any bounds check
  /// so a `null`/`empty` fix can't sneak through.
  static bool isValidCoord(double lat, double lng) {
    if (lat.isNaN || lng.isNaN) return false;
    if (lat.isInfinite || lng.isInfinite) return false;
    if (lat == 0.0 && lng == 0.0) return false;
    return true;
  }

  /// True iff `(lat, lng)` is inside Unguja OR inside Pemba.
  /// Inclusive on all four edges of each box.
  static bool isWithinZanzibar(double lat, double lng) {
    if (!isValidCoord(lat, lng)) return false;
    final inUnguja = lat >= ungujaMinLat &&
        lat <= ungujaMaxLat &&
        lng >= ungujaMinLng &&
        lng <= ungujaMaxLng;
    final inPemba = lat >= pembaMinLat &&
        lat <= pembaMaxLat &&
        lng >= pembaMinLng &&
        lng <= pembaMaxLng;
    return inUnguja || inPemba;
  }

  /// Read-name alias for [isWithinZanzibar]. Prefer this at call sites
  /// that read like "is this a valid Zanzibar coord?" — the predicate
  /// already implies the bounds check.
  static bool isValidZanzibarCoord(double lat, double lng) =>
      isWithinZanzibar(lat, lng);
}
