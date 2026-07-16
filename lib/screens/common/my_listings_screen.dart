// My Listings screen — for street sellers and dalalis. Lists every
// listing owned by the current user and surfaces the per-card action
// menu (Edit / Mark Sold / Delete). All actions go through the
// `ListingManagementController`, which checks ownership before writing.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/enums/listing_status.dart';
import '../../models/fish_listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/cards/fish_listing_card.dart';
import '../../widgets/common/common_widgets.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Listings',
            style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        centerTitle: true,
      ),
      body: userAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => EmptyStateWidget(
          icon: Icons.error_rounded,
          title: 'Error loading user data',
          subtitle: e.toString(),
        ),
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          final provider = sellerListingsProvider(user.userId);
          final listingsAsync = ref.watch(provider);
          return listingsAsync.when(
            loading: () =>
                const LoadingIndicator(message: 'Loading your listings...'),
            error: (error, _) => EmptyStateWidget(
              icon: Icons.error_outline_rounded,
              title: 'Failed to load listings',
              subtitle: error.toString(),
              onRetry: () => ref.refresh(provider),
            ),
            data: (listings) {
              if (listings.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.inventory_2_rounded,
                  title: 'No Listings Yet',
                  subtitle: 'Create a listing to start selling!',
                  onRetry: () => ref.refresh(provider),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.refresh(provider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.paddingLG),
                  itemCount: listings.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSizes.paddingMD),
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return _ManageableListingCard(listing: listing);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/listings/create'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 4,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _ManageableListingCard extends ConsumerWidget {
  final FishListingModel listing;
  const _ManageableListingCard({required this.listing});

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLG)),
        title: const Text('Delete listing?'),
        content: Text(
          'This will permanently remove the ${listing.fishType} listing '
          '(${listing.quantityKg.toStringAsFixed(1)} kg). Buyers will no '
          'longer see it on the marketplace.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(listingManagementControllerProvider.notifier)
        .deleteListing(listing.listingId);
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.success
            ? 'Listing deleted'
            : (result.error ?? 'Delete failed')),
        backgroundColor:
            result.success ? AppColors.successGreen : AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _markSold(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(listingManagementControllerProvider.notifier)
        .markAsSold(listing.listingId);
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.success
            ? 'Marked as sold'
            : (result.error ?? 'Action failed')),
        backgroundColor:
            result.success ? AppColors.successGreen : AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final sold = listing.status == ListingStatus.sold.value;
    final expired = listing.status == ListingStatus.expired.value;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXL)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusXL)),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.paddingSM,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit_rounded,
                    color: cs.primary),
                title: Text('Edit',
                    style: tt.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                subtitle: const Text('Update price, quantity or description'),
                onTap: expired || sold
                    ? null
                    : () {
                        Navigator.of(ctx).pop();
                        context.push('/listings/${listing.listingId}/edit');
                      },
              ),
              ListTile(
                leading: Icon(
                  Icons.check_circle_rounded,
                  color: sold
                      ? cs.onSurface.withValues(alpha: 0.45)
                      : AppColors.successGreen,
                ),
                title: Text(sold ? 'Already sold' : 'Mark as sold',
                    style: tt.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                subtitle: const Text('Hide from marketplace'),
                onTap: sold || expired
                    ? null
                    : () async {
                        Navigator.of(ctx).pop();
                        await _markSold(context, ref);
                      },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_rounded, color: AppColors.errorRed),
                title: const Text('Delete',
                    style: TextStyle(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w700)),
                subtitle: const Text('Remove this listing permanently'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _confirmAndDelete(context, ref);
                },
              ),
              const SizedBox(height: AppSizes.paddingSM),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        FishListingCard(
          listing: listing,
          onTap: () => context.push('/listings/${listing.listingId}'),
        ),
        Positioned(
          top: 6,
          left: 6,
          child: Material(
            color: cs.scrim.withValues(alpha: 0.55),
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              tooltip: 'Manage listing',
              onPressed: () => _showActions(context, ref),
            ),
          ),
        ),
      ],
    );
  }
}
