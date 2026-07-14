// Geohash utilities for proximity search.
//
// Why geohash: Firestore does not support native geo radius queries
// (`near`, `within`). The standard workaround — and what
// `geoflutterfire_plus` does under the hood — is to store each seller's
// geohash prefix on their document and query by prefix range. The
// server returns all docs whose geohash shares the prefix; the client
// then refines by Haversine to keep only the actual `radiusKm` circle.
//
// Precision table (geohash base32):
//   1  ≈ 2,500 km    4  ≈ 39 km      7  ≈ 153 m
//   2  ≈ 630  km     5  ≈ 4.8 km     8  ≈ 38 m
//   3  ≈ 78   km     6  ≈ 1.2 km     9  ≈ 4.77 m
//
// Precision 7 is the typical choice for in-city proximity search —
// each cell is roughly a 150 m square, so a 10 km query covers ~64
// neighbor cells and returns ~hundreds-thousands of candidates before
// Haversine refinement.

import 'dart:math' as math;

import 'package:dart_geohash/dart_geohash.dart';

class BoundingBox {
  final double minLat;
  final double minLng;
  final double maxLat;
  final double maxLng;
  const BoundingBox(this.minLat, this.minLng, this.maxLat, this.maxLng);
}

class GeoHashQuery {
  /// The geohash of the search center.
  final String center;
  /// Lower-bound for the `where('geohash', '>=', start)` clause.
  final String start;
  /// Upper-bound for the `where('geohash', '<=', end)` clause.
  final String end;
  /// Whether `end` is inclusive (Firestore string range is inclusive by
  /// default — clients refine with Haversine).
  final bool endInclusive;

  const GeoHashQuery({
    required this.center,
    required this.start,
    required this.end,
    this.endInclusive = false,
  });
}

class GeohashService {
  /// Default precision for proximity searches. 7 chars ≈ 153 m × 153 m
  /// cells, which is a good compromise between precision and the number
  /// of candidate documents we have to fetch + filter.
  static const int defaultPrecision = 7;

  /// Compute the geohash for the given lat/lng.
  /// Geohash expects (longitude, latitude) order — see the source.
  static String encode(double lat, double lng, {int precision = defaultPrecision}) {
    return GeoHasher().encode(lng, lat, precision: precision);
  }

  /// Pretty inverse (used in tests / debugging — production code only
  /// ever writes the encoded form).
  static (double lat, double lng) decode(String geohash) {
    final pair = GeoHasher().decode(geohash);
    return (pair[1], pair[0]); // decode returns [lng, lat]
  }

  /// Bounding box for a center + radius (km). Drives the "all cells whose
  /// prefix covers the circle" math at the chosen precision.
  static BoundingBox boundingBox(
    double centerLat,
    double centerLng,
    double radiusKm,
  ) {
    const earthRadiusKm = 6371.0;
    final latDelta = _deg2rad(radiusKm / earthRadiusKm);
    final lngDelta = _deg2rad(radiusKm / (earthRadiusKm * math.cos(_deg2rad(centerLat))));
    return BoundingBox(
      centerLat - latDelta,
      centerLng - lngDelta,
      centerLat + latDelta,
      centerLng + lngDelta,
    );
  }

  /// Build a single Firestore-compatible query that bounds the search
  /// area. The trick: we ask the server for all docs whose geohash lies
  /// between `start` and `end` of the lexicographic range that intersects
  /// the bounding box at the chosen precision.
  static GeoHashQuery queryBox({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
    int precision = defaultPrecision,
  }) {
    final box = boundingBox(centerLat, centerLng, radiusKm);
    final lower = encode(box.minLat, box.minLng, precision: precision);
    final upper = encode(box.maxLat, box.maxLng, precision: precision);
    final center = encode(centerLat, centerLng, precision: precision);

    // The simple `[lower, upper]` range works when both corners are on
    // the same geohash "side" of the meridian. For a search that crosses
    // the antimeridian we'd need a more elaborate union — out of scope
    // for the Zanzibar initial use case.
    final geohashOrder = lower.compareTo(upper);
    final start = geohashOrder < 0 ? lower : upper;
    final end = geohashOrder < 0 ? upper : lower;

    return GeoHashQuery(
      center: center,
      start: start,
      end: '$end~', // bump so the range covers all longer prefixes too
      endInclusive: true,
    );
  }

  /// Refine the candidate set by Haversine. Used client-side after the
  /// geohash query comes back.
  static bool withinRadius({
    required double queryLat,
    required double queryLng,
    required double candidateLat,
    required double candidateLng,
    required double radiusKm,
  }) {
    final dx = _deg2rad(candidateLng - queryLng) *
        math.cos(_deg2rad((queryLat + candidateLat) / 2));
    final dy = _deg2rad(candidateLat - queryLat);
    // Quick planar approximation is fine for ≤10 km — saves a sqrt.
    final approxKm = math.sqrt(dx * dx + dy * dy) * 6371.0;
    return approxKm <= radiusKm * 1.05; // 5% slop for the planar shortcut
  }

  static double _deg2rad(double d) => d * (math.pi / 180.0);
}
