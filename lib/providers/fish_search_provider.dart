// Streams the buyer's fish-name search results.
//
// Pipeline:
//
//   activeListingsProvider × liveSellersProvider × currentBuyerLocationProvider
//          │                       │                       │
//          └────────────┬──────────┴───────────┬───────────┘
//                       ▼                      ▼
//            ┌── query filter ──┐    ┌── group by fish type ──┐
//            ▼                  ▼    ▼                        ▼
//        FishSearchResult stream (real-time)
//
// Results are sorted: anyOnline first, then by closest match
// ([FishSearchResult.closestDistanceKm]).

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

/// Great-circle distance in km between two lat/lng points. Exposed
/// for tests; identical math to the seller model's internal method.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180.0;
  final dLng = (lng2 - lng1) * math.pi / 180.0;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180.0) *
          math.cos(lat2 * math.pi / 180.0) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

/// Real-time fish search. Combines the three upstream streams into a
/// single broadcast stream that re-emits whenever any of them changes.
final fishSearchProvider =
    StreamProvider.family<FishSearchResults, String>((ref, query) {
  final q = normalizeSearchQuery(query);
  if (q == null) return Stream.value(const <FishSearchResult>[]);

  final controller = StreamController<FishSearchResults>();
  List<FishListingModel> listings = const [];
  List<StreetSellerModel> sellers = const [];
  ({double lat, double lng})? buyer;

  void emit() {
    // 1. Filter listings by query.
    final matching = listings
        .where((l) => listingMatchesSearchQuery(l, q))
        .toList();

    // 2. Quick seller lookup.
    final byId = <String, StreetSellerModel>{
      for (final s in sellers) s.sellerId: s,
    };

    // 3. Pair each matching listing with its seller.
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

    // 4. Group by fish type.
    final grouped = <String, List<FishListingWithSeller>>{};
    for (final p in pairs) {
      grouped.putIfAbsent(p.listing.fishType, () => []).add(p);
    }

    // 5. Build the result list.
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

    // 6. Online sellers first, then by distance.
    results.sort((a, b) {
      if (a.anyOnline != b.anyOnline) {
        return a.anyOnline ? -1 : 1;
      }
      return a.closestDistanceKm.compareTo(b.closestDistanceKm);
    });

    controller.add(results);
  }

  // React to upstream changes via Riverpod's `ref.listen`. We use
  // `fireImmediately: true` so the first frame after the user types
  // doesn't have to wait for the next upstream tick.
  ref.listen(activeListingsProvider, (_, next) {
    final value = next.valueOrNull;
    if (value != null) {
      listings = value;
      emit();
    }
  }, fireImmediately: true);

  ref.listen(liveSellersProvider, (_, next) {
    final value = next.valueOrNull;
    if (value != null) {
      sellers = value;
      emit();
    }
  }, fireImmediately: true);

  ref.listen(currentBuyerLocationProvider, (_, next) {
    final loc = next.valueOrNull;
    if (loc == null) {
      buyer = null;
    } else {
      buyer = (lat: loc.latitude, lng: loc.longitude);
    }
    emit();
  }, fireImmediately: true);

  ref.onDispose(controller.close);
  return controller.stream;
});
