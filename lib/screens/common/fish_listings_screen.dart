import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/cards/fish_listing_card.dart';
import '../../widgets/common/common_widgets.dart';

class FishListingsScreen extends ConsumerWidget {
  const FishListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(activeListingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        elevation: 0,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: listingsAsync.when(
        loading: () =>
            const LoadingIndicator(message: 'Loading fresh catch...'),
        error: (error, stack) => EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Failed to load listings',
          subtitle: error.toString(),
          onRetry: () => ref.refresh(activeListingsProvider),
        ),
        data: (listings) {
          if (listings.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.set_meal_outlined,
              title: 'No Fish Available',
              subtitle: 'Check back later for fresh catch!',
              onRetry: () => ref.refresh(activeListingsProvider),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(activeListingsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSizes.paddingLG),
              itemCount: listings.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSizes.paddingMD),
              itemBuilder: (context, index) {
                final listing = listings[index];
                return FishListingCard(
                  listing: listing,
                  onTap: () => context.push('/listings/${listing.listingId}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
