import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../config/theme_extensions.dart';
import '../../constants/app_sizes.dart';
import '../../models/fish_listing_model.dart';
import '../../models/enums/listing_status.dart';
import '../../utils/formatters.dart';
import '../common/premium_components.dart';

class FishListingCard extends StatelessWidget {
  final FishListingModel listing;
  final VoidCallback? onTap;

  const FishListingCard({super.key, required this.listing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = ListingStatusExtension.fromString(listing.status);
    final isExpired = listing.expiresAt != null &&
        listing.expiresAt!.isBefore(DateTime.now());
    final tokens = BackgroundStyle.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium card surface — same border / shadow language as
    // `PremiumCard`, but inlined so the image still clips to its top
    // rounded corners.

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSizes.radiusMD),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        child: Ink(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusMD),
            border: Border.all(color: tokens.border, width: 0.6),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? cs.shadow.withValues(alpha: 0.50)
                    : cs.shadow.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image ────────────────────────────────────────────────────
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
                            placeholder: (_, __) => _imagePlaceholder(context),
                            errorWidget: (_, __, ___) =>
                                _imagePlaceholder(context),
                          )
                        : _imagePlaceholder(context),
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
              // ── Info ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.set_meal,
                          size: AppSizes.iconSM,
                          color: cs.primary,
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
                        StatChip(
                          icon: Icons.scale,
                          label: Formatters.formatQuantity(listing.quantityKg),
                          color: cs.primary,
                        ),
                        const SizedBox(width: 8),
                        StatChip(
                          icon: Icons.attach_money,
                          label:
                              '${Formatters.formatCurrency(listing.pricePerKg)}/kg',
                          color: cs.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Both children are Flexible: a long price plus a
                        // spelled-out Swahili relative time ("Dakika 5
                        // zilizopita") exceeds the card width on a 360dp
                        // phone and painted an overflow stripe.
                        Flexible(
                          child: Text(
                            Formatters.formatCurrency(listing.totalPrice),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingXS),
                        Flexible(
                          child: Text(
                            Formatters.formatRelativeTime(listing.createdAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                ),
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
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    final tokens = BackgroundStyle.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 130,
      width: double.infinity,
      color: tokens.surfaceAlt,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.set_meal,
            size: 40,
            color: cs.onSurface.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 4),
          Text(
            'No Image',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
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
    final cs = Theme.of(context).colorScheme;
    Color color;
    switch (status) {
      case ListingStatus.active:
        // Live listings use the secondary (Elegant Green) so it
        // matches the "available" semantic across the app.
        color = cs.secondary;
        break;
      case ListingStatus.sold:
        color = cs.primary;
        break;
      case ListingStatus.expired:
        color = cs.error;
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
        style: TextStyle(
          color: cs.onPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
