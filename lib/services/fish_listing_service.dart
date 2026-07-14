import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';

import '../models/fish_listing_model.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

// Inline geohash encoder (precision 7 ~ 153 m cell, Base32 alphabet).
// Matches what `geohash_service.dart` does so all our geo writes are
// consistent — keep them in sync if you ever change the algorithm.
String _encodeGeohash(double lat, double lng) {
  const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  String hash = '';
  double minLat = -90, maxLat = 90;
  double minLng = -180, maxLng = 180;
  bool evenBit = true;
  int bit = 0;
  int ch = 0;
  while (hash.length < 7) {
    if (evenBit) {
      final mid = (minLng + maxLng) / 2;
      if (lng >= mid) {
        ch = (ch << 1) | 1;
        minLng = mid;
      } else {
        ch = ch << 1;
        maxLng = mid;
      }
    } else {
      final mid = (minLat + maxLat) / 2;
      if (lat >= mid) {
        ch = (ch << 1) | 1;
        minLat = mid;
      } else {
        ch = ch << 1;
        maxLat = mid;
      }
    }
    evenBit = !evenBit;
    if (++bit == 5) {
      hash += base32[ch];
      bit = 0;
      ch = 0;
    }
  }
  return hash;
}

class FishListingService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  bool get _isAvailable => Firebase.apps.isNotEmpty;

  static const String _collection = 'fishListings';

  // ── Geo defaults ───────────────────────────────────────────────────────────
  // The buyer's `streamApprovedFishNear()` filter rejects any listing that
  // is missing `latitude`/`longitude`. To avoid that we ALWAYS write geo
  // fields on create — preferring the seller's last-known position and
  // falling back to a sensible Zanzibar default so the listing still
  // surfaces somewhere on the map.
  static const double _fallbackLat = -6.1629; // Stone Town
  static const double _fallbackLng = 39.2026;

  /// Create a new fish listing. `sellerLocation` is the seller's
  /// last-known position (from their `users/` doc); we read GPS once if
  /// it's missing. The location flows into the buyer's geo-radius
  /// query.
  Future<String> createListing(
    FishListingModel listing, {
    UserModel? seller,
    Position? livePosition,
  }) async {
    if (!_isAvailable) throw StateError('Firebase not available');
    try {
      AppLogger.info('Creating listing for seller: ${listing.sellerId}');
      final data = listing.toJson();
      data['createdAt'] = FieldValue.serverTimestamp();

      // 1) Resolve coordinates (live → profile → fallback).
      final coords = await _resolveCoords(
        seller: seller,
        live: livePosition,
      );
      data['latitude'] = coords.$1;
      data['longitude'] = coords.$2;
      data['location'] = {
        'latitude': coords.$1,
        'longitude': coords.$2,
        'geohash': _encodeGeohash(coords.$1, coords.$2),
      };
      data['geo'] = GeoPoint(coords.$1, coords.$2);
      data['geohash'] = _encodeGeohash(coords.$1, coords.$2);

      final docRef = await _firestore.collection(_collection).add(data);
      // Update the doc with its own id
      await docRef.update({'listingId': docRef.id});
      AppLogger.info(
          'Listing created: ${docRef.id} at ${coords.$1},${coords.$2}');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Error creating listing: $e');
      rethrow;
    }
  }

  /// Best-effort coordinate resolution. Always returns *something* so the
  /// listing is never invisibly dropped by the buyer's geo filter.
  Future<(double, double)> _resolveCoords({
    UserModel? seller,
    Position? live,
  }) async {
    if (live != null) return (live.latitude, live.longitude);
    final loc = seller?.location;
    if (loc != null &&
        loc['latitude'] is num &&
        loc['longitude'] is num) {
      return (
        (loc['latitude'] as num).toDouble(),
        (loc['longitude'] as num).toDouble(),
      );
    }
    // Last-ditch GPS read with a tight timeout. If that fails too we
    // fall back to Stone Town so the listing is still visible.
    try {
      final svcOn = await Geolocator.isLocationServiceEnabled();
      if (svcOn) {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.always ||
            perm == LocationPermission.whileInUse) {
          final p = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 5),
          );
          return (p.latitude, p.longitude);
        }
      }
    } catch (e) {
      AppLogger.warning('Live GPS lookup failed during create-listing: $e');
    }
    return (_fallbackLat, _fallbackLng);
  }

  /// Stream all active listings (marketplace feed)
  Stream<List<FishListingModel>> streamActiveListings() {
    if (!_isAvailable) return Stream.value([]);
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => FishListingModel.fromJson(d.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream listings created by a specific seller
  Stream<List<FishListingModel>> streamListingsBySeller(String sellerId) {
    if (!_isAvailable) return Stream.value([]);
    return _firestore
        .collection(_collection)
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => FishListingModel.fromJson(d.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }



  /// Fetch a single listing by ID
  Future<FishListingModel?> getListingById(String listingId) async {
    if (!_isAvailable) return null;
    try {
      final doc = await _firestore.collection(_collection).doc(listingId).get();
      if (!doc.exists) return null;
      return FishListingModel.fromJson(doc.data()!);
    } catch (e) {
      AppLogger.error('Error fetching listing $listingId: $e');
      return null;
    }
  }

  /// Update listing fields
  Future<void> updateListing(
    String listingId,
    Map<String, dynamic> fields,
  ) async {
    if (!_isAvailable) return;
    try {
      await _firestore.collection(_collection).doc(listingId).update(fields);
      AppLogger.info('Listing $listingId updated');
    } catch (e) {
      AppLogger.error('Error updating listing: $e');
      rethrow;
    }
  }

  /// Mark listing as sold
  Future<void> markAsSold(String listingId) async {
    await updateListing(listingId, {
      'status': 'sold',
      'soldAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a listing
  Future<void> deleteListing(String listingId) async {
    if (!_isAvailable) return;
    try {
      await _firestore.collection(_collection).doc(listingId).delete();
      AppLogger.info('Listing $listingId deleted');
    } catch (e) {
      AppLogger.error('Error deleting listing: $e');
      rethrow;
    }
  }

  /// Persist a `location` patch to an existing listing. Used by the
  /// `ListingLocationService` after the seller captures their shop
  /// location — the listing may have been created earlier without a
  /// location, and we want the buyer's geo query to pick it up.
  Future<void> updateListingLocation(
    String listingId, {
    required double latitude,
    required double longitude,
  }) async {
    if (!_isAvailable) return;
    try {
      final geohash = _encodeGeohash(latitude, longitude);
      await _firestore.collection(_collection).doc(listingId).update({
        'latitude': latitude,
        'longitude': longitude,
        'geohash': geohash,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'geohash': geohash,
        },
        'geo': GeoPoint(latitude, longitude),
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info('Listing $listingId location updated');
    } catch (e) {
      AppLogger.error('Error updating listing location: $e');
      rethrow;
    }
  }
}
