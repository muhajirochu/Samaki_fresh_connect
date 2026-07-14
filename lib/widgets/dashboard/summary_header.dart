// Summary header — three reactive tiles shown at the top of the buyer
// dashboard: Fish Available Nearby, Active Requests, Nearest Seller.
//
// The data is sourced from Riverpod providers (Phase 1 + 3 selectors),
// so the tiles update in real time when:
//   - a fish goes out of stock (count drops),
//   - the buyer posts/cancels a request (active count moves),
//   - the buyer's location updates (nearest seller changes).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../providers/buyer_provider.dart';

class DashboardSummaryHeader extends ConsumerWidget {
  const DashboardSummaryHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the raw streams directly so each tile is independent — if
    // one stream errors (e.g. permissions on a private subcollection)
    // the other two tiles still render real values rather than 0.
    // Previously this provider read through `buyerDashboardProvider`,
    // which blocks on `anyLoading`; we now show what's actually
    // available and update as the rest of the streams resolve.
    final fishAsync = ref.watch(buyerFishFeedProvider);
    final requestsAsync = ref.watch(buyerActiveRequestsProvider);
    final sellersAsync = ref.watch(activeStreetSellersProvider);

    final fishCount = fishAsync.valueOrNull?.length ?? 0;
    final activeRequests = requestsAsync.valueOrNull
            ?.where((r) => r.countsAsActive)
            .length ??
        0;

    // Nearest seller derived directly from the live sellers list +
    // the buyer's current session location. If the buyer hasn't
    // signed in yet (no `currentBuyerSessionProvider`), or their
    // profile doesn't carry a `location` yet, fall back to Stone
    // Town centre — that's where the demo sellers live, so the
    // "nearest" tile always shows a useful distance.
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
            label: 'Fish Available\nNearby',
            value: '$fishCount',
            accent: AppColors.primaryBlue,
            onTap: () {
              context.push('/buyer/map');
            },
          ),
        ),
        const SizedBox(width: AppSizes.paddingSM),
        Expanded(
          child: _SummaryTile(
            icon: Icons.assignment_turned_in_rounded,
            label: 'Active\nRequests',
            value: '$activeRequests',
            accent: AppColors.secondaryTeal,
            onTap: () {
              context.push('/buyer/requests');
            },
          ),
        ),
        const SizedBox(width: AppSizes.paddingSM),
        Expanded(
          child: _SummaryTile(
            icon: Icons.storefront_rounded,
            label: 'Nearest\nSeller',
            value: nearestSeller == null
                ? '—'
                : '${nearestSeller.distanceKmFrom(buyerLat, buyerLng).toStringAsFixed(1)} km',
            subtitle: nearestSeller?.fullName.split(' ').first,
            accent: AppColors.accentOrange,
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
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingSM,
            vertical: AppSizes.paddingMD,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLG),
            border: Border.all(color: AppColors.gray200),
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.gray600,
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
        ),
      ),
    );
  }
}
