// Buyer's fish-name search results screen.
//
// Reached from the dashboard search bar. The user types a fish name
// (or any text — descriptions are matched too); results stream in
// from the [fishSearchProvider] and group by fish type. Tapping a
// result navigates to the map screen pre-filtered for that seller.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/fish_search_result.dart';
import '../../providers/fish_search_provider.dart';

class BuyerFishSearchScreen extends HookConsumerWidget {
  /// Optional initial query (when the user tapped an autocomplete
  /// suggestion).
  final String? initialQuery;

  const BuyerFishSearchScreen({super.key, this.initialQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = useState<String>(initialQuery ?? '');
    final controller = useTextEditingController(text: initialQuery ?? '');
    final focusNode = useFocusNode();

    useEffect(() {
      // Auto-focus on open so the keyboard pops up immediately.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNode.requestFocus();
      });
      return null;
    }, const []);

    final resultsAsync = ref.watch(fishSearchProvider(query.value));

    return Scaffold(
      backgroundColor: AppColors.gray100,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Search Fish',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Search field pinned to the top.
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingMD,
              AppSizes.paddingSM,
              AppSizes.paddingMD,
              AppSizes.paddingMD,
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: (v) => query.value = v,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'e.g. tuna, mackerel, fillet…',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.gray500),
                suffixIcon: query.value.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.gray500),
                        onPressed: () {
                          controller.clear();
                          query.value = '';
                        },
                      ),
                filled: true,
                fillColor: AppColors.gray100,
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
          ),
          const Divider(height: 1, color: AppColors.gray200),

          // Results.
          Expanded(
            child: _ResultsBody(
              query: query.value,
              resultsAsync: resultsAsync,
              onTapListing: (result, listingWithSeller) {
                context.go(
                  '/buyer/map',
                  extra: {
                    'fishType': result.fishType,
                    'sellerId': listingWithSeller.seller.sellerId,
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsBody extends StatelessWidget {
  final String query;
  final AsyncValue<List<FishSearchResult>> resultsAsync;
  final void Function(FishSearchResult, FishListingWithSeller) onTapListing;

  const _ResultsBody({
    required this.query,
    required this.resultsAsync,
    required this.onTapListing,
  });

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) {
      return const _EmptyHint(
        icon: Icons.search_rounded,
        title: 'Start typing to search',
        subtitle: 'Find sellers with the fish you want, sorted by distance.',
      );
    }

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _EmptyHint(
        icon: Icons.error_outline_rounded,
        title: 'Search failed',
        subtitle: '$e',
        color: AppColors.errorRed,
      ),
      data: (results) {
        if (results.isEmpty) {
          return _EmptyHint(
            icon: Icons.set_meal_rounded,
            title: 'No sellers have "$query" right now',
            subtitle:
                'Hakuna muuzaji wa samaki wa aina hii kwa sasa. Try a different fish name.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          itemCount: results.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSizes.paddingMD),
          itemBuilder: (context, idx) {
            final r = results[idx];
            return _SearchResultCard(
              result: r,
              onTapListing: (pair) => onTapListing(r, pair),
            );
          },
        );
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final FishSearchResult result;
  final void Function(FishListingWithSeller) onTapListing;

  const _SearchResultCard({
    required this.result,
    required this.onTapListing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: fish name + total kg + price range.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingMD,
              AppSizes.paddingMD,
              AppSizes.paddingMD,
              AppSizes.paddingSM,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  ),
                  child: const Icon(Icons.set_meal_rounded,
                      color: AppColors.primaryBlue, size: 22),
                ),
                const SizedBox(width: AppSizes.paddingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${result.listingCount} seller'
                        '${result.listingCount == 1 ? "" : "s"} · '
                        '${result.totalKgAvailable.toStringAsFixed(0)} kg in stock',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (result.anyOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingXS,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusXS),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Live',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.successGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Price range.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMD,
            ),
            child: Row(
              children: [
                Text(
                  'TZS ${result.minPricePerKg.toStringAsFixed(0)} – '
                  '${result.maxPricePerKg.toStringAsFixed(0)} / kg',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.gray700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.paddingSM),
          const Divider(
            color: AppColors.gray200,
            height: 1,
            indent: AppSizes.paddingMD,
            endIndent: AppSizes.paddingMD,
          ),

          // Sellers list (capped at 3 to keep cards scannable).
          for (final pair in result.listings.take(3))
            _SellerRow(pair: pair, onTap: () => onTapListing(pair)),
          if (result.listings.length > 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingMD,
                AppSizes.paddingXS,
                AppSizes.paddingMD,
                AppSizes.paddingMD,
              ),
              child: Text(
                '+ ${result.listings.length - 3} more sellers',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SellerRow extends StatelessWidget {
  final FishListingWithSeller pair;
  final VoidCallback onTap;

  const _SellerRow({required this.pair, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.paddingMD,
          AppSizes.paddingSM,
          AppSizes.paddingMD,
          AppSizes.paddingSM,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.gray100,
              backgroundImage: pair.seller.profilePictureUrl != null
                  ? NetworkImage(pair.seller.profilePictureUrl!)
                  : null,
              child: pair.seller.profilePictureUrl == null
                  ? const Icon(Icons.person_rounded,
                      size: 18, color: AppColors.gray500)
                  : null,
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
                          pair.seller.fullName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (pair.seller.isOnline) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pair.listing.quantityKg.toStringAsFixed(1)} kg · '
                    'TZS ${pair.listing.pricePerKg.toStringAsFixed(0)} / kg',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${pair.distanceKm.toStringAsFixed(1)} km',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.gray500),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;

  const _EmptyHint({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? AppColors.gray500;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: c),
            ),
            const SizedBox(height: AppSizes.paddingMD),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.gray600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
