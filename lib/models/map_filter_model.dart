// Buyer-side filter state for the map. Holds the active fish-type filter
// and a search query; derived providers compose this with the Phase-1
// streams to produce the "sellers who have this fish" list.

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/enums/fish_type.dart';
import '../models/fish_item_model.dart';
import '../models/street_seller_model.dart';
import '../providers/buyer_provider.dart';
import '../services/location_service.dart';
import '../utils/logger.dart';

/// A pair of (seller, matching fish items). The seller is the *place*;
/// the items are what they currently have in stock that matches the
/// filter. Empty `items` means the seller exists but has no matching
/// fish — they are NOT included in the markers list.
class SellerWithFish {
  final StreetSellerModel seller;
  final List<FishItemModel> matchingItems;

  const SellerWithFish({required this.seller, required this.matchingItems});

  /// The single FishItem to show on the marker popover (closest match by
  /// quantity, or the first one if tied).
  FishItemModel get primaryItem {
    if (matchingItems.isEmpty) {
      throw StateError('SellerWithFish has no matching items');
    }
    final sorted = [...matchingItems]
      ..sort((a, b) => b.quantityKg.compareTo(a.quantityKg));
    return sorted.first;
  }

  LatLng get position => LatLng(seller.latitude, seller.longitude);
}

class MapFilter {
  /// null = "all fish types"
  final FishType? fishType;
  final String searchQuery;
  final double radiusKm;

  const MapFilter({
    this.fishType,
    this.searchQuery = '',
    this.radiusKm = 10.0,
  });

  MapFilter copyWith({
    FishType? fishType,
    bool clearFishType = false,
    String? searchQuery,
    double? radiusKm,
  }) {
    return MapFilter(
      fishType: clearFishType ? null : (fishType ?? this.fishType),
      searchQuery: searchQuery ?? this.searchQuery,
      radiusKm: radiusKm ?? this.radiusKm,
    );
  }
}

class MapFilterController extends StateNotifier<MapFilter> {
  MapFilterController() : super(const MapFilter());

  void setFishType(FishType? type) {
    state = state.copyWith(fishType: type, clearFishType: type == null);
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void setRadius(double km) {
    state = state.copyWith(radiusKm: km);
  }

  void reset() {
    state = const MapFilter();
  }
}

final mapFilterControllerProvider =
    StateNotifierProvider<MapFilterController, MapFilter>(
  (ref) => MapFilterController(),
);

/// All sellers, optionally restricted to those whose FishItems match the
/// active filter. Real-time — when a fish goes out of stock the
/// matching-items list shrinks; the seller marker itself stays put.
///
/// This is the single source of truth for the buyer-side map. We read
/// from `activeStreetSellersProvider` (Firestore-backed) and
/// `buyerFishFeedProvider` (Firestore-backed) and merge them into a
/// list of `SellerWithFish` rows. The map screen reads this provider
/// directly, so no other layer can drop sellers.
final sellersWithFishProvider = Provider<List<SellerWithFish>>((ref) {
  final filter = ref.watch(mapFilterControllerProvider);
  final sellersAsync = ref.watch(activeStreetSellersProvider);
  final fishAsync = ref.watch(buyerFishFeedProvider);

  // Read the AsyncValue so we can surface loading/error states.
  // We always render *something* as long as the sellers stream
  // emits — even when the fish feed is still loading.
  final sellers = sellersAsync.valueOrNull ?? const <StreetSellerModel>[];
  final fish = fishAsync.valueOrNull ?? const <FishItemModel>[];

  // Debug: log if we get an empty sellers list so the developer can
  // see *why* (loading vs. no data vs. session missing).
  if (sellers.isEmpty) {
    AppLogger.debug(
      'sellersWithFishProvider: empty sellers. '
      'asyncState=${sellersAsync.isLoading ? "loading" : sellersAsync.hasError ? "error" : "no-data"}, '
      'fishCount=${fish.length}',
    );
  }

  final filterHasText = filter.fishType != null ||
      filter.searchQuery.trim().isNotEmpty;

  // Group matching fish by seller.
  final fishByBroker = <String, List<FishItemModel>>{};
  for (final item in fish) {
    if (!_itemMatchesFilter(item, filter)) continue;
    fishByBroker.putIfAbsent(item.sellerId, () => []).add(item);
  }

  final result = <SellerWithFish>[];
  for (final seller in sellers) {
    // 1:1 mapping in the demo dataset — the seller's `sellerId` is
    // also the broker key in `fishListings`.
    final matches = fishByBroker[seller.sellerId] ?? const [];

    // Only drop a seller when the user actively filtered AND the
    // seller has zero matching items. Without a filter we always
    // show the seller, even before the fish feed has loaded.
    if (filterHasText && matches.isEmpty) continue;
    result.add(SellerWithFish(seller: seller, matchingItems: matches));
  }

  AppLogger.debug(
    'sellersWithFishProvider: ${sellers.length} sellers loaded, '
    '${result.length} will be shown after filter.',
  );

  return result;
});

/// True when no seller in the active area stocks the requested fish.
/// Drives the "no fish available" empty state in the UI.
final noMatchingSellersProvider = Provider<bool>((ref) {
  final filter = ref.watch(mapFilterControllerProvider);
  // Only "no match" if the buyer actually filtered to a specific fish
  // type. "All types" with zero results is a different empty state
  // (just no sellers registered yet).
  if (filter.fishType == null && filter.searchQuery.trim().isEmpty) {
    return false;
  }
  return ref.watch(sellersWithFishProvider).isEmpty;
});

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

// ── Selected-seller state (for routing) ───────────────────────────────────────

class SelectedSellerState {
  final SellerWithFish? selected;
  const SelectedSellerState({this.selected});

  SelectedSellerState copyWith({SellerWithFish? selected, bool clear = false}) {
    return SelectedSellerState(
      selected: clear ? null : (selected ?? this.selected),
    );
  }
}

class SelectedSellerController extends StateNotifier<SelectedSellerState> {
  SelectedSellerController() : super(const SelectedSellerState());

  void select(SellerWithFish seller) {
    state = SelectedSellerState(selected: seller);
  }

  void clear() {
    state = const SelectedSellerState();
  }
}

final selectedSellerControllerProvider =
    StateNotifierProvider<SelectedSellerController, SelectedSellerState>(
  (ref) => SelectedSellerController(),
);

/// Distance from the current buyer location to a given seller, in km.
double distanceFromBuyerKm({
  required BuyerLocation buyer,
  required SellerWithFish seller,
}) {
  return seller.seller.distanceKmFrom(buyer.latitude, buyer.longitude);
}
