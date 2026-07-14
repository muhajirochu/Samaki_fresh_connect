// "Popular Near You" — recommendations derived from the local fish feed.
// Each tile shows: fish name, listing count, lowest price/kg, thumbnail.
//
// Driven by `popularNearbyFishProvider`, which ranks fish types by
// listing density within 10km of the buyer. Re-derives whenever the
// underlying stream emits.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/enums/fish_type.dart';
import '../../providers/buyer_provider.dart';
import '../../utils/formatters.dart';

class PopularFishSection extends ConsumerWidget {
  /// Called when the buyer taps a popular fish tile.
  final void Function(String fishName, String? fishTypeValue) onTap;

  const PopularFishSection({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popular = ref.watch(popularNearbyFishProvider);

    if (popular.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.paddingLG,
          vertical: AppSizes.paddingMD,
        ),
        child: Text(
          'Mapendekezo yatapatikana hapa baada ya wauzaji kuchapisha samaki wengi.',
          style: TextStyle(color: AppColors.gray500),
        ),
      );
    }

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
        itemCount: popular.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppSizes.paddingSM),
        itemBuilder: (context, i) {
          final p = popular[i];
          return _PopularTile(
            fishName: p.fishName,
            listingCount: p.listingCount,
            pricePerKg: p.lowestPricePerKg,
            imageUrl: p.imageUrl,
            onTap: () => onTap(p.fishName, _fishTypeValueFor(p.fishName)),
          );
        },
      ),
    );
  }

  /// Map display-name back to FishType.value for query-param routing.
  /// Returns null if the name isn't recognized (UI still navigates with q=).
  String? _fishTypeValueFor(String name) {
    final lower = name.toLowerCase();
    for (final t in [
      FishType.tilapia,
      FishType.tuna,
      FishType.mackerel,
      FishType.sardine,
      FishType.grouper,
      FishType.snapper,
      FishType.other,
    ]) {
      if (t.displayName.toLowerCase() == lower) return t.value;
    }
    return null;
  }
}

class _PopularTile extends StatelessWidget {
  final String fishName;
  final int listingCount;
  final double? pricePerKg;
  final String? imageUrl;
  final VoidCallback onTap;

  const _PopularTile({
    required this.fishName,
    required this.listingCount,
    required this.onTap,
    this.pricePerKg,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingSM),
          child: Row(
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusMD),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              color: AppColors.gray100),
                          errorWidget: (_, __, ___) => _imgFallback(),
                        )
                      : _imgFallback(),
                ),
              ),
              const SizedBox(width: AppSizes.paddingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      fishName,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppColors.accentOrange.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSM),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department_rounded,
                                  color: AppColors.accentOrange, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                '$listingCount listings',
                                style: const TextStyle(
                                  color: AppColors.accentOrange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (pricePerKg != null)
                      Text(
                        'Kuanzia ${Formatters.formatCurrency(pricePerKg!)}/kg',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _imgFallback() {
    return Container(
      color: AppColors.gray100,
      child: const Icon(Icons.set_meal_rounded,
          color: AppColors.gray400, size: 28),
    );
  }
}