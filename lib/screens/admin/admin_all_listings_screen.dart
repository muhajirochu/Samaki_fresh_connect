// Admin — All Listings (marketplace moderation).
//
// Lists every listing across the platform with status / price /
// seller + a delete action. Reactive via Firestore snapshots so
// the admin sees new listings appear in real time.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums/fish_type.dart';
import '../../models/fish_listing_model.dart';
import '../../providers/admin_provider.dart';
import '../../utils/logger.dart';

class AdminAllListingsScreen extends ConsumerWidget {
  const AdminAllListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final listingsAsync = ref.watch(adminAllListingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.allListings)),
      body: listingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(l10n.loadingError(e.toString()))),
        data: (listings) {
          if (listings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingXL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_rounded,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5)),
                    const SizedBox(height: AppSizes.paddingMD),
                    Text(
                      l10n.noListingsFound,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSizes.paddingSM),
                    Text(
                      l10n.noListingsFoundSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminAllListingsProvider);
              await Future<void>.delayed(
                const Duration(milliseconds: 300),
              );
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSizes.paddingLG),
              itemCount: listings.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSizes.paddingMD),
              itemBuilder: (_, i) =>
                  _ListingRow(listings[i], key: ValueKey(listings[i].listingId)),
            ),
          );
        },
      ),
    );
  }
}

class _ListingRow extends ConsumerWidget {
  final FishListingModel listing;
  const _ListingRow(this.listing, {super.key});

  Color _statusColor(BuildContext context) {
    switch (listing.status) {
      case 'active':
        return AppColors.accentGreen;
      case 'sold':
        return AppColors.infoBlue;
      case 'expired':
        return AppColors.errorRed;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteListing),
        content: Text(l10n.deleteListingConfirmationAdmin),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorRed,
            ),
            child: Text(l10n.deleteListing),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (listing.listingId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorGeneric('Missing listing id')),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final service = ref.read(adminListingServiceProvider);
    try {
      await service.deleteListing(listing.listingId);
      AppLogger.info('Admin deleted listing ${listing.listingId}');
      ref.invalidate(adminAllListingsProvider);
      ref.invalidate(adminActiveListingsCountProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.listingDeleted),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorGeneric(e.toString())),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final statusColor = _statusColor(context);
    final fishTypeLabel = FishTypeExtension.fromString(listing.fishType)
            .displayName;
    final price = listing.pricePerKg;
    final qty = listing.quantityKg;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSizes.radiusMD),
            ),
            child: const Icon(Icons.set_meal_rounded),
          ),
          const SizedBox(width: AppSizes.paddingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fishTypeLabel,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'TZS ${price.toStringAsFixed(0)}/kg · ${qty.toStringAsFixed(1)} kg',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    listing.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.errorRed,
            ),
            onPressed: () => _confirmDelete(context, ref),
            tooltip: l10n.deleteListing,
          ),
        ],
      ),
    );
  }
}
