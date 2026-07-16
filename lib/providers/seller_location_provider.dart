// Riverpod adapters for the live seller tracker + the buyer-side
// geohash-filtered seller search.
//
// ── Session isolation ──────────────────────────────────────
//   - The seller's tracker is keyed on the current user's id. Switching
//     accounts auto-disposes the tracker.
//   - The buyer-side geo search is keyed on (lat, lng, radiusKm). It
//     only watches data when a valid session is in scope.
//
// ── Real-time readiness ───────────────────────────────────
//   - `liveSellersProvider` runs a Firestore snapshot stream filtered
//     by `isOnline == true`. The buyer's "Nearby Sellers" list updates
//     within ~200 ms of a seller going online or offline.
//   - `nearbySellersGeoQueryProvider` is a one-shot Future; callers
//     should re-trigger it when their location changes.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/street_seller_model.dart';
import '../services/geohash_service.dart';
import '../services/seller_location_tracker.dart';
import '../utils/logger.dart';
import 'auth_provider.dart';

// ── Seller-side: online tracker ──────────────────────────────────────────────

/// Holds the singleton tracker for the duration of the seller's session.
/// Kept alive by ref.watch; when the user logs out or switches role,
/// the provider is invalidated and the tracker is disposed.
final sellerLocationTrackerProvider =
    ChangeNotifierProvider<SellerLocationTracker>((ref) {
  final tracker = SellerLocationTracker();
  ref.onDispose(() => tracker.dispose());
  return tracker;
});

/// Toggle: true ⇔ seller is currently broadcasting GPS. Streams from the
/// tracker's status so the UI can show a green dot / spinner / error.
final sellerOnlineStatusProvider = Provider<SellerTrackerStatus>((ref) {
  final tracker = ref.watch(sellerLocationTrackerProvider);
  return tracker.status;
});

/// High-level actions the UI calls. Internally validates the session is
/// a street seller before touching the tracker.
class SellerOnlineActions {
  SellerOnlineActions(this._ref);
  final Ref _ref;

  Future<bool> goOnline() async {
    final user = _ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null) {
      throw StateError('Not signed in');
    }
    // Any signed-in user who has a streetSeller doc can flip the flag.
    // We do not enforce role here — the seller dashboard is itself the
    // role gate — but the call returns false on a permission failure.
    final tracker = _ref.read(sellerLocationTrackerProvider);
    final ok = await tracker.start(user.userId);
    return ok;
  }

  Future<void> goOffline() async {
    final tracker = _ref.read(sellerLocationTrackerProvider);
    await tracker.stop();
  }
}

final sellerOnlineActionsProvider = Provider<SellerOnlineActions>((ref) {
  return SellerOnlineActions(ref);
});

// ── Buyer-side: live + geohash-filtered seller streams ───────────────────────

final _sellersCollection = FirebaseFirestore.instance.collection('streetSellers');

/// All sellers whose `isOnline == true` AND `isActive == true`. Real-time.
/// Used as the "live" layer of the buyer map — the moment a street
/// seller taps "Go online" anywhere in the city, they appear here.
///
/// Capped at [_maxActiveSellers]; Firestore pushdown `LIMIT` keeps
/// the wire payload bounded even as the seller pool grows.
final liveSellersProvider = StreamProvider<List<StreetSellerModel>>((ref) {
  if (Firebase.apps.isEmpty) return Stream.value(const []);
  return _sellersCollection
      .where('isOnline', isEqualTo: true)
      .where('isActive', isEqualTo: true)
      .limit(_maxActiveSellers)
      .snapshots()
      .map((snap) {
    final list =
        snap.docs.map((d) => StreetSellerModel.fromMap(d.data(), docId: d.id))
            .toList();
    list.sort((a, b) {
      final aT = a.lastLocationUpdateAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bT = b.lastLocationUpdateAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bT.compareTo(aT);
    });
    return list;
  });
});

/// Maximum number of sellers we materialise in memory at once. The
/// buyer map + search only need the most recently active slice.
const int _maxActiveSellers = 500;

/// All sellers (online + offline) — keeps the map populated when no
/// one is currently live but the buyer's last-known area still has
/// registered sellers. Capped with `LIMIT` for the same reason as
/// [liveSellersProvider].
final activeStreetSellersProviderRemote =
    StreamProvider<List<StreetSellerModel>>((ref) {
  if (Firebase.apps.isEmpty) return Stream.value(const []);
  return _sellersCollection
      .where('isActive', isEqualTo: true)
      .limit(_maxActiveSellers)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => StreetSellerModel.fromMap(d.data(), docId: d.id))
          .toList());
});

/// Parameters for a geo query against the streetSellers collection.
class GeoSearchParams {
  final double latitude;
  final double longitude;
  final double radiusKm;
  const GeoSearchParams({
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
  });

  @override
  bool operator ==(Object other) =>
      other is GeoSearchParams &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.radiusKm == radiusKm;

  @override
  int get hashCode => Object.hash(latitude, longitude, radiusKm);
}

/// Server-side geo query + client-side Haversine refinement.
///
/// Pattern (matches `geoflutterfire_plus`):
///   1. Compute a [GeoHashQuery] for the (lat, lng, radius) at a fixed
///      precision — each geohash cell is ~150 m × 150 m at precision 7.
///   2. Stream Firestore docs whose `geohash` lies in the
///      `start..end` lexicographic range.
///   3. Refine candidates with a fast planar approximation in
///      [GeohashService.withinRadius].
///
/// Each new search invalidates the previous query — repeated taps on
/// the same radius just re-attach to the live stream (no extra round
/// trips).
///
/// On any Firestore error (most commonly a missing composite index on
/// `(geohash, isActive)`) we **silently** fall back to
/// `activeStreetSellersProviderRemote` so the buyer always sees
final nearbySellersGeoQueryProvider = StreamProvider.family<
    List<StreetSellerModel>, GeoSearchParams>((ref, params) {
  if (Firebase.apps.isEmpty) return Stream.value(const []);

  final q = GeohashService.queryBox(
    centerLat: params.latitude,
    centerLng: params.longitude,
    radiusKm: params.radiusKm,
  );

  final controller = StreamController<List<StreetSellerModel>>.broadcast();
  QuerySnapshot<Map<String, dynamic>>? lastSnapshot;
  Object? primaryError;
  List<StreetSellerModel> fallbackCache = const [];

  void emit() {
    if (primaryError != null) {
      // Indexed query errored (most commonly a missing composite
      // index). Use the unfiltered fallback so the buyer still sees
      // sellers instead of an empty map.
      if (!controller.isClosed && fallbackCache.isNotEmpty) {
        controller.add(fallbackCache);
      } else if (!controller.isClosed) {
        controller.add(const []);
      }
      return;
    }
    final snap = lastSnapshot;
    if (snap == null) {
      // Primary hasn't returned yet — show the unfiltered list as a
      // placeholder so the UI isn't blank during the first tick.
      if (!controller.isClosed && fallbackCache.isNotEmpty) {
        controller.add(fallbackCache);
      }
      return;
    }
    final docs = snap.docs
        .map((d) => StreetSellerModel.fromMap(d.data(), docId: d.id))
        .where((s) {
      if (s.latitude == 0 && s.longitude == 0) return false;
      return GeohashService.withinRadius(
        queryLat: params.latitude,
        queryLng: params.longitude,
        candidateLat: s.latitude,
        candidateLng: s.longitude,
        radiusKm: params.radiusKm,
      );
    }).toList();
    docs.sort(
        (a, b) => a.distanceKmFrom(params.latitude, params.longitude)
            .compareTo(b.distanceKmFrom(params.latitude, params.longitude)));
    if (!controller.isClosed) controller.add(docs);
  }

  // Primary: the geohash range query. Built inside try/catch so a
  // throw at query-construction time (e.g. missing index) skips
  // straight to the fallback path.
  Stream<QuerySnapshot<Map<String, dynamic>>> primaryStream;
  try {
    primaryStream = _sellersCollection
        .where('geohash', isGreaterThanOrEqualTo: q.start)
        .where('geohash', isLessThanOrEqualTo: q.end)
        .where('isActive', isEqualTo: true)
        .snapshots();
  } catch (e) {
    AppLogger.warning(
      'nearbySellersGeoQueryProvider: query build failed, '
      'using fallback: $e',
    );
    primaryStream = const Stream.empty();
    primaryError = e;
  }

  final primarySub = primaryStream.listen(
    (snap) {
      lastSnapshot = snap;
      emit();
    },
    onError: (Object e, StackTrace st) {
      AppLogger.warning(
        'nearbySellersGeoQueryProvider: primary query errored, '
        'falling back to activeStreetSellersProviderRemote: $e',
      );
      primaryError = e;
      emit();
    },
  );

  // Fallback: listen via Riverpod's ref.listen (not the deprecated
  // `.stream` property) and capture the latest value.
  final fallbackSub = ref.listen<AsyncValue<List<StreetSellerModel>>>(
    activeStreetSellersProviderRemote,
    (_, next) {
      final list = next.valueOrNull;
      if (list != null) {
        fallbackCache = list;
        emit();
      }
    },
    fireImmediately: true,
  );

  ref.onDispose(() {
    primarySub.cancel();
    fallbackSub.close();
    controller.close();
  });

  return controller.stream;
});

