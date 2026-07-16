// Buyer's fish-name search results screen.
//
// Reached from the dashboard search bar. The user types a fish name
// (or any text — descriptions are matched too); results stream in
// from the [fishSearchProvider] and group by fish type. Tapping a
// result navigates to the map screen pre-filtered for that seller.
//
// Implementation note: the search query is stored in
// [searchQueryProvider] (a Riverpod `StateProvider<String>`) rather
// than in a local `useState`. The single, app-wide
// [fishSearchProvider] listens to that one provider, so changing the
// query just re-runs the filter against already-loaded buffers —
// no new Firestore subscription per query.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/fish_search_result.dart';
import '../../providers/fish_search_provider.dart';

class BuyerFishSearchScreen extends ConsumerStatefulWidget {
  /// Optional initial query (when the user tapped an autocomplete
  /// suggestion).
  final String? initialQuery;

  const BuyerFishSearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<BuyerFishSearchScreen> createState() =>
      _BuyerFishSearchScreenState();
}

class _BuyerFishSearchScreenState extends ConsumerState<BuyerFishSearchScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery ?? '';
    _controller = TextEditingController(text: initial);
    _focusNode = FocusNode();
    // Seed the shared query provider so the search stream picks up
    // the initial value before the first frame renders.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(searchQueryProvider.notifier).state = initial;
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // Update the shared query so the singleton search provider
    // re-emits against its already-loaded buffers.
    ref.read(searchQueryProvider.notifier).state = value;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(fishSearchProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context).searchFish,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Search field pinned to the top.
          Container(
            color: cs.surface,
            padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingMD,
              AppSizes.paddingSM,
              AppSizes.paddingMD,
              AppSizes.paddingMD,
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).searchHint,
                prefixIcon: Icon(Icons.search_rounded,
                    color: cs.onSurface.withValues(alpha: 0.55)),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: cs.onSurface.withValues(alpha: 0.55)),
                        onPressed: () {
                          _controller.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
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
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.15)),

          // Results.
          Expanded(
            child: _ResultsBody(
              query: query,
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
    final l10n = AppLocalizations.of(context);
    if (query.trim().isEmpty) {
      return _EmptyHint(
        icon: Icons.search_rounded,
        title: l10n.startTypingToSearch,
        subtitle:
            'Find sellers with the fish you want, sorted by distance.',
      );
    }

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _EmptyHint(
        icon: Icons.error_outline_rounded,
        title: l10n.searchFailed,
        subtitle: '$e',
        color: AppColors.errorRed,
      ),
      data: (results) {
        if (results.isEmpty) {
          return _EmptyHint(
            icon: Icons.set_meal_rounded,
            title: l10n.noSellersHave(query),
            subtitle: l10n.noSellersHaveSubtitle,
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
    final cs = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.20),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
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
                    color: cs.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  ),
                  child: Icon(Icons.set_meal_rounded,
                      color: cs.primary, size: 22),
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
                          color: cs.onSurface.withValues(alpha: 0.65),
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
                    color: cs.onSurface.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.paddingSM),
          Divider(
            color: cs.outline.withValues(alpha: 0.15),
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
                  color: cs.primary,
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
    final cs = theme.colorScheme;
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
              backgroundColor: cs.surfaceContainerHighest,
              backgroundImage: pair.seller.profilePictureUrl != null
                  ? NetworkImage(pair.seller.profilePictureUrl!)
                  : null,
              child: pair.seller.profilePictureUrl == null
                  ? Icon(Icons.person_rounded,
                      size: 18, color: cs.onSurface.withValues(alpha: 0.55))
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
                      color: cs.onSurface.withValues(alpha: 0.65),
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
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: cs.onSurface.withValues(alpha: 0.55)),
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
    final cs = theme.colorScheme;
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
                color: cs.onSurface.withValues(alpha: 0.65),
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
