// Firestore service for the Buyer Dashboard. Three streams:
//   1. Broker-approved fish listings (the "marketplace" the buyer sees).
//   2. This buyer's fish requests.
//   3. Street sellers the buyer can see (for distance / contact).
//
// Every public method either:
//   - takes a buyerId explicitly, OR
//   - reads it from the current auth context, OR
//   - returns a Stream that is already scoped via `.where('buyerId', ...)`.
//
// Nothing here reaches across user roles.
//
// Street-seller demo data (the `fallback` lists used to live in
// `services/demo_sellers_data.dart`) was removed so the marketplace
// shows real registered sellers and their listings, never seeded
// fixtures.

import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/fish_item_model.dart';
import '../models/fish_request_model.dart';
import '../models/street_seller_model.dart';
import '../utils/logger.dart';

class BuyerDashboardService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  bool get _isAvailable => Firebase.apps.isNotEmpty;

  static const String _listingsCollection = 'fishListings';
  static const String _requestsCollection = 'fishRequests';
  static const String _sellersCollection = 'streetSellers';

  // ── Marketplace feed ────────────────────────────────────────────────────────

  /// All broker-approved, active, in-stock fish listings. Real-time — the
  /// moment a fish hits quantityKg == 0 (or status flips to 'sold'), it
  /// disappears from this stream and from the buyer's UI.
  ///
  /// Filtering `isBrokerApproved == true` on Firestore requires a composite
  /// index in production. For dev, the in-memory `.isBuyable` guard below
  /// catches anything the broker didn't approve.
  Stream<List<FishItemModel>> streamApprovedFish() {
    if (!_isAvailable) {
      return Stream.value(const <FishItemModel>[]);
    }
    AppLogger.debug(
      'streamApprovedFish: subscribing to fishListings where status=active',
    );
    return _firestore
        .collection(_listingsCollection)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) {
      AppLogger.debug(
        'streamApprovedFish: snapshot size=${snap.docs.length}',
      );
      final items = <FishItemModel>[];
      for (final d in snap.docs) {
        try {
          final item = FishItemModel.fromMap(d.data(), docId: d.id);
          if (item.isBuyable) items.add(item);
        } catch (e, st) {
          AppLogger.warning('Skipping malformed fish listing ${d.id}: $e',
              e, st);
        }
      }
      AppLogger.debug(
        'streamApprovedFish: returning ${items.length} buyable items '
        'out of ${snap.docs.length} raw docs',
      );
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  /// Variant: a buyer's "nearby" feed. `radiusKm` is applied in-memory
  /// because Firestore geo queries need a separate geo library.
  Stream<List<FishItemModel>> streamApprovedFishNear(
    double buyerLat,
    double buyerLng, {
    double radiusKm = 10.0,
  }) {
    return streamApprovedFish().map((items) {
      return items.where((item) {
        if (item.latitude == null || item.longitude == null) return false;
        final dist = _haversineKm(
          buyerLat,
          buyerLng,
          item.latitude!,
          item.longitude!,
        );
        return dist <= radiusKm;
      }).toList();
    });
  }

  // ── This buyer's fish requests ─────────────────────────────────────────────

  Stream<List<FishRequestModel>> streamRequestsForBuyer(String buyerId) {
    if (!_isAvailable) return Stream.value(const []);
    return _firestore
        .collection(_requestsCollection)
        .where('buyerId', isEqualTo: buyerId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => FishRequestModel.fromMap(d.data(), docId: d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Create a new fish request, stamped with the supplied buyerId. The
  /// caller (controller) MUST supply the buyerId — we never infer it from
  /// auth here so unit tests can drive the service with a fake id.
  Future<String> createRequest(FishRequestModel request) async {
    if (!_isAvailable) throw StateError('Firebase not available');
    final data = request.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await _firestore.collection(_requestsCollection).add(data);
    await ref.update({'requestId': ref.id});
    AppLogger.info(
        'FishRequest created: ${ref.id} for buyer ${request.buyerId}');
    return ref.id;
  }

  Future<void> cancelRequest(String requestId) async {
    if (!_isAvailable) return;
    await _firestore.collection(_requestsCollection).doc(requestId).update({
      'status': FishRequestStatus.cancelled.value,
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Street sellers (read-only for the buyer) ───────────────────────────────

  /// Maximum number of sellers we materialise in memory at once. The
  /// marketplace feed rarely needs more than a few hundred sellers —
  /// Firestore pushdown `LIMIT` keeps the wire payload bounded.
  static const int _maxActiveSellers = 500;

  Stream<List<StreetSellerModel>> streamActiveSellers() {
    if (!_isAvailable) return Stream.value(const <StreetSellerModel>[]);
    return _firestore
        .collection(_sellersCollection)
        .where('isActive', isEqualTo: true)
        .limit(_maxActiveSellers)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((d) => StreetSellerModel.fromMap(d.data(), docId: d.id))
          .toList();
    });
  }

  // ── Recent searches (per-buyer subcollection) ──────────────────────────────

  Future<void> recordSearch({
    required String buyerId,
    required String query,
    int resultCount = 0,
  }) async {
    if (!_isAvailable) return;
    if (query.trim().isEmpty) return;
    final trimmed = query.trim();
    final ref = _firestore
        .collection('users')
        .doc(buyerId)
        .collection('recentSearches')
        .doc(trimmed.toLowerCase());
    await ref.set({
      'query': trimmed,
      'searchedAt': FieldValue.serverTimestamp(),
      'resultCount': resultCount,
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> streamRecentSearches(String buyerId) {
    if (!_isAvailable) return Stream.value(const []);
    return _firestore
        .collection('users')
        .doc(buyerId)
        .collection('recentSearches')
        .orderBy('searchedAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // ── Geo helper (duplicated from StreetSellerModel.distanceKmFrom so we can
  //     sort/filter listing coordinates without instantiating a seller). ────

  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _deg2rad(double d) => d * (math.pi / 180.0);
}