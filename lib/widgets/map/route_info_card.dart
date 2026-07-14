// Bottom card showing the active route's distance + ETA. Slides up when
// a seller is selected; dismissed via the close button.

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../features/map/utils/gps_helper.dart';
import '../../models/map_filter_model.dart';
import '../../models/street_seller_model.dart';
import '../../services/routing_service.dart';

class RouteInfoCard extends StatelessWidget {
  final SellerWithFish seller;
  final RouteResult? route;
  final VoidCallback onClose;
  final VoidCallback? onSendRequest;

  const RouteInfoCard({
    super.key,
    required this.seller,
    required this.route,
    required this.onClose,
    this.onSendRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSizes.radiusXL),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingLG,
            AppSizes.paddingMD,
            AppSizes.paddingLG,
            AppSizes.paddingMD,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle.
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingMD),
              // Seller header row.
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                    ),
                    child: const Icon(Icons.store_rounded,
                        color: AppColors.accentOrange, size: 22),
                  ),
                  const SizedBox(width: AppSizes.paddingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seller.seller.fullName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          seller.seller.marketName ??
                              seller.seller.streetName ??
                              'Street seller',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.gray600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.gray500,
                    tooltip: 'Funga',
                  ),
                ],
              ),
              // Live-presence pill. Shown whenever the seller is online
              // — green + "Live location" when fresh, grey + relative
              // time when stale.
              const SizedBox(height: AppSizes.paddingSM),
              _LiveStatusPill(seller: seller.seller),
              const SizedBox(height: AppSizes.paddingMD),
              // Metrics row: distance + ETA.
              Row(
                children: [
                  Expanded(child: _MetricTile(
                    icon: Icons.straighten_rounded,
                    label: 'Umbali',
                    value: route == null
                        ? '...'
                        : '${route!.distanceKm.toStringAsFixed(1)} km',
                    color: AppColors.primaryBlue,
                  )),
                  const SizedBox(width: AppSizes.paddingSM),
                  Expanded(child: _MetricTile(
                    icon: Icons.access_time_rounded,
                    label: 'Muda unaotarajiwa',
                    value: route == null
                        ? '...'
                        : _formatEta(route!.durationMinutes),
                    color: AppColors.secondaryTeal,
                  )),
                ],
              ),
              if (route?.source == RouteSource.fallback) ...[
                const SizedBox(height: AppSizes.paddingSM),
                _FallbackBadge(),
              ],
              const SizedBox(height: AppSizes.paddingMD),
              // Fish summary.
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingSM),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.set_meal_rounded,
                        color: AppColors.primaryBlue, size: 20),
                    const SizedBox(width: AppSizes.paddingSM),
                    Expanded(
                      child: Text(
                        _fishSummary(seller),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.gray700,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (onSendRequest != null) ...[
                const SizedBox(height: AppSizes.paddingMD),
                SizedBox(
                  width: double.infinity,
                  height: AppSizes.buttonHeight,
                  child: FilledButton.icon(
                    onPressed: onSendRequest,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Tuma Ombi'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fishSummary(SellerWithFish s) {
    final total = s.matchingItems.fold<double>(
      0,
      (acc, item) => acc + item.quantityKg,
    );
    if (s.matchingItems.length == 1) {
      return '${s.matchingItems.first.displayName} · '
          '${s.matchingItems.first.quantityKg.toStringAsFixed(1)} kg';
    }
    return '${s.matchingItems.length} aina · ${total.toStringAsFixed(1)} kg jumla';
  }

  static String _formatEta(double minutes) {
    if (minutes < 1) return '< 1 dk';
    if (minutes < 60) return '${minutes.round()} dk';
    final hours = minutes / 60;
    return '${hours.toStringAsFixed(1)} saa';
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSM,
        vertical: AppSizes.paddingMD,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSizes.paddingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.gray600,
                          fontWeight: FontWeight.w500,
                        )),
                Text(value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSM,
        vertical: AppSizes.paddingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningAmber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 14, color: AppColors.warningAmber),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Njia ya moja kwa moja (mtandao haupatikani)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warningAmber,
                    fontWeight: FontWeight.w500,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Live-presence pill. Green + "Online · live location" when the
/// seller's last GPS fix is fresh; grey + relative "Last seen N ago"
/// otherwise.
class _LiveStatusPill extends StatelessWidget {
  final StreetSellerModel seller;

  const _LiveStatusPill({required this.seller});

  @override
  Widget build(BuildContext context) {
    final lastFix = seller.lastLocationUpdateAt;
    final isFresh = seller.isOnline &&
        lastFix != null &&
        DateTime.now().difference(lastFix) <
            const Duration(minutes: 5);

    final theme = Theme.of(context);
    if (isFresh) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingSM,
          vertical: AppSizes.paddingXS,
        ),
        decoration: BoxDecoration(
          color: AppColors.successGreen.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppSizes.radiusSM),
          border: Border.all(
            color: AppColors.successGreen.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.successGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSizes.paddingXS),
            Text(
              'Online · live location',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.successGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    // Offline / stale fallback. Hide entirely if we have no signal at
    // all — the seller is presumably just signed up and hasn't moved
    // yet.
    if (lastFix == null && !seller.isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSM,
        vertical: AppSizes.paddingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(AppSizes.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.gray500,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSizes.paddingXS),
          Text(
            lastFix == null
                ? 'Offline'
                : 'Last seen ${GpsHelper.formatRelativeTime(lastFix)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.gray600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
