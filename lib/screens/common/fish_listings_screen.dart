import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/route_paths.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/cards/fish_listing_card.dart';
import '../../widgets/common/common_widgets.dart';

class FishListingsScreen extends ConsumerWidget {
  const FishListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(activeListingsProvider);
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.marketplace),
        elevation: 0,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // ref.invalidate re-subscribes the StreamProvider so the
          // screen re-renders with a fresh snapshot. Await one frame
          // so the spinner has time to appear.
          ref.invalidate(activeListingsProvider);
          await Future<void>.delayed(const Duration(milliseconds: 400));
        },
        child: listingsAsync.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: 320,
                child: LoadingIndicator(message: l10n.loadingFreshCatch),
              ),
            ],
          ),
          error: (error, stack) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.paddingLG),
            children: [
              SizedBox(
                height: 320,
                child: EmptyStateWidget(
                  icon: Icons.error_outline,
                  title: l10n.failedToLoadListings,
                  subtitle: error.toString(),
                  onRetry: () => ref.invalidate(activeListingsProvider),
                ),
              ),
            ],
          ),
          data: (listings) {
            if (listings.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSizes.paddingLG),
                children: [
                  SizedBox(
                    height: 320,
                    child: EmptyStateWidget(
                      icon: Icons.set_meal_outlined,
                      title: l10n.noFishAvailable,
                      subtitle: l10n.checkBackLater,
                      onRetry: () => ref.invalidate(activeListingsProvider),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.paddingLG),
              itemCount: listings.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSizes.paddingMD),
              itemBuilder: (context, index) {
                final listing = listings[index];
                return FishListingCard(
                  listing: listing,
                  onTap: () => context.pushNamed(
                    AppRouteNames.listingDetail,
                    pathParameters: {'id': listing.listingId},
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
