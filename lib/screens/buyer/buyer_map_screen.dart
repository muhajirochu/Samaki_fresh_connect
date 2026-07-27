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
import '../../widgets/map/seller_profile_sheet.dart';
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
    final filter = ref.watch(mapFilterControllerProvider);
    final noMatches = ref.watch(noMatchingSellersProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ramani ya Wauzaji'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Onyesha aina zote',
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
                  // Select the seller (which shows the route card) and
                  // also open the full profile sheet so the buyer
                  // can see the seller's complete info + photo.
                  ref
                      .read(selectedSellerControllerProvider.notifier)
                      .select(s);
                  SellerProfileSheet.show(
                    context,
                    seller: s.seller,
                    buyerLatitude: fallbackLoc.latitude,
                    buyerLongitude: fallbackLoc.longitude,
                    onSendRequest: () {
                      Navigator.of(context).pop();
                      SendRequestSheet.show(
                        context: context,
                        seller: s,
                      );
                    },
                  );
                },
              );
            }(),
          ),

          // ── Top: search bar + fish-type chips ────────────────────────────
          Positioned(
            top: AppSizes.paddingSM,
            left: AppSizes.paddingMD,
            right: AppSizes.paddingMD,
            child: _SearchAndChips(
              searchCtrl: _searchCtrl,
              onSearchChanged: (q) =>
                  ref.read(mapFilterControllerProvider.notifier)
                      .setSearchQuery(q),
              onFishTypeSelected: (type) {
                final current = ref.read(mapFilterControllerProvider).fishType;
                // Toggle off if the same chip is tapped.
                if (current == type) {
                  ref.read(mapFilterControllerProvider.notifier)
                      .setFishType(null);
                } else {
                  ref.read(mapFilterControllerProvider.notifier)
                      .setFishType(type);
                }
                ref.read(selectedSellerControllerProvider.notifier).clear();
              },
              activeFishType: filter.fishType,
            ),
          ),

          // ── Top-right: visible-sellers confirm pill ────────────────────
          // The user needs to *see* that sellers are loaded. This pill
          // shows the count + a tap-to-list of every visible seller's
          // name + coordinates so they can verify visually.
          if (!buyerLocAsync.isLoading &&
              !buyerLocAsync.hasError &&
              sellersWithFish.isNotEmpty)
            Positioned(
              top: AppSizes.paddingSM + 60, // sits below the search bar
              right: AppSizes.paddingMD,
              child: _VisibleSellersPill(
                count: sellersWithFish.length,
                sellers: sellersWithFish,
              ),
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

class _SearchAndChips extends StatelessWidget {
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<FishType?> onFishTypeSelected;
  final FishType? activeFishType;

  const _SearchAndChips({
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onFishTypeSelected,
    required this.activeFishType,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      elevation: 4,
      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingSM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchCtrl,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tafuta samaki...',
                prefixIcon: Icon(Icons.search_rounded,
                    color: cs.onSurface.withValues(alpha: 0.55)),
                suffixIcon: searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: cs.onSurface.withValues(alpha: 0.55)),
                        onPressed: () {
                          searchCtrl.clear();
                          onSearchChanged('');
                        },
                      ),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: AppSizes.paddingSM,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingXS),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FishChip(
                    label: 'Zote',
                    selected: activeFishType == null,
                    onTap: () => onFishTypeSelected(null),
                  ),
                  for (final t in FishType.values)
                    _FishChip(
                      label: t.displayName,
                      selected: activeFishType == t,
                      onTap: () => onFishTypeSelected(t),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FishChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FishChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.paddingXS),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: cs.surfaceContainerHighest,
        selectedColor: cs.primary,
        labelStyle: TextStyle(
          color: selected ? cs.onPrimary : cs.onSurface,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(
          color: selected
              ? cs.primary
              : cs.outline.withValues(alpha: 0.25),
        ),
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
class _VisibleSellersPill extends StatelessWidget {
  final int count;
  final List<SellerWithFish> sellers;

  const _VisibleSellersPill({required this.count, required this.sellers});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      // Visible-sellers pill uses the secondary (Elegant Green) so
      // it matches the "live / available" semantic across the app.
      color: cs.secondary,
      elevation: 4,
      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      child: InkWell(
        onTap: () => _showSellersSheet(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMD,
            vertical: AppSizes.paddingXS,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.store_rounded,
                size: 14,
                color: cs.onSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '$count wauzaji wanaonekana',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: cs.onSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSellersSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingLG,
            vertical: AppSizes.paddingMD,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingMD),
              Text(
                'Wauzaji $count wanaonekana',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSizes.paddingXS),
              Text(
                'Bonyeza marker kwenye ramani kuona samaki, njia, na '
                'muda unaotarajiwa.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.65),
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: AppSizes.paddingMD),
              for (final s in sellers)
                _VisibleSellerRow(seller: s),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row in the visible-sellers sheet.
class _VisibleSellerRow extends StatelessWidget {
  final SellerWithFish seller;
  const _VisibleSellerRow({required this.seller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: seller.seller.isOnline
                  ? cs.secondary.withValues(alpha: 0.15)
                  : cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSizes.radiusMD),
            ),
            child: Icon(
              Icons.store_rounded,
              size: 18,
              color: seller.seller.isOnline
                  ? cs.secondary
                  : cs.primary,
            ),
          ),
          const SizedBox(width: AppSizes.paddingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        seller.seller.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (seller.seller.isOnline) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: cs.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${seller.seller.latitude.toStringAsFixed(4)}, '
                  '${seller.seller.longitude.toStringAsFixed(4)}'
                  '${seller.seller.marketName != null ? ' · ${seller.seller.marketName}' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.65),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
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