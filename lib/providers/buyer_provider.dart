// Buyer Dashboard state management.
//
// ── Session-isolation contract ────────────────────────────────────────────────
// All buyer-scoped state is derived from `currentBuyerSessionProvider`, which
// in turn is built from the auth state (`currentUserStreamProvider`).
// If the auth user changes (sign-out, role switch, account swap), every
// downstream buyer provider recomputes and re-seeds the state with a fresh
// `BuyerDashboardState(buyerId: <newId>)`. A state whose `buyerId` does not
// match the current session is treated as stale and dropped.
//
// ── Real-time readiness ──────────────────────────────────────────────────────
// The marketplace stream (`buyerFishFeedProvider`) is a Firestore snapshot
// stream, so any change to a listing (status, stock, broker approval) is
// reflected in the UI within a few hundred ms with no manual refresh.
// `FishItemModel.isBuyable` is the single source of truth for visibility —
// if a fish runs out of stock, the stream emits the new list and the UI
// drops the item automatically. The dashboard summary derives its
// "fishAvailableNearby" from this same stream.

import 'dart:async';
import 'dart:math' as math;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/buyer_dashboard_state.dart';
import '../models/fish_item_model.dart';
import '../models/fish_request_model.dart';
import '../models/street_seller_model.dart';
import '../models/enums/fish_type.dart';
import '../models/enums/user_role.dart';
import '../models/user_model.dart';
import '../services/buyer_dashboard_service.dart';
import '../utils/logger.dart';
import 'auth_provider.dart';
import 'seller_location_provider.dart'
    show activeStreetSellersProviderRemote;

// ── Service provider ──────────────────────────────────────────────────────────
final buyerDashboardServiceProvider = Provider<BuyerDashboardService>(
  (ref) => BuyerDashboardService(),
);

// ── Session guard ─────────────────────────────────────────────────────────────

/// The buyer session the dashboard is bound to. Recomputed whenever the
/// auth user changes OR the user's role is no longer `buyer`. Reading this
/// provider is the gate that every other buyer provider goes through.
class BuyerSession {
  final String buyerId;
  final UserModel? user;
  const BuyerSession({required this.buyerId, this.user});

  bool get isValid => buyerId.isNotEmpty && user?.role == UserRole.buyer;
}

/// Resolves the current auth user into a `BuyerSession`. Returns `null`
/// when nobody is signed in OR the signed-in user is not a buyer (e.g. they
/// signed in on a different role's device and a stale token remained). This
/// is the single isolation point — downstream providers key off its value
/// and Riverpod auto-invalidates the whole buyer graph on user swap.
final currentBuyerSessionProvider = Provider<BuyerSession?>((ref) {
  final authUser = ref.watch(currentUserProvider);
  final userAsync = ref.watch(currentUserStreamProvider);
  final user = userAsync.valueOrNull;

  if (authUser == null) return null;
  if (user == null) {
    // Auth token exists but the profile doc hasn't loaded yet — don't
    // expose partial data, but also don't crash providers that watch us.
    return null;
  }
  if (user.role != UserRole.buyer) {
    // A non-buyer is signed in. Hand them back null so buyer-specific
    // screens render their own "wrong role" guard.
    return null;
  }
  return BuyerSession(buyerId: user.userId, user: user);
});

// ── Marketplace feed ──────────────────────────────────────────────────────────

/// All broker-approved, active, in-stock fish. This is the raw feed the
/// dashboard "Fish Available Nearby" tile reads. The near-filter (radius
/// from buyer's location) is layered on top in `buyerDashboardProvider`.
/// Public to every signed-in user — fish inventory is the same regardless
/// of who's looking at the dashboard (the buyer's own seller can also
/// benefit from seeing the catalog).
final buyerFishFeedProvider = StreamProvider<List<FishItemModel>>((ref) {
  final service = ref.watch(buyerDashboardServiceProvider);
  // Try to scope by the signed-in buyer's location; otherwise fall back
  // to the unfiltered feed. The stream always emits when Firestore is
  // available, regardless of session.
  final session = ref.watch(currentBuyerSessionProvider);
  final lat = session?.user?.location?['latitude'] as double?;
  final lng = session?.user?.location?['longitude'] as double?;
  final Stream<List<FishItemModel>> source = (lat != null && lng != null)
      ? service.streamApprovedFishNear(lat, lng)
      : service.streamApprovedFish();
  // A malformed listing doc, missing index, or transient permission
  // error must not crash the dashboard. Swallow the error so the
  // stream keeps a usable (empty) state instead of stalling in an
  // unrecoverable error branch.
  return source.handleError((Object e, StackTrace s) {
    AppLogger.warning('buyerFishFeedProvider error: $e');
  });
});

// ── This buyer's active fish requests ────────────────────────────────────────

final buyerActiveRequestsProvider =
    StreamProvider<List<FishRequestModel>>((ref) {
  final session = ref.watch(currentBuyerSessionProvider);
  if (session == null) return const Stream.empty();
  final service = ref.watch(buyerDashboardServiceProvider);
  return service.streamRequestsForBuyer(session.buyerId).map((all) =>
      all.where((r) => r.countsAsActive).toList());
});

/// All fish requests owned by this buyer, regardless of status. Powers
/// the "My Requests" screen's Active + History tabs.
final buyerAllRequestsProvider =
    StreamProvider<List<FishRequestModel>>((ref) {
  final session = ref.watch(currentBuyerSessionProvider);
  if (session == null) return const Stream.empty();
  final service = ref.watch(buyerDashboardServiceProvider);
  return service.streamRequestsForBuyer(session.buyerId);
});

// ── Recent searches (per-buyer, capped) ───────────────────────────────────────

final buyerRecentSearchesProvider =
    StreamProvider<List<RecentSearch>>((ref) {
  final session = ref.watch(currentBuyerSessionProvider);
  if (session == null) return const Stream.empty();
  final service = ref.watch(buyerDashboardServiceProvider);
  return service
      .streamRecentSearches(session.buyerId)
      .map((raw) => raw.map(RecentSearch.fromMap).toList());
});

// ── Active street sellers (read-only) ─────────────────────────────────────────
//
// Re-exported alias: `activeStreetSellersProviderRemote` is the single
// app-wide Firestore subscription for the seller list, defined in
// `seller_location_provider.dart`. We keep the older name exported
// here so existing widgets (`buyerDashboardProvider`,
// `summary_header.dart`, `map_filter_model.dart`, `buyer_map_screen`)
// continue to compile, but every consumer now reads from the
// SAME Firestore handle — no duplicate subscriptions.

final activeStreetSellersProvider = Provider<AsyncValue<List<StreetSellerModel>>>(
  (ref) => ref.watch(activeStreetSellersProviderRemote),
);

// ── Aggregated dashboard state ────────────────────────────────────────────────

/// The single source of truth the UI reads. Combines the four streams above
/// into a `BuyerDashboardState`. Recomputes whenever:
///   - the auth user changes (session swap → brand new state),
///   - the buyer's profile (location) changes,
///   - the marketplace / requests / searches / sellers streams tick.
final buyerDashboardProvider =
    Provider<AsyncValue<BuyerDashboardState>>((ref) {
  final session = ref.watch(currentBuyerSessionProvider);

  final fish = ref.watch(buyerFishFeedProvider);
  final requests = ref.watch(buyerActiveRequestsProvider);
  final searches = ref.watch(buyerRecentSearchesProvider);
  final sellers = ref.watch(activeStreetSellersProvider);

  // Per-stream readiness tracking. Earlier versions of this provider
  // returned `AsyncValue.loading` whenever any stream was still
  // loading, which made the dashboard numbers show `0` while data was
  // being prepared. We now emit `data` as soon as at least the
  // *sellers* and *fish* feeds have produced something, even if the
  // requests / searches streams are still warming up. Both are loaded
  // synchronously from Firestore snapshots; the difference matters
  // when the device is offline or when Firestore permissions are
  // being checked.
  final anyError = fish.hasError || requests.hasError ||
      searches.hasError || sellers.hasError;

  if (anyError) {
    final firstError = fish.error ?? requests.error ??
        searches.error ??
        sellers.error;
    AppLogger.warning(
      'buyerDashboardProvider: at least one upstream stream errored: $firstError',
    );
    // We still try to render whatever data is available.
  }

  // We only block the dashboard on the streams that *every* tile
  // needs. The requests / searches feeds are private to the signed-in
  // buyer — if there's no session, they're irrelevant.
  final coreReady = !fish.isLoading || fish.hasValue;
  final sellersReady = !sellers.isLoading || sellers.hasValue;
  if (!coreReady || !sellersReady) {
    return const AsyncValue.loading();
  }

  final buyerLat = session?.user?.location?['latitude'] as double?;
  final buyerLng = session?.user?.location?['longitude'] as double?;

  return AsyncValue.data(
    BuyerDashboardState(
      buyerId: session?.buyerId ?? '',
      fishAvailableNearby: fish.valueOrNull ?? const [],
      activeRequests: requests.valueOrNull ?? const [],
      recentSearches: searches.valueOrNull ?? const [],
      nearbySellers: sellers.valueOrNull ?? const [],
      buyerLatitude: buyerLat,
      buyerLongitude: buyerLng,
    ),
  );
});

// ── Write-side controllers (Notifier) ─────────────────────────────────────────

/// Notifier for actions the buyer can take from the dashboard:
///   - record a search (de-duped, capped at 10 by the service query),
///   - post a new fish request,
///   - cancel an active request.
class BuyerDashboardController extends StateNotifier<BuyerDashboardState?> {
  BuyerDashboardController(this._ref)
      : super(null);

  final Ref _ref;

  BuyerDashboardService get _service =>
      _ref.read(buyerDashboardServiceProvider);

  /// Look up the current session and refuse to act if it's not a buyer.
  /// Returns the buyerId, or null if the caller is not authorized.
  String? _requireSession() {
    final session = _ref.read(currentBuyerSessionProvider);
    if (session == null || !session.isValid) return null;
    // If the cached state is for a different buyer, drop it. This is the
    // line of defense against a stale `BuyerDashboardState` being written
    // into the wrong account.
    final cached = state;
    if (cached != null && !cached.belongsTo(session.buyerId)) {
      state = BuyerDashboardState.empty(session.buyerId);
    }
    return session.buyerId;
  }

  Future<void> recordSearch(String query, {int resultCount = 0}) async {
    final buyerId = _requireSession();
    if (buyerId == null) return;
    try {
      await _service.recordSearch(
        buyerId: buyerId,
        query: query,
        resultCount: resultCount,
      );
    } catch (e) {
      AppLogger.error('recordSearch failed: $e');
    }
  }

  Future<String?> createFishRequest({
    required FishType fishType,
    String customFishName = '',
    required double quantityKg,
    double? maxPricePerKg,
    String? notes,
    String? regionName,
    String? marketName,
    DateTime? needsBy,
    bool deliveryRequired = false,
  }) async {
    final buyerId = _requireSession();
    if (buyerId == null) return null;
    final now = DateTime.now();
    final request = FishRequestModel(
      requestId: '',
      buyerId: buyerId,
      fishType: fishType,
      customFishName: customFishName,
      quantityKg: quantityKg,
      maxPricePerKg: maxPricePerKg,
      notes: notes,
      regionName: regionName,
      marketName: marketName,
      needsBy: needsBy,
      deliveryRequired: deliveryRequired,
      createdAt: now,
      updatedAt: now,
    );
    try {
      final id = await _service.createRequest(request);
      return id;
    } catch (e) {
      AppLogger.error('createFishRequest failed: $e');
      return null;
    }
  }

  Future<void> cancelFishRequest(String requestId) async {
    final buyerId = _requireSession();
    if (buyerId == null) return;
    try {
      await _service.cancelRequest(requestId);
    } catch (e) {
      AppLogger.error('cancelFishRequest failed: $e');
    }
  }
}

final buyerDashboardControllerProvider = StateNotifierProvider<
    BuyerDashboardController, BuyerDashboardState?>((ref) {
  return BuyerDashboardController(ref);
});

// ── Convenience selectors (so widgets don't need to re-derive) ────────────────

/// Count of "Fish Available Nearby" — powers the dashboard summary tile.
final nearbyFishCountProvider = Provider<int>((ref) {
  return ref.watch(buyerDashboardProvider).valueOrNull?.fishCount ?? 0;
});

/// Count of "Active Requests" — powers the dashboard summary tile.
final activeRequestsCountProvider = Provider<int>((ref) {
  return ref.watch(buyerDashboardProvider).valueOrNull?.activeRequestCount ?? 0;
});

/// Whether the buyer has set a location yet (controls the "set your location"
/// prompt vs. the "nearby" list).
final buyerHasLocationProvider = Provider<bool>((ref) {
  return ref.watch(buyerDashboardProvider).valueOrNull?.hasLocation ?? false;
});

// ── Phase 3 selectors (summary header + browse + recommendations) ────────────

/// A "Fish Available Nearby" entry enriched with the seller's name and the
/// distance from the buyer's location, ready to feed browse cards.
class NearbyFishEntry {
  final FishItemModel item;
  final String? sellerName;
  final double? distanceKm;
  const NearbyFishEntry({
    required this.item,
    this.sellerName,
    this.distanceKm,
  });
}

/// The single nearest seller relative to the buyer. `null` if the buyer
/// has no location or no sellers are loaded. Used by the "Nearest Seller"
/// tile in the summary header.
class NearestSeller {
  final StreetSellerModel seller;
  final double distanceKm;
  final int? fishCount; // fish items that the seller currently lists
  const NearestSeller({
    required this.seller,
    required this.distanceKm,
    this.fishCount,
  });
}

final nearestSellerProvider = Provider<NearestSeller?>((ref) {
  final dash = ref.watch(buyerDashboardProvider).valueOrNull;
  if (dash == null) return null;
  if (dash.buyerLatitude == null || dash.buyerLongitude == null) return null;
  if (dash.nearbySellers.isEmpty) return null;

  final fishByBroker = <String, int>{};
  for (final f in dash.fishAvailableNearby) {
    fishByBroker[f.sellerId] = (fishByBroker[f.sellerId] ?? 0) + 1;
  }

  final sorted = [...dash.nearbySellers]..sort(
        (a, b) => a.distanceKmFrom(
              dash.buyerLatitude!,
              dash.buyerLongitude!,
            ).compareTo(
              b.distanceKmFrom(
                dash.buyerLatitude!,
                dash.buyerLongitude!,
              ),
            ),
      );
  final closest = sorted.first;
  return NearestSeller(
    seller: closest,
    distanceKm: closest.distanceKmFrom(
      dash.buyerLatitude!,
      dash.buyerLongitude!,
    ),
    fishCount: fishByBroker[closest.sellerId],
  );
});

/// Browse-list data: every buyable fish nearby, enriched with seller
/// info + distance. Sorted by distance ascending (closest first).
final nearbyFishListProvider = Provider<List<NearbyFishEntry>>((ref) {
  final dash = ref.watch(buyerDashboardProvider).valueOrNull;
  if (dash == null) return const [];

  // Build a quick seller-by-id lookup.
  final sellerById = {for (final s in dash.nearbySellers) s.sellerId: s};
  final brokerName = {for (final s in dash.nearbySellers) s.sellerId: s.fullName};

  final entries = dash.fishAvailableNearby
      .map((item) => NearbyFishEntry(
            item: item,
            sellerName: brokerName[item.sellerId] ??
                (sellerById[item.sellerId]?.fullName),
            distanceKm: (dash.buyerLatitude != null &&
                    dash.buyerLongitude != null &&
                    item.latitude != null &&
                    item.longitude != null)
                ? _haversineKm(
                    dash.buyerLatitude!,
                    dash.buyerLongitude!,
                    item.latitude!,
                    item.longitude!,
                  )
                : null,
          ))
      .toList();
  entries.sort((a, b) {
    final da = a.distanceKm ?? double.infinity;
    final db = b.distanceKm ?? double.infinity;
    return da.compareTo(db);
  });
  return entries;
});

/// "Popular Near You" — the fish types most frequently listed by sellers
/// in the buyer's area. In production this would use real order-history
/// signals; the local heuristic is "fish type with the most listings
/// among nearby brokers".
class PopularFish {
  final String fishName;
  final int listingCount;
  final double? lowestPricePerKg;
  final String? imageUrl;
  const PopularFish({
    required this.fishName,
    required this.listingCount,
    this.lowestPricePerKg,
    this.imageUrl,
  });
}

final popularNearbyFishProvider = Provider<List<PopularFish>>((ref) {
  final dash = ref.watch(buyerDashboardProvider).valueOrNull;
  if (dash == null) return const [];

  // Group listings by fish type. We only consider fish within the buyer's
  // 10km radius (which is the same radius used by buyerFishFeedProvider).
  final byType = <String, List<FishItemModel>>{};
  for (final f in dash.fishAvailableNearby) {
    if (f.latitude == null || f.longitude == null) continue;
    if (dash.buyerLatitude == null || dash.buyerLongitude == null) continue;
    final dist = _haversineKm(
      dash.buyerLatitude!,
      dash.buyerLongitude!,
      f.latitude!,
      f.longitude!,
    );
    if (dist > 10.0) continue;
    byType.putIfAbsent(f.fishType.value, () => []).add(f);
  }
  final entries = byType.entries.map((e) {
    final prices =
        e.value.map((i) => i.pricePerKg).toList()..sort();
    return PopularFish(
      fishName: e.value.first.displayName,
      listingCount: e.value.length,
      lowestPricePerKg: prices.isEmpty ? null : prices.first,
      imageUrl: e.value.first.imageUrls.isEmpty
          ? null
          : e.value.first.imageUrls.first,
    );
  }).toList();
  entries.sort((a, b) => b.listingCount.compareTo(a.listingCount));
  return entries.take(8).toList();
});

/// Autocomplete suggestions for the search bar. Returns up to 8 matches
/// across fish name, custom name, and the Swahili/common synonyms
/// ("Changu" for Tuna, "Kambale" for Grouper, etc.).
class SearchSuggestion {
  final String label;
  final String? fishTypeValue; // null = "any of these"
  final String? imageUrl;
  const SearchSuggestion({
    required this.label,
    this.fishTypeValue,
    this.imageUrl,
  });
}

/// Map of Swahili common-names → enum value. Drives the autocomplete
/// case where the buyer types "Changu" but the app stores "Tuna".
const Map<String, FishType> _swahiliSynonyms = {
  'changu': FishType.tuna,
  'jodari': FishType.tuna,
  'tuna': FishType.tuna,
  'tilapia': FishType.tilapia,
  'sardini': FishType.sardine,
  'sardine': FishType.sardine,
  'kambale': FishType.grouper,
  'grouper': FishType.grouper,
  'mackerel': FishType.mackerel,
  'mkeleli': FishType.mackerel,
  'snapper': FishType.snapper,
  'kolekole': FishType.snapper,
};

final searchSuggestionsProvider =
    Provider.family<List<SearchSuggestion>, String>((ref, query) {
  final dash = ref.watch(buyerDashboardProvider).valueOrNull;
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  final results = <SearchSuggestion>{};

  // 1. Synonym hit (e.g. "Changu" → Tuna).
  final syn = _swahiliSynonyms[q];
  if (syn != null) {
    results.add(SearchSuggestion(
      label: syn.displayName,
      fishTypeValue: syn.value,
    ));
  }

  // 2. Partial matches against the FishType enum display names.
  for (final t in FishType.values) {
    if (t.displayName.toLowerCase().contains(q)) {
      results.add(SearchSuggestion(
        label: t.displayName,
        fishTypeValue: t.value,
      ));
    }
  }

  // 3. Matches against the actual loaded fish (custom names, descriptions).
  if (dash != null) {
    for (final f in dash.fishAvailableNearby) {
      final inName = f.displayName.toLowerCase().contains(q);
      final inCustom = f.customFishName.toLowerCase().contains(q);
      final inDesc = (f.description ?? '').toLowerCase().contains(q);
      if (inName || inCustom || inDesc) {
        results.add(SearchSuggestion(
          label: f.displayName,
          fishTypeValue: f.fishType.value,
          imageUrl: f.imageUrls.isEmpty ? null : f.imageUrls.first,
        ));
      }
    }
  }

  return results.take(8).toList();
});

// Haversine helper duplicated from routing_service (no cross-file import
// in this project — the math is small enough to keep self-contained).
double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
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

double _deg2rad(double d) => d * (math.pi / 180.0);
