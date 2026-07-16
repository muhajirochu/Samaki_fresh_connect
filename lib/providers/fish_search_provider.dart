// Streams the buyer's fish-name search results.
//
// Pipeline:
//
//   activeListingsProvider × activeStreetSellersProviderRemote × currentBuyerLocationProvider
//          │                              │                                  │
//          └──────────────┬───────────────┴───────────────┬──────────────────┘
//                         ▼                               ▼
//              ┌── query filter ──┐             ┌── group by fish type ──┐
//              ▼                  ▼             ▼                        ▼
//          FishSearchResult stream (real-time)
//
// Why `activeStreetSellersProviderRemote` (and not `liveSellersProvider`):
//   The previous version watched `liveSellersProvider`, which is filtered
//   by `isOnline == true`. That meant a street seller who had
//   registered, posted fish, but hadn't tapped "Go Online" was
//   *invisible* to buyer search — the search would return "No sellers
//   have Tuna right now" even though the seller was registered and
//   had tuna in stock. We source from
//   `activeStreetSellersProviderRemote` (every seller with
//   `isActive == true`, online or offline) so all registered sellers
//   are reachable via search.
//
// Architecture:
//   `fishSearchProvider` is a SINGLETON `StreamProvider` (not a family)
//   — only one Firestore subscription, one `StreamController`, one set
//   of `ref.listen` callbacks, shared across every search screen in
//   the app. The query is fed in via `searchQueryProvider` (a tiny
//   `StateProvider<String>`), so changing the query just re-runs
//   `emit()` against the same already-loaded listings/sellers/location
//   buffers — no extra Firestore round-trip.
//
// Upstream readiness gate:
//   On cold start, the three upstream streams arrive at slightly
//   different ticks. Without a gate, the search screen would flash
//   "No sellers have X" for a frame in between. We track per-stream
//   readiness flags so `emit()` only publishes once *all three*
//   upstreams have delivered their first observation; subsequent
//   ticks just refresh.

import 'dart:async';
import 'dart:math' as math;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/fish_search_result.dart';
import '../models/fish_listing_model.dart';
import '../models/street_seller_model.dart';
import '../services/location_service.dart' show currentBuyerLocationProvider;
import 'listing_provider.dart';
import 'seller_location_provider.dart';

typedef FishSearchResults = List<FishSearchResult>;

/// Current search query. Cheap shared state — flipping this triggers
/// `fishSearchProvider` to re-emit against its already-loaded buffers
/// (no Firestore round-trip).
final searchQueryProvider = StateProvider<String>((_) => '');

/// Trims and lowercases the query. Returns `null` for empty input so
/// callers can short-circuit. Exposed (not private) so tests can
/// cover the normalization behaviour directly.
String? normalizeSearchQuery(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  return trimmed.toLowerCase();
}

/// True when a listing's `fishType` or `description` text contains
/// the (already lowercased) query. Exposed for tests.
bool listingMatchesSearchQuery(FishListingModel listing, String q) {
  if (listing.fishType.toLowerCase().contains(q)) return true;
  final desc = (listing.description ?? '').toLowerCase();
  if (desc.isNotEmpty && desc.contains(q)) return true;
  return false;
}

/// True when the listing should be visible to a buyer in search. Mirrors
/// the same gates `FishItemModel.isBuyable` enforces, applied here to
/// the raw `FishListingModel` so we don't have to round-trip through
/// the broker/buyer model layer for the search pipeline.
bool listingIsSearchable(FishListingModel listing, {DateTime? now}) {
  if (listing.status.toLowerCase() != 'active') return false;
  if (listing.quantityKg <= 0) return false;
  final cutoff = now ?? DateTime.now();
  if (listing.expiresAt.isBefore(cutoff)) {
    return false;
  }
  return true;
}

/// Great-circle distance in km between two lat/lng points. Exposed
/// for tests; identical math to the seller model's internal method.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180.0;
  final dLng = (lng2 - lng1) * math.pi / 180.0;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180.0) *
          math.cos(lat2 * math.pi / 180.0) *
          math.sin(dLng / 2) * math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

/// Single, app-wide fish-search stream. One Firestore subscription,
/// one `StreamController`, one set of upstream listeners — shared
/// across every consumer. The query is fed in via
/// [searchQueryProvider] so consumers change only that value to
/// trigger a re-filter against the already-loaded buffers.
final fishSearchProvider = StreamProvider<FishSearchResults>((ref) {
  final controller = StreamController<FishSearchResults>.broadcast();

  // Mutable buffers fed by the three upstream listeners.
  List<FishListingModel> listings = const [];
  List<StreetSellerModel> sellers = const [];
  ({double lat, double lng})? buyer;

  // Upstream readiness flags — see file comment.
  bool listingsReady = false;
  bool sellersReady = false;
  bool locationReady = false;

  // Cached query — we look this up on every `emit()` so changing
  // `searchQueryProvider` is enough to re-filter.
  String activeQuery = '';

  void emit() {
    // Hold back the first emission until every upstream has spoken
    // at least once. Without this gate the search screen would
    // flash "No sellers have X" for a frame between the listings
    // and sellers ticks.
    if (!(listingsReady && sellersReady && locationReady)) {
      return;
    }

    final q = normalizeSearchQuery(activeQuery);
    if (q == null) {
      if (!controller.isClosed) controller.add(const <FishSearchResult>[]);
      return;
    }

    // 1. Drop listings that aren't currently buyable (sold,
    //    expired, out of stock).
    final buyable = listings.where(listingIsSearchable).toList();

    // 2. Filter by the search query.
    final matching = buyable
        .where((l) => listingMatchesSearchQuery(l, q))
        .toList();

    // 3. Seller lookup restricted to active sellers.
    final byId = <String, StreetSellerModel>{
      for (final s in sellers)
        if (s.isActive) s.sellerId: s,
    };

    // 4. Pair each matching listing with its seller.
    final pairs = <FishListingWithSeller>[];
    for (final l in matching) {
      final seller = byId[l.sellerId];
      if (seller == null) continue;
      final distance = (buyer != null)
          ? haversineKm(
              seller.latitude,
              seller.longitude,
              buyer!.lat,
              buyer!.lng,
            )
          : 0.0;
      pairs.add(FishListingWithSeller(
        listing: l,
        seller: seller,
        distanceKm: distance,
      ));
    }

    // 5. Group by fish type.
    final grouped = <String, List<FishListingWithSeller>>{};
    for (final p in pairs) {
      grouped.putIfAbsent(p.listing.fishType, () => []).add(p);
    }

    // 6. Build the result list.
    final results = grouped.entries.map((entry) {
      final group = entry.value
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      final raw = entry.key;
      final display =
          raw.isEmpty ? raw : raw[0].toUpperCase() + raw.substring(1);
      return FishSearchResult(
        fishType: raw,
        displayName: display,
        listings: group,
      );
    }).toList();

    // 7. Online sellers first, then by distance.
    results.sort((a, b) {
      if (a.anyOnline != b.anyOnline) {
        return a.anyOnline ? -1 : 1;
      }
      return a.closestDistanceKm.compareTo(b.closestDistanceKm);
    });

    if (!controller.isClosed) controller.add(results);
  }

  // Upstream: listings.
  ref.listen(activeListingsProvider, (_, next) {
    final value = next.valueOrNull;
    if (value != null) {
      listings = value;
      listingsReady = true;
      emit();
    }
  }, fireImmediately: true);

  // Upstream: sellers (every active seller, online or offline).
  ref.listen(activeStreetSellersProviderRemote, (_, next) {
    final value = next.valueOrNull;
    if (value != null) {
      sellers = value;
      sellersReady = true;
      emit();
    }
  }, fireImmediately: true);

  // Upstream: buyer location.
  ref.listen(currentBuyerLocationProvider, (_, next) {
    final loc = next.valueOrNull;
    if (loc != null) {
      buyer = (lat: loc.latitude, lng: loc.longitude);
      locationReady = true;
      emit();
    }
  }, fireImmediately: true);

  // Upstream: search query. Cheapest of the four — pure state, no
  // Firestore round-trip.
  ref.listen<String>(searchQueryProvider, (_, next) {
    activeQuery = next;
    emit();
  }, fireImmediately: true);

  ref.onDispose(controller.close);
  return controller.stream;
});