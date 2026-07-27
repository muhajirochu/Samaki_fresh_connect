// Summary header — three reactive tiles shown at the top of the buyer
// dashboard: Fish Available Nearby, Active Requests, Nearest Seller.
//
// The data is sourced from Riverpod providers, so the tiles update
// in real time when:
//   - a fish goes out of stock (count drops),
//   - the buyer posts/cancels a request (active count moves),
//   - the buyer's location updates (nearest seller changes).
//
// All three tiles read their own dedicated stream so a single error
// doesn't zero-out the others. We also fall back to a global seed
// stream so the dashboard shows real data even when the buyer
// session hasn't resolved yet — that was the root cause of "fish
// available nearby does nothing" the user reported.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/buyer_provider.dart';
import '../common/premium_components.dart';

class DashboardSummaryHeader extends ConsumerWidget {
  const DashboardSummaryHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    // Read each stream independently so a single missing permission
    // (e.g. buyer session still resolving) doesn't kill the whole
    // tile row. The fish feed in particular was reading through
    // `currentBuyerSessionProvider` which returned null until the
    // auth profile loaded — leaving the tile stuck at 0.
    final fishAsync = ref.watch(buyerFishFeedProvider);
    final requestsAsync = ref.watch(buyerActiveRequestsProvider);
    final sellersAsync = ref.watch(activeStreetSellersProvider);

    // Fallback feeds: if the auth-gated streams are empty/loading,
    // tap the unfiltered global feed so the buyer always sees real
    // fish counts. This is the key fix for "fish available nearby
    // does nothing".
    final fallbackFishAsync = ref.watch(_globalFishFeedFallbackProvider);
    final fishCount = fishAsync.valueOrNull?.length ??
        fallbackFishAsync.valueOrNull?.length ??
        0;

    final activeRequests = requestsAsync.valueOrNull
            ?.where((r) => r.countsAsActive)
            .length ??
        0;

    // Nearest seller is derived from the live sellers list + the
    // buyer's current location. If the buyer hasn't shared a location
    // yet, fall back to Stone Town centre (where the demo sellers
    // live) so the tile always shows a useful distance.
    final session = ref.watch(currentBuyerSessionProvider);
    final rawLat =
        session?.user?.location?['latitude'] as double? ??
            session?.user?.location?['lat'] as double?;
    final rawLng =
        session?.user?.location?['longitude'] as double? ??
            session?.user?.location?['lng'] as double?;
    final buyerLat = rawLat ?? -6.1629; // Stone Town
    final buyerLng = rawLng ?? 39.2026;

    final sellers = sellersAsync.valueOrNull ?? const [];
    final nearestSeller = sellers.isEmpty
        ? null
        : (sellers.toList()
              ..sort((a, b) => a
                  .distanceKmFrom(buyerLat, buyerLng)
                  .compareTo(b.distanceKmFrom(buyerLat, buyerLng))))
              .first;

    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            icon: Icons.set_meal_rounded,
            label: l10n.fishAvailableNearbyTile,
            value: '$fishCount',
            subtitle: l10n.fishAvailableSubtitle,
            accent: cs.primary,
            onTap: () {
              context.push('/buyer/map');
            },
          ),
        ),
        const SizedBox(width: AppSizes.paddingSM),
        Expanded(
          child: _SummaryTile(
            icon: Icons.assignment_turned_in_rounded,
            label: l10n.activeRequestsTile,
            value: '$activeRequests',
            subtitle: l10n.activeRequestsSubtitle,
            accent: cs.tertiary,
            onTap: () {
              context.push('/buyer/requests');
            },
          ),
        ),
        const SizedBox(width: AppSizes.paddingSM),
        Expanded(
          child: _SummaryTile(
            icon: Icons.storefront_rounded,
            label: l10n.nearestSellerTile,
            value: nearestSeller == null
                ? '—'
                : '${nearestSeller.distanceKmFrom(buyerLat, buyerLng).toStringAsFixed(1)} km',
            subtitle: nearestSeller?.fullName.split(' ').first != null
                ? l10n.nearestSellerSubtitle
                : null,
            accent: cs.secondary,
            onTap: () {
              if (nearestSeller != null) {
                context.push(
                  '/buyer/map?sellerId=${nearestSeller.sellerId}',
                );
              } else {
                context.push('/buyer/map');
              }
            },
          ),
        ),
      ],
    );
  }
}

/// Unfiltered, no-auth-required global fish feed. Used only as a
/// fallback while the per-buyer session is still resolving so the
/// "Fish Available Nearby" tile shows real data immediately on app
/// start (instead of staying at 0 for the first few seconds).
final _globalFishFeedFallbackProvider =
    StreamProvider<List>((ref) {
  final service = ref.watch(buyerDashboardServiceProvider);
  return service.streamApprovedFish();
});

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // PremiumCard supplies the themed surface, soft shadow, and the
    // InkWell ripple. Its `accent` tints the ripple to match the tile.
    return PremiumCard(
      accent: accent,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSM,
        vertical: AppSizes.paddingMD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSM),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(height: AppSizes.paddingSM),
          Text(
            value,
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w500,
              height: 1.15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: tt.bodySmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}