// Street-seller model surfaced to the Buyer Dashboard.
//
// Note: a "street seller" in this app is also a registered user with role
// UserRole.streetSeller. This class is the *view* of that user as a seller —
// the data the buyer needs (location, name, contact) — not the auth record.

import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/timestamp_converter.dart';

class StreetSellerModel {
  final String sellerId;
  final String fullName;
  final String phoneNumber;
  final String? profilePictureUrl;

  // ── Location (the buyer needs this to compute "nearby") ────────────────────
  final double latitude;
  final double longitude;
  /// Base32 geohash at precision 9 — ~4.77 m × 4.77 m cell, used by the
  /// geo-query for fast server-side prefix filtering before the buyer
  /// refines with Haversine.
  final String? geohash;
  final String? marketName;
  final String? regionName;
  final String? streetName;

  // ── Live-presence signals ──────────────────────────────────────────────────
  /// Set to `true` while the seller's `SellerLocationTracker` is actively
  /// streaming GPS into Firestore. Drives the green "online" dot in the UI.
  final bool isOnline;
  /// Most recent direction of travel, degrees clockwise from north.
  final double? headingDegrees;
  /// Instantaneous ground speed in m/s when the last fix was taken.
  final double? speedMps;
  /// Accuracy radius in meters reported by the OS at the last fix.
  final double? accuracyMeters;
  /// When the last GPS fix was written to Firestore. Null for sellers
  /// who have never come online through the tracker.
  final DateTime? lastLocationUpdateAt;

  // ── Buyer-facing trust signals ─────────────────────────────────────────────
  final bool isActive;
  final bool isVerified; // admin-verified seller
  final double averageRating;
  final int totalRatings;
  final int totalOrders;

  final DateTime createdAt;
  final DateTime updatedAt;

  const StreetSellerModel({
    required this.sellerId,
    required this.fullName,
    required this.phoneNumber,
    this.profilePictureUrl,
    required this.latitude,
    required this.longitude,
    this.geohash,
    this.marketName,
    this.regionName,
    this.streetName,
    this.isOnline = false,
    this.headingDegrees,
    this.speedMps,
    this.accuracyMeters,
    this.lastLocationUpdateAt,
    this.isActive = true,
    this.isVerified = false,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.totalOrders = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Haversine distance in km from a buyer location. Cheap, accurate enough
  /// for "nearby" filtering (good to ~0.5% over typical Zanzibar distances).
  double distanceKmFrom(double buyerLat, double buyerLng) {
    const earthRadiusKm = 6371.0;
    final dLat = _deg2rad(latitude - buyerLat);
    final dLng = _deg2rad(longitude - buyerLng);
    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_deg2rad(buyerLat)) *
            math.cos(_deg2rad(latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180.0);

  factory StreetSellerModel.fromMap(
    Map<String, dynamic> data, {
    String? docId,
  }) {
    // ── Location ────────────────────────────────────────────────────────────
    // The model accepts three shapes so we can co-exist with both the
    // legacy flat lat/lng fields and the new GeoPoint + nested location map:
    //
    //   1. Modern preferred shape:
    //        location = { latitude, longitude, geohash }
    //      plus top-level: latitude, longitude, geohash (denormalized for
    //      single-field geo queries).
    //
    //   2. Firestore GeoPoint stored under `location.geo`.
    //
    //   3. Legacy: flat `latitude` / `longitude` only.

    double lat = 0.0;
    double lng = 0.0;
    String? geo;

    // 1) flat top-level takes precedence
    final flatLat = (data['latitude'] as num?)?.toDouble();
    final flatLng = (data['longitude'] as num?)?.toDouble();
    if (flatLat != null && flatLng != null) {
      lat = flatLat;
      lng = flatLng;
    }

    // 2) nested `location` map override
    if (data['location'] is Map) {
      final loc = data['location'] as Map<String, dynamic>;
      if (loc['latitude'] is num) lat = (loc['latitude'] as num).toDouble();
      if (loc['longitude'] is num) lng = (loc['longitude'] as num).toDouble();
      if (loc['geohash'] is String) geo = loc['geohash'] as String;
      // 3) Firestore `GeoPoint` form
      if (loc['geo'] is GeoPoint) {
        final gp = loc['geo'] as GeoPoint;
        lat = gp.latitude;
        lng = gp.longitude;
      }
    }

    // 4) Firestore `GeoPoint` at top-level
    if (data['geo'] is GeoPoint) {
      final gp = data['geo'] as GeoPoint;
      lat = gp.latitude;
      lng = gp.longitude;
    }

    geo ??= data['geohash'] as String?;

    // ── Online + heading / speed ───────────────────────────────────────────
    final heading = (data['heading'] as num?)?.toDouble();
    final speed = (data['speed'] as num?)?.toDouble();
    final accuracy = (data['locationAccuracy'] as num?)?.toDouble();
    DateTime? lastFix;
    if (data['lastLocationUpdateAt'] != null) {
      lastFix = const OptionalTimestampConverter()
          .fromJson(data['lastLocationUpdateAt']);
    }

    return StreetSellerModel(
      sellerId: docId ?? (data['sellerId'] as String? ?? ''),
      fullName: (data['fullName'] as String?) ?? '',
      phoneNumber: (data['phoneNumber'] as String?) ?? '',
      profilePictureUrl: data['profilePictureUrl'] as String?,
      latitude: lat,
      longitude: lng,
      geohash: geo,
      marketName: data['marketName'] as String?,
      regionName: data['regionName'] as String?,
      streetName: data['streetName'] as String?,
      isOnline: (data['isOnline'] as bool?) ?? false,
      headingDegrees: heading,
      speedMps: speed,
      accuracyMeters: accuracy,
      lastLocationUpdateAt: lastFix,
      isActive: (data['isActive'] as bool?) ?? true,
      isVerified: (data['isVerified'] as bool?) ?? false,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (data['totalRatings'] as num?)?.toInt() ?? 0,
      totalOrders: (data['totalOrders'] as num?)?.toInt() ?? 0,
      createdAt: const TimestampConverter().fromJson(data['createdAt']),
      updatedAt: const TimestampConverter().fromJson(
        data['updatedAt'] ?? data['createdAt'],
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'sellerId': sellerId,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'profilePictureUrl': profilePictureUrl,
        // Top-level lat/lng for legacy readers.
        'latitude': latitude,
        'longitude': longitude,
        // Geohash duplicated at top level so the geo query's
        // `where('geohash', ...)` clause is single-field and indexable.
        'geohash': geohash,
        // Nested shape for human readers and for any service that reads
        // a `location` map (matches the convention used by UserModel).
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          if (geohash != null) 'geohash': geohash,
        },
        // Firestore GeoPoint so the `geo` field can be used by future
        // native geo helpers.
        'geo': GeoPoint(latitude, longitude),
        'marketName': marketName,
        'regionName': regionName,
        'streetName': streetName,
        'isOnline': isOnline,
        'heading': headingDegrees,
        'speed': speedMps,
        'locationAccuracy': accuracyMeters,
        'lastLocationUpdateAt': lastLocationUpdateAt == null
            ? null
            : Timestamp.fromDate(lastLocationUpdateAt!),
        'isActive': isActive,
        'isVerified': isVerified,
        'averageRating': averageRating,
        'totalRatings': totalRatings,
        'totalOrders': totalOrders,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// Convenience: a slice of the map for location-only updates. Used by
  /// the live tracker so we don't write every field on every fix.
  Map<String, dynamic> toLocationPatch(String geohashOverride) => {
        'latitude': latitude,
        'longitude': longitude,
        'geohash': geohashOverride,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'geohash': geohashOverride,
        },
        'geo': GeoPoint(latitude, longitude),
        'heading': headingDegrees,
        'speed': speedMps,
        'locationAccuracy': accuracyMeters,
        'lastLocationUpdateAt': lastLocationUpdateAt == null
            ? null
            : Timestamp.fromDate(lastLocationUpdateAt!),
      };
}
