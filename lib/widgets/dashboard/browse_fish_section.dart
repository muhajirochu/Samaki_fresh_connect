// "Browse Other Fish" — horizontal scroller of cards. Each card shows:
//   - photo (or placeholder),
//   - fish name,
//   - price/kg,
//   - seller name,
//   - distance from the buyer.
//
// Driven by `nearbyFishListProvider`. When a fish goes out of stock the
// card disappears with no extra plumbing — the provider re-derives from
// the same Firestore stream as the summary header.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/theme_extensions.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/fish_item_model.dart';
import '../../providers/buyer_provider.dart';
import '../../utils/formatters.dart';

class BrowseFishSection extends ConsumerWidget {
  /// Called when the buyer taps a card. Provides the FishItemModel id.
  final void Function(FishItemModel item) onTap;

  const BrowseFishSection({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(nearbyFishListProvider);
    final tokens = BackgroundStyle.of(context);
    final cs = Theme.of(context).colorScheme;

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingLG,
          vertical: AppSizes.paddingMD,
        ),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: tokens.surfaceAlt,
            borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phishing_rounded,
                  color: cs.onSurface.withValues(alpha: 0.45),
                  size: 32,
                ),
                const SizedBox(height: 6),
                Text(
                  'Hakuna samaki karibu nawe kwa sasa',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
        itemCount: entries.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppSizes.paddingMD),
        itemBuilder: (context, i) {
          final entry = entries[i];
          return BrowseFishCard(
            entry: entry,
            onTap: () => onTap(entry.item),
          );
        },
      ),
    );
  }
}

class BrowseFishCard extends StatelessWidget {
  final NearbyFishEntry entry;
  final VoidCallback onTap;

  const BrowseFishCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = BackgroundStyle.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fish = entry.item;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          border: Border.all(color: tokens.border, width: 0.6),
          // Subtle themed shadow — mirrors PremiumCard but kept inline
          // so the card can keep its custom `boxShadow` offset/size.
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.30)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo ────────────────────────────────────────────────────────
            Stack(
              children: [
                SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: fish.imageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: fish.imageUrls.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              _imagePlaceholder(context),
                          errorWidget: (_, __, ___) =>
                              _imagePlaceholder(context),
                        )
                      : _imagePlaceholder(context),
                ),
                if (entry.distanceKm != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _DistanceChip(km: entry.distanceKm!),
                  ),
              ],
            ),
            // ── Info ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingSM,
                AppSizes.paddingSM,
                AppSizes.paddingSM,
                AppSizes.paddingXS,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fish.displayName,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${Formatters.formatCurrency(fish.pricePerKg)}/kg',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.storefront_rounded,
                        size: 12,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          entry.sellerName ?? '—',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.65),
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  Widget _imagePlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = BackgroundStyle.of(context);
    // `_imagePlaceholder` is only called from inside `build`, so the
    // build context passed here is always valid.
    return Container(
      color: tokens.surfaceAlt,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.set_meal_rounded,
            size: 28,
            color: cs.onSurface.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 2),
          Text(
            'No image',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.45),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _DistanceChip extends StatelessWidget {
  final double km;
  const _DistanceChip({required this.km});

  @override
  Widget build(BuildContext context) {
    final formatted = km < 1.0
        ? '${(km * 1000).round()} m'
        : '${km.toStringAsFixed(1)} km';
    // Dark scrim behind white-on-dark foreground — this is intentional:
    // the chip floats over arbitrary photos, so a constant translucent
    // dark wash gives legible foreground on any image.
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(AppSizes.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.place_rounded,
            color: Colors.white,
            size: 11,
          ),
          const SizedBox(width: 2),
          Text(
            formatted,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
