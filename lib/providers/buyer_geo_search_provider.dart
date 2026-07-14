// Buyer's geo-radius search for sellers who carry a specific fish.
//
// Pipeline (all real-time Firestore streams + the buyer's GPS):
//
//   1. `currentBuyerLocationProvider`   ──► buyer's live GPS
//   2. `mapFilterControllerProvider`    ──► active fish-type / radius
//   3. `nearbySellersGeoQueryProvider`  ──► geohash-prefixed sellers
//                                          inside the radius
//      (fallback: `activeStreetSellersProviderRemote` when no location)
//   4. `buyerFishFeedProvider`          ──► all buyable fish nearby
//   5. `liveSellersProvider`            ──► currently online sellers
//
// We intersect (3) with (4) + (5), filtered by the active MapFilter.
// For each surviving seller we attach the buyable fish items they
// stock, so the map marker can carry a popover with the primary item,
// exact distance, and online state.

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/fish_item_model.dart';
import '../models/map_filter_model.dart';
import '../models/street_seller_model.dart';
import '../services/location_service.dart';
import 'buyer_provider.dart';
import 'seller_location_provider.dart';

// `SellerWithFish` is defined in `map_filter_model.dart`; re-export it
// here so callers can use `BuyerGeoSearchProvider.nearbySellers` without
// importing a second file.
export '../models/map_filter_model.dart' show SellerWithFish;

/// Parameters for a buyer's radius search.
class BuyerGeoSearchParams {
  final double? buyerLat;
  final double? buyerLng;
  final double radiusKm;

  const BuyerGeoSearchParams({
    this.buyerLat,
    this.buyerLng,
    this.radiusKm = 10.0,
  });

  bool get hasLocation =>
      buyerLat != null && buyerLng != null && radiusKm > 0;

  @override
  bool operator ==(Object other) =>
      other is BuyerGeoSearchParams &&
      other.buyerLat == buyerLat &&
      other.buyerLng == buyerLng &&
      other.radiusKm == radiusKm;

  @override
  int get hashCode => Object.hash(buyerLat, buyerLng, radiusKm);
}

/// The shape the map screen consumes.
class NearbySellerWithFish {
  final StreetSellerModel seller;
  final List<FishItemModel> matchingItems;
  final double distanceKm;
  final bool isOnline;

  const NearbySellerWithFish({
    required this.seller,
    required this.matchingItems,
    required this.distanceKm,
    required this.isOnline,
  });

  FishItemModel get primaryItem => matchingItems.first;
}

/// Convenience: produces a [BuyerGeoSearchParams] from the buyer's
/// current location + the active filter's radius.
final currentBuyerSearchParamsProvider =
    Provider<BuyerGeoSearchParams>((ref) {
  final locAsync = ref.watch(currentBuyerLocationProvider);
  final filter = ref.watch(mapFilterControllerProvider);
  return BuyerGeoSearchParams(
    buyerLat: locAsync.valueOrNull?.latitude,
    buyerLng: locAsync.valueOrNull?.longitude,
    radiusKm: filter.radiusKm,
  );
});

/// Live, real-time results — keyed by (buyer location, radius).
///
/// Implementation note: we expose a `StreamProvider.family` so each
/// (lat, lng, radius) tuple has its own subscription, but inside we
/// compose four `Stream`s into a single broadcast stream. Whenever
/// ANY of them ticks (seller moves into/out of a geohash cell, fish
/// stock updates, a seller goes online, or the filter changes) we
/// recompute the combined list and re-emit.
final nearbySellersWithFishProvider = StreamProvider.family<
    List<NearbySellerWithFish>, BuyerGeoSearchParams>((ref, params) {
  return _compose(ref, params);
});

/// The stream the buyer UI consumes — recomputes whenever the
/// location, filter, fish feed, or seller geohash query ticks.
final currentSellersWithFishProvider =
    Provider<AsyncValue<List<NearbySellerWithFish>>>((ref) {
  final params = ref.watch(currentBuyerSearchParamsProvider);
  return ref.watch(nearbySellersWithFishProvider(params));
});

/// Adapter: the new combined-search results projected onto the legacy
/// `SellerWithFish` shape that the existing Phase-2 `SellerMap` widget
/// and selection controller consume. We don't change those widgets —
/// they already understand `StreetSellerModel` + matched `FishItemModel`
/// — we just bridge the new `NearbySellerWithFish` into it.
final nearbySellerWithFishAsLegacyProvider =
    Provider<AsyncValue<List<SellerWithFish>>>((ref) {
  final async = ref.watch(currentSellersWithFishProvider);
  return async.whenData((rows) {
    return rows
        .map((r) => SellerWithFish(
              seller: r.seller,
              matchingItems: r.matchingItems,
            ))
        .toList();
  });
});

/// Same projection as [nearbySellerWithFishAsLegacyProvider] but exposed
/// as a `List<SellerWithFish>` once data is loaded — convenience for
/// widgets that don't want to handle the AsyncValue themselves.
final nearbySellerWithFishAsLegacyListProvider =
    Provider<List<SellerWithFish>>((ref) {
  return ref.watch(nearbySellerWithFishAsLegacyProvider).valueOrNull ??
      const [];
});

/// Distance from the buyer's current GPS to a given seller, in km.
double distanceFromBuyerKm({
  required BuyerLocation buyer,
  required NearbySellerWithFish entry,
}) {
  return entry.seller.distanceKmFrom(buyer.latitude, buyer.longitude);
}

// ── Internals ────────────────────────────────────────────────────────────────

Stream<List<NearbySellerWithFish>> _compose(
  Ref ref,
  BuyerGeoSearchParams params,
) {
  // We want this provider to fire whenever:
  //   (a) the [params] family key changes, OR
  //   (b) the seller geohash stream emits, OR
  //   (c) the fish feed emits, OR
  //   (d) the live-sellers presence stream emits, OR
  //   (e) the filter state changes.
  //
  // Riverpod already gives us (a) by re-running the family body, and
  // (b)/(c)/(d)/(e) re-emit through `ref.listen` inside `_combine`.
  // Inside, we just bridge each provider to a Stream<AsyncValue> and
  // re-combine on every tick.

  final sellerProvider = params.hasLocation
      ? nearbySellersGeoQueryProvider(
          GeoSearchParams(
            latitude: params.buyerLat!,
            longitude: params.buyerLng!,
            radiusKm: params.radiusKm,
          ),
        )
      : activeStreetSellersProviderRemote;

  // Combine four signal streams into one. Each provider tick triggers
  // a fresh `combine()` invocation. We debounce with a microtask so
  // concurrent ticks produce only one downstream event.
  late final List<StreamController<void>> pumps;
  late final List<ProviderSubscription<dynamic>> subs;
  late final StreamController<List<NearbySellerWithFish>> out;
  late Timer debounce;

  out = StreamController<List<NearbySellerWithFish>>.broadcast();

  void recompute() {
    debounce.cancel();
    debounce = Timer(const Duration(milliseconds: 16), () {
      // Microtask: collect latest tick from each provider and emit.
      final sellers = ref.read(sellerProvider).valueOrNull ??
          const <StreetSellerModel>[];
      final fishAsync = ref.read(buyerFishFeedProvider);
      final liveAsync = ref.read(liveSellersProvider);
      final filter = ref.read(mapFilterControllerProvider);
      final result = _combine(
        sellers,
        fishAsync,
        liveAsync,
        filter,
        params,
      );
      if (!out.isClosed) out.add(result);
    });
  }

  pumps = [];
  subs = [];

  /// Subscribe to any provider and pump our recompute on every tick.
  /// Generic over the listenable type — works for both
  /// `StreamProvider` (`AsyncValue<T>`) and `StateNotifierProvider`
  /// (`MapFilter`) without specialised overloads.
  void pumpFor<T>(ProviderListenable<T> provider) {
    final pump = StreamController<void>.broadcast();
    pumps.add(pump);
    final sub = ref.listen<T>(
      provider,
      (_, __) => pump.add(null),
      fireImmediately: true,
    );
    subs.add(sub);
    pump.stream.listen((_) => recompute());
  }

  pumpFor(sellerProvider);
  pumpFor(buyerFishFeedProvider);
  pumpFor(liveSellersProvider);
  pumpFor(mapFilterControllerProvider);

  ref.onDispose(() {
    debounce.cancel();
    for (final s in subs) {
      s.close();
    }
    for (final p in pumps) {
      p.close();
    }
    out.close();
  });

  return out.stream;
}

List<NearbySellerWithFish> _combine(
  List<StreetSellerModel> sellers,
  AsyncValue<List<FishItemModel>> fishAsync,
  AsyncValue<List<StreetSellerModel>> liveAsync,
  MapFilter filter,
  BuyerGeoSearchParams params,
) {
  final fish = fishAsync.valueOrNull ?? const <FishItemModel>[];
  final filterHasText = filter.fishType != null ||
      filter.searchQuery.trim().isNotEmpty;

  final itemsBySeller = <String, List<FishItemModel>>{};
  for (final item in fish) {
    if (!_itemMatchesFilter(item, filter)) continue;
    itemsBySeller.putIfAbsent(item.sellerId, () => []).add(item);
  }

  final onlineIds = <String>{
    for (final s in liveAsync.valueOrNull ?? const <StreetSellerModel>[])
      s.sellerId,
  };

  final out = <NearbySellerWithFish>[];
  for (final s in sellers) {
    final matches = itemsBySeller[s.sellerId] ?? const <FishItemModel>[];
    if (filterHasText && matches.isEmpty) continue;
    final distanceKm = params.hasLocation
        ? s.distanceKmFrom(params.buyerLat!, params.buyerLng!)
        : double.nan;
    out.add(NearbySellerWithFish(
      seller: s,
      matchingItems: matches,
      distanceKm: distanceKm,
      isOnline: onlineIds.contains(s.sellerId) || s.isOnline,
    ));
  }
  out.sort((a, b) {
    if (a.distanceKm.isNaN && b.distanceKm.isNaN) return 0;
    if (a.distanceKm.isNaN) return 1;
    if (b.distanceKm.isNaN) return -1;
    return a.distanceKm.compareTo(b.distanceKm);
  });
  return out;
}

bool _itemMatchesFilter(FishItemModel item, MapFilter filter) {
  if (filter.fishType != null && item.fishType != filter.fishType) {
    return false;
  }
  if (filter.searchQuery.trim().isNotEmpty) {
    final q = filter.searchQuery.toLowerCase();
    final inName = item.displayName.toLowerCase().contains(q);
    final inDesc = (item.description ?? '').toLowerCase().contains(q);
    if (!inName && !inDesc) return false;
  }
  return true;
}