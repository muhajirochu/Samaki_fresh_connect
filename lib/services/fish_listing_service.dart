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

  /// Maximum number of active listings we hold in memory at once. The
  /// buyer's marketplace feed rarely needs more than a few hundred
  /// most-recent listings — anything older than ~24h has expired and
  /// isn't buyable anyway. Capping the query lets Firestore use a
  /// `LIMIT` pushdown (combined with the `status+createdAt` index)
  /// instead of streaming the whole collection.
  static const int _maxActiveListings = 500;

  /// Stream all active listings (marketplace feed).
  ///
  /// Firestore side: capped at [_maxActiveListings] sorted by
  /// `createdAt DESC`. The composite `status+createdAt` index in
  /// `firestore.indexes.json` makes this O(log n). Without the
  /// `LIMIT`, every snapshot — even ones with zero new docs — would
  /// pull the entire active collection off the wire.
  Stream<List<FishListingModel>> streamActiveListings() {
    if (!_isAvailable) return Stream.value([]);
    AppLogger.debug('streamActiveListings: subscribing to fishListings');
    // No `.orderBy(...)` here — Firestore would require a composite
    // `(status, createdAt)` index to honour it, and a freshly
    // provisioned project that hasn't run `firebase deploy
    // --only firestore:indexes` would fail the whole stream with
    // `failed-precondition`. Sorting in memory below already gives
    // us the same ordering and tolerates missing indexes.
    //
    // On Firestore error (permission-denied, missing index, network)
    // we fall back to an *unfiltered* read so the marketplace still
    // surfaces data instead of staying on a permanent "Failed to
    // load listings" wall. The fallback itself can fail (e.g. the
    // user has no read permission at all) and only then do we surface
    // the error.
    final filtered = _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'active')
        .limit(_maxActiveListings)
        .snapshots()
        .map((snap) {
      final list = <FishListingModel>[];
      for (final d in snap.docs) {
        try {
          list.add(FishListingModel.fromJson(d.data()));
        } catch (e) {
          AppLogger.warning(
              'streamActiveListings: dropping malformed doc ${d.id}: $e');
        }
      }
      list.sort((a, b) => _dateOrZero(b.createdAt)
          .compareTo(_dateOrZero(a.createdAt)));
      return list;
    }).handleError((Object e, StackTrace s) {
      AppLogger.warning(
          'streamActiveListings: filtered query failed, '
          'falling back to unfiltered read. Error: $e');
      // Return a stream of one snapshot-error that the outer
      // .handleError will catch and replace with the fallback.
      return Stream<List<FishListingModel>>.error(e, s);
    });

    return filtered.handleError((Object e, StackTrace s) {
      // First attempt failed — try the unfiltered read. Even an
      // empty marketplace keeps the UI alive.
      return _firestore
          .collection(_collection)
          .limit(_maxActiveListings)
          .snapshots()
          .map((snap) {
        final list = <FishListingModel>[];
        for (final d in snap.docs) {
          try {
            list.add(FishListingModel.fromJson(d.data()));
          } catch (e2) {
            AppLogger.warning(
                'streamActiveListings fallback: '
                'dropping malformed doc ${d.id}: $e2');
          }
        }
        list.sort((a, b) => _dateOrZero(b.createdAt)
            .compareTo(_dateOrZero(a.createdAt)));
        return list;
      }).handleError((Object e2, StackTrace s2) {
        // Even the unfiltered read failed. Surface the original
        // error so the UI shows a useful retry state.
        AppLogger.error(
            'streamActiveListings: unfiltered fallback also failed: $e2');
        throw e;
      });
    });
  }

  /// Stream listings created by a specific seller. Capped with
  /// `LIMIT` so a seller with hundreds of historical listings
  /// doesn't drag down the seller dashboard render time.
  Stream<List<FishListingModel>> streamListingsBySeller(String sellerId) {
    if (!_isAvailable) return Stream.value([]);
    // No `.orderBy(...)` here — same rationale as streamActiveListings
    // above. Without the composite `(sellerId, createdAt)` index
    // deployed, the query fails with `failed-precondition`. We sort
    // in memory instead.
    //
    // On Firestore error we fall back to reading the whole collection
    // and filtering client-side so My Listings still surfaces the
    // seller's rows when the index isn't deployed.
    final filtered = _firestore
        .collection(_collection)
        .where('sellerId', isEqualTo: sellerId)
        .limit(_maxActiveListings)
        .snapshots()
        .map((snap) {
      final list = <FishListingModel>[];
      for (final d in snap.docs) {
        try {
          list.add(FishListingModel.fromJson(d.data()));
        } catch (e) {
          AppLogger.warning(
              'streamListingsBySeller: dropping malformed doc ${d.id}: $e');
        }
      }
      list.sort((a, b) => _dateOrZero(b.createdAt)
          .compareTo(_dateOrZero(a.createdAt)));
      return list;
    }).handleError((Object e, StackTrace s) {
      AppLogger.warning(
          'streamListingsBySeller: filtered query failed, '
          'falling back to unfiltered read. Error: $e');
      return Stream<List<FishListingModel>>.error(e, s);
    });

    return filtered.handleError((Object e, StackTrace s) {
      return _firestore
          .collection(_collection)
          .limit(_maxActiveListings)
          .snapshots()
          .map((snap) {
        final list = <FishListingModel>[];
        for (final d in snap.docs) {
          try {
            final raw = Map<String, dynamic>.from(d.data());
            if (raw['sellerId'] != sellerId) continue;
            list.add(FishListingModel.fromJson(raw));
          } catch (e2) {
            AppLogger.warning(
                'streamListingsBySeller fallback: '
                'dropping malformed doc ${d.id}: $e2');
          }
        }
        list.sort((a, b) => _dateOrZero(b.createdAt)
            .compareTo(_dateOrZero(a.createdAt)));
        return list;
      }).handleError((Object e2, StackTrace s2) {
        AppLogger.error(
            'streamListingsBySeller: unfiltered fallback also failed: $e2');
        throw e;
      });
    });
  }

  /// Returns the date or epoch-0 if null — keeps sort callbacks
  /// total-order-friendly for legacy listings missing `createdAt`.
  static DateTime _dateOrZero(DateTime? d) =>
      d ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Stream every listing in the system (admin moderation view).
  /// Includes sold, expired and inactive listings so the admin can
  /// review the full marketplace catalogue. Capped with `LIMIT` so
  /// the admin screen stays responsive even on a large collection.
  ///
  /// Uses the document id as the listingId fallback so legacy
  /// documents without a denormalised `listingId` field still get
  /// a valid id (required for the admin delete action).
  Stream<List<FishListingModel>> streamAllListings() {
    if (!_isAvailable) return Stream.value([]);
    try {
      // No `.orderBy(...)` — sorting in memory keeps the stream alive
      // until the deployed (createdAt DESC) single-field index is
      // available.
      return _firestore
          .collection(_collection)
          .limit(_maxActiveListings)
          .snapshots()
          .map((snap) {
        final list = <FishListingModel>[];
        for (final d in snap.docs) {
          try {
            final raw = Map<String, dynamic>.from(d.data());
            // Fall back to the document id when `listingId` is
            // missing (legacy documents that predate the rename).
            if ((raw['listingId'] as String?)?.isEmpty ?? true) {
              raw['listingId'] = d.id;
            }
            list.add(FishListingModel.fromJson(raw));
          } catch (e) {
            AppLogger.warning(
                'streamAllListings: dropping malformed doc ${d.id}: $e');
          }
        }
        list.sort((a, b) => _dateOrZero(b.createdAt)
            .compareTo(_dateOrZero(a.createdAt)));
        return list;
      });
    } catch (e) {
      AppLogger.error('Error streaming all listings: $e');
      return Stream.value(<FishListingModel>[]);
    }
  }

  /// Stream the count of currently-active listings — used by the
  /// admin dashboard's "Active Listings" stat tile. Listens on the
  /// `status == 'active'` query so the count flips live as listings
  /// are marked sold / expired.
  Stream<int> streamActiveListingsCount() {
    if (!_isAvailable) return Stream.value(0);
    try {
      return _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'active')
          .snapshots()
          .map((snap) => snap.docs.length);
    } catch (e) {
      AppLogger.error('Error streaming active listings count: $e');
      return Stream.value(0);
    }
  }

  /// Live count of every listing in the system (regardless of
  /// status). Drives the admin dashboard's Total Listings tile.
  Stream<int> streamTotalListingsCount() {
    if (!_isAvailable) return Stream.value(0);
    try {
      return _firestore
          .collection(_collection)
          .snapshots()
          .map((snap) => snap.docs.length);
    } catch (e) {
      AppLogger.error('Error streaming total listings count: $e');
      return Stream.value(0);
    }
  }

  /// Stream every listing matching a specific fish type / category
  /// slug. Used by the admin category moderation view.
  Stream<List<FishListingModel>> streamListingsByCategorySlug(String slug) {
    if (!_isAvailable) return Stream.value(<FishListingModel>[]);
    try {
      // No `.orderBy(...)` — see streamAllListings above.
      return _firestore
          .collection(_collection)
          .where('fishType', isEqualTo: slug)
          .snapshots()
          .map((snap) {
        final list = <FishListingModel>[];
        for (final d in snap.docs) {
          try {
            final raw = Map<String, dynamic>.from(d.data());
            if ((raw['listingId'] as String?)?.isEmpty ?? true) {
              raw['listingId'] = d.id;
            }
            list.add(FishListingModel.fromJson(raw));
          } catch (e) {
            AppLogger.warning(
                'streamListingsByCategorySlug: dropping malformed doc ${d.id}: $e');
          }
        }
        list.sort((a, b) => _dateOrZero(b.createdAt)
            .compareTo(_dateOrZero(a.createdAt)));
        return list;
      });
    } catch (e) {
      AppLogger.error('Error streaming listings by category $slug: $e');
      return Stream.value(<FishListingModel>[]);
    }
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

  /// Atomically flip a listing from `active` to `sold`. Uses a
  /// Firestore `runTransaction` so two simultaneous purchases can't
  /// both succeed — only the first caller wins and the rest receive
  /// `false`. The transaction also re-checks the live status under
  /// Firestore's lock so a listing already marked `sold` cannot be
  /// purchased again.
  ///
  /// Returns `true` on success, `false` if the listing was no longer
  /// `active` at the moment of the write (e.g. another buyer won the
  /// race, or the seller manually flipped the status).
  Future<bool> tryMarkAsSold(String listingId) async {
    if (!_isAvailable) return false;
    try {
      final result = await _firestore.runTransaction<bool>((txn) async {
        final ref = _firestore.collection(_collection).doc(listingId);
        final snap = await txn.get(ref);
        if (!snap.exists) return false;
        final data = snap.data();
        if (data == null) return false;
        final status = data['status'] as String?;
        if (status != 'active') return false;
        txn.update(ref, {
          'status': 'sold',
          'soldAt': FieldValue.serverTimestamp(),
        });
        return true;
      });
      if (result) {
        AppLogger.info('Listing $listingId marked as sold (atomic)');
      } else {
        AppLogger.warning(
            'tryMarkAsSold: $listingId was no longer active');
      }
      return result;
    } catch (e) {
      AppLogger.error('tryMarkAsSold error for $listingId: $e');
      rethrow;
    }
  }

  /// Mark listing as sold
  ///
  /// Deprecated: callers should prefer [tryMarkAsSold] so concurrent
  /// purchases can't double-mark the same row. Kept for compatibility
  /// with the legacy "Mark as sold" admin button.
  // ignore: deprecated_member_use
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

  /// Bulk-delete many listings in a single round trip.
  ///
  /// Uses Firestore's `WriteBatch` so the deletes commit atomically
  /// (all-or-nothing) and the network round trips stay linear with
  /// the batch size instead of N. Returns the count of listings that
  /// were successfully committed.
  ///
  /// Empty / null listing ids are skipped silently — the admin UI
  /// filters them out before the call, but defensive code here means
  /// a stray empty string can't blow up the whole batch.
  Future<int> deleteListingsBulk(Iterable<String> listingIds) async {
    if (!_isAvailable) return 0;
    final ids = listingIds
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (ids.isEmpty) return 0;
    try {
      final batch = _firestore.batch();
      for (final id in ids) {
        batch.delete(_firestore.collection(_collection).doc(id));
      }
      await batch.commit();
      AppLogger.info('Bulk-deleted ${ids.length} listings');
      return ids.length;
    } catch (e) {
      AppLogger.error('Error bulk-deleting listings: $e');
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
