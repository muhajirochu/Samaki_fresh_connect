// Buyer Map screen — Phase 2 main entry point.
//
// Features:
//   - OpenStreetMap (flutter_map) showing the buyer's location and every
//     nearby street seller that stocks the requested fish.
//   - Tap a marker → draw route + show distance/ETA card.
//   - Filter the markers by fish type (chip row at the top).
//   - Empty-state with the spec-mandated Swahili message when no seller
//     has the fish.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../constants/app_sizes.dart';
import '../../models/enums/fish_type.dart';
import '../../models/fish_item_model.dart';
import '../../models/map_filter_model.dart';
import '../../models/street_seller_model.dart';
import '../../providers/buyer_geo_search_provider.dart';
import '../../providers/route_provider.dart';
import '../../providers/seller_location_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/map/empty_map_state.dart';
import '../../widgets/map/route_info_card.dart';
import '../../widgets/map/seller_map.dart';
import '../../widgets/requests/send_request_sheet.dart';

class BuyerMapScreen extends ConsumerStatefulWidget {
  /// Optional pre-selected fish type. Used when the buyer arrives via a
  /// search-result tile.
  final FishType? initialFishType;
  final String? initialSearchQuery;
  final String? initialSellerId;

  const BuyerMapScreen({
    super.key,
    this.initialFishType,
    this.initialSearchQuery,
    this.initialSellerId,
  });

  @override
  ConsumerState<BuyerMapScreen> createState() => _BuyerMapScreenState();
}

class _BuyerMapScreenState extends ConsumerState<BuyerMapScreen> {
  late final TextEditingController _searchCtrl;
  bool _hasAutoSelected = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialSearchQuery ?? '');
    // Seed the filter once the widget tree is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier =
          ref.read(mapFilterControllerProvider.notifier);
      if (widget.initialFishType != null) {
        notifier.setFishType(widget.initialFishType);
      }
      if (widget.initialSearchQuery != null &&
          widget.initialSearchQuery!.isNotEmpty) {
        notifier.setSearchQuery(widget.initialSearchQuery!);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buyerLocAsync = ref.watch(currentBuyerLocationProvider);

    // Cascade read across three providers in order of preference.
    //
    //   1. `sellersWithFishProvider` — the Phase-2 single source of
    //      truth in `map_filter_model.dart`. Fires as soon as the
    //      `activeStreetSellersProvider` Firestore stream emits.
    //   2. `nearbySellerWithFishAsLegacyProvider` — the older geo-
    //      query path. Useful as a fallback when the primary is
    //      empty (e.g. before the buyer session is resolved).
    //   3. `_unfilteredSellersProvider` — bare-metal fallback that
    //      ignores the buyer session and the fish feed. Defined at
    //      the bottom of this file.
    //
    // Whichever is non-empty wins. The map is never blank as long as
    // Firestore has at least one seller doc.
    final primary = ref.watch(sellersWithFishProvider);
    final legacy = ref.watch(nearbySellerWithFishAsLegacyProvider).valueOrNull ??
        const <SellerWithFish>[];
    final unfiltered =
        ref.watch(_unfilteredSellersProvider).valueOrNull ?? const <SellerWithFish>[];

    List<SellerWithFish> sellersWithFish;
    if (primary.isNotEmpty) {
      sellersWithFish = primary;
    } else if (legacy.isNotEmpty) {
      sellersWithFish = legacy;
    } else {
      sellersWithFish = unfiltered;
    }
    
    // Auto-select seller if provided in route
    if (widget.initialSellerId != null && !_hasAutoSelected && sellersWithFish.isNotEmpty) {
      final match = sellersWithFish
          .where((s) => s.seller.sellerId == widget.initialSellerId)
          .firstOrNull;
      if (match != null) {
        _hasAutoSelected = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(selectedSellerControllerProvider.notifier).select(match);
          }
        });
      }
    }

    final selection = ref.watch(selectedSellerControllerProvider).selected;
    final routeAsync = ref.watch(activeRouteProvider);

    final noMatches = ref.watch(noMatchingSellersProvider);
    final cs = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.sellersMapTitle),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: l10n.showAllTypes,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(mapFilterControllerProvider.notifier).reset();
              _searchCtrl.clear();
              ref.read(selectedSellerControllerProvider.notifier).clear();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map (or fallback) ────────────────────────────────────────────
          Positioned.fill(
            child: () {
              // Decide the camera "you are here" point:
              //   1. Use the buyer's resolved GPS / profile location
              //      if available.
              //   2. Otherwise fall back to Stone Town so the map
              //      still renders something meaningful while the
              //      GPS lookup is in flight. This is critical — the
              //      previous behaviour showed a spinner until the
              //      location provider resolved, even when sellers
              //      were already loaded.
              final resolvedLoc = buyerLocAsync.valueOrNull;
              final fallbackLoc = resolvedLoc ??
                  const BuyerLocation(
                    latitude: -6.1629,
                    longitude: 39.2026,
                    source: 'fallback',
                  );

              // If the buyer explicitly filtered and no seller has the
              // fish, show the empty state instead of an empty map.
              if (noMatches) {
                return EmptyMapState(
                  onClear: () {
                    ref.read(mapFilterControllerProvider.notifier).reset();
                    _searchCtrl.clear();
                  },
                );
              }
              return SellerMap(
                sellers: sellersWithFish,
                buyerLocation: fallbackLoc,
                activeRoute: routeAsync.valueOrNull,
                selectedSeller: selection,
                onSellerTap: (s) {
                  // Select the seller to show the route card at the bottom.
                  ref
                      .read(selectedSellerControllerProvider.notifier)
                      .select(s);
                },
              );
            }(),
          ),



          // ── Source badge (gps / profile / fallback) ─────────────────────
          Positioned(
            bottom: selection == null ? AppSizes.paddingLG : 220,
            left: AppSizes.paddingMD,
            child: buyerLocAsync.maybeWhen(
              data: (loc) => _LocationSourceBadge(source: loc.source),
              orElse: () => const SizedBox.shrink(),
            ),
          ),

          // ── Floating distance badge — appears on the map whenever a route
          // is active. Smart m/km: shows "350 m" when close, "3.2 km" when
          // farther away. Positioned bottom-right above the route card so it
          // is always visible even while the user pans the map.
          if (selection != null)
            Positioned(
              bottom: 228,
              right: AppSizes.paddingMD,
              child: routeAsync.maybeWhen(
                data: (route) => route != null
                    ? _FloatingDistanceBadge(distanceKm: route.distanceKm)
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),
            ),

          // ── Bottom: route card when a seller is selected ────────────────
          if (selection != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: routeAsync.when(
                loading: () => const _LoadingRouteCard(),
                error: (e, _) => RouteInfoCard(
                  seller: selection,
                  route: null,
                  onClose: () => ref
                      .read(selectedSellerControllerProvider.notifier)
                      .clear(),
                  onSendRequest: () => SendRequestSheet.show(
                    context: context,
                    seller: selection,
                    prefillFishType:
                        selection.matchingItems.first.fishType,
                  ),
                ),
                data: (route) => RouteInfoCard(
                  seller: selection,
                  route: route,
                  onClose: () => ref
                      .read(selectedSellerControllerProvider.notifier)
                      .clear(),
                  onSendRequest: () => SendRequestSheet.show(
                    context: context,
                    seller: selection,
                    prefillFishType:
                        selection.matchingItems.first.fishType,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}



class _LocationSourceBadge extends StatelessWidget {
  final String source;
  const _LocationSourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (source) {
      'gps' => ('GPS · Live', cs.secondary),
      'profile' => ('Imehifadhiwa', cs.primary),
      _ => ('Makadirio', cs.tertiary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSM,
        vertical: AppSizes.paddingXS,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _LoadingRouteCard extends StatelessWidget {
  const _LoadingRouteCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 100,
      margin: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

/// Top-right pill on the buyer map showing the count of currently
/// visible sellers + their locations. Tapping opens a sheet listing
/// every seller with name + coordinates + online dot so the user can
/// visually confirm the data is loading.

/// One row in the visible-sellers sheet.

/// Floating badge on the map surface showing the active route distance.
/// Uses smart m/km: below 1 km shows metres (e.g. "850 m"), otherwise km.
/// Appears with a subtle scale-in animation when a seller is selected.
class _FloatingDistanceBadge extends StatefulWidget {
  final double distanceKm;
  const _FloatingDistanceBadge({required this.distanceKm});

  @override
  State<_FloatingDistanceBadge> createState() => _FloatingDistanceBadgeState();
}

class _FloatingDistanceBadgeState extends State<_FloatingDistanceBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _format(double km) {
    if (km < 1.0) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          // Gradient pill — primary gradient for a premium feel.
          gradient: LinearGradient(
            colors: [
              cs.primary,
              cs.primary.withValues(alpha: 0.82),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: isDark ? 0.55 : 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_walk_rounded,
                color: cs.onPrimary, size: 18),
            const SizedBox(width: 6),
            Text(
              _format(widget.distanceKm),
              style: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bare-metal fallback provider that ignores the buyer session and
/// the fish feed. Reads directly from `activeStreetSellersProviderRemote`
/// (which has no session dependency) and wraps each seller in a
/// `SellerWithFish` with an empty matches list.
///
/// Used as the *last* cascade in `BuyerMapScreen.build` so the map
/// shows every registered seller even when:
///   - the buyer's session is still resolving,
///   - `sellersWithFishProvider` is empty (fish feed not loaded yet),
///   - the geo-query path failed.
///
/// Critically, this never returns an empty list when Firestore has
/// data — the buyer's map is guaranteed to show sellers as long as
/// the demo seeder ran.
final _unfilteredSellersProvider =
    Provider<AsyncValue<List<SellerWithFish>>>((ref) {
  final async = ref.watch(activeStreetSellersProviderRemote);
  return async.whenData(
    (sellers) => sellers
        .map((StreetSellerModel s) =>
            SellerWithFish(seller: s, matchingItems: const <FishItemModel>[]))
        .toList(),
  );
});