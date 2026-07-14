import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/fish_listing_model.dart';
import '../../models/enums/listing_status.dart';
import '../../utils/formatters.dart';

class FishListingCard extends StatelessWidget {
  final FishListingModel listing;
  final VoidCallback? onTap;

  const FishListingCard({super.key, required this.listing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = ListingStatusExtension.fromString(listing.status);
    final isExpired = listing.expiresAt.isBefore(DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ─────────────────────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusMD),
                topRight: Radius.circular(AppSizes.radiusMD),
              ),
              child: Stack(
                children: [
                  listing.imageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: listing.imageUrls.first,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _imagePlaceholder(),
                          errorWidget: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                  // Status badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _StatusBadge(
                      status: isExpired ? ListingStatus.expired : status,
                    ),
                  ),
                ],
              ),
            ),
            // ── Info ──────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.set_meal,
                        size: AppSizes.iconSM,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing.fishType,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.scale,
                        label: Formatters.formatQuantity(listing.quantityKg),
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.attach_money,
                        label:
                            '${Formatters.formatCurrency(listing.pricePerKg)}/kg',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Formatters.formatCurrency(listing.totalPrice),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        Formatters.formatRelativeTime(listing.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.gray500,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 130,
      width: double.infinity,
      color: AppColors.gray100,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.set_meal, size: 40, color: AppColors.gray400),
          SizedBox(height: 4),
          Text(
            'No Image',
            style: TextStyle(color: AppColors.gray400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ListingStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ListingStatus.active:
        color = AppColors.successGreen;
        break;
      case ListingStatus.sold:
        color = AppColors.infoBlue;
        break;
      case ListingStatus.expired:
        color = AppColors.errorRed;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSizes.radiusSM),
      ),
      child: Text(
        status.displayName,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.gray500),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.gray600),
        ),
      ],
    );
  }
}
