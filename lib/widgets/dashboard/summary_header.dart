// Summary header — three reactive tiles shown at the top of the buyer
// dashboard: Fish Available Nearby, Active Requests, Nearest Seller.
//
// Fix log (2026-08-01):
//   • Fish count   — now reads the global unfiltered Firestore feed
//                    directly (no session required). Populated within
//                    the first Firestore tick after app launch.
//   • Active reqs  — shows a loading shimmer while the buyer session
//                    resolves; jumps to the real count once the stream
//                    first emits.
//   • Nearest km   — now uses `currentBuyerLocationProvider` (GPS →
//                    profile → Stone Town) so the distance is always
//                    meaningful, not stuck at "—" when the session
//                    location map-field is null.
//   • Smart m/km   — distances < 1 km display as "850 m" not "0.9 km".

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/buyer_provider.dart';
import '../../services/location_service.dart';
import '../common/premium_components.dart';

class DashboardSummaryHeader extends ConsumerWidget {
  const DashboardSummaryHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    // ── 1. Fish Available ──────────────────────────────────────────────
    // Always read the global unfiltered feed — it doesn't require a
    // buyer session so it populates immediately after login. The
    // session-scoped `buyerFishFeedProvider` may also have data (when
    // the buyer has GPS/profile coords), so we take whichever is larger.
    final globalFishAsync = ref.watch(_globalFishFeedFallbackProvider);
    final sessionFishAsync = ref.watch(buyerFishFeedProvider);
    final globalCount  = globalFishAsync.valueOrNull?.length ?? 0;
    final sessionCount = sessionFishAsync.valueOrNull?.length ?? 0;
    final fishCount    = globalCount > sessionCount ? globalCount : sessionCount;
    final fishLoading  = globalFishAsync.isLoading && sessionFishAsync.isLoading;

    // ── 2. Active Requests ─────────────────────────────────────────────
    // `buyerActiveRequestsProvider` emits an empty stream while session
    // is null — show a shimmer until the first real value arrives.
    final requestsAsync  = ref.watch(buyerActiveRequestsProvider);
    final activeRequests = requestsAsync.valueOrNull
            ?.where((r) => r.countsAsActive)
            .length ??
        0;
    final requestsLoading = requestsAsync.isLoading;

    // ── 3. Nearest Seller (km) ─────────────────────────────────────────
    // Use `currentBuyerLocationProvider` which resolves: GPS → saved
    // profile coords → Stone Town fallback. This is the same source the
    // map screen uses, so the distance is always meaningful.
    final locationAsync  = ref.watch(currentBuyerLocationProvider);
    final sellersAsync   = ref.watch(activeStreetSellersProvider);
    final sellers        = sellersAsync.valueOrNull ?? const [];

    // Resolve buyer lat/lng from location provider (GPS-backed).
    final buyerLoc = locationAsync.valueOrNull;
    final buyerLat = buyerLoc?.latitude  ?? -6.1629; // Stone Town fallback
    final buyerLng = buyerLoc?.longitude ?? 39.2026;

    final nearestSeller = sellers.isEmpty
        ? null
        : (sellers.toList()
              ..sort((a, b) => a
                  .distanceKmFrom(buyerLat, buyerLng)
                  .compareTo(b.distanceKmFrom(buyerLat, buyerLng))))
              .first;

    final nearestKm = nearestSeller?.distanceKmFrom(buyerLat, buyerLng);
    // Smart m/km for the nearest-seller tile — same logic as the map badge.
    final nearestLabel = nearestKm == null
        ? '—'
        : nearestKm < 1.0
            ? '${(nearestKm * 1000).round()} m'
            : '${nearestKm.toStringAsFixed(1)} km';

    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            icon: Icons.set_meal_rounded,
            label: l10n.fishAvailableNearbyTile,
            value: fishLoading ? '…' : '$fishCount',
            subtitle: l10n.fishAvailableSubtitle,
            accent: cs.primary,
            isLoading: fishLoading,
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
            value: requestsLoading ? '…' : '$activeRequests',
            subtitle: l10n.activeRequestsSubtitle,
            accent: cs.tertiary,
            isLoading: requestsLoading,
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
            value: (sellersAsync.isLoading || locationAsync.isLoading)
                ? '…'
                : nearestLabel,
            subtitle: nearestSeller?.fullName.split(' ').first != null
                ? l10n.nearestSellerSubtitle
                : null,
            accent: cs.secondary,
            isLoading: sellersAsync.isLoading || locationAsync.isLoading,
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
  final bool isLoading;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.onTap,
    this.subtitle,
    this.isLoading = false,
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
          // Thin progress bar replaces the "0" state while loading.
          if (isLoading) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: accent.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ],
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
