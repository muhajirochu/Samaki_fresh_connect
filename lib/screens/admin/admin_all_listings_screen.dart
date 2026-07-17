// Admin — All Listings (marketplace moderation).
//
// Lists every listing across the platform with status / price /
// seller. Two interaction modes:
//
//   • Browse mode (default): tapping opens the listing detail;
//     the trailing icon still offers a quick single delete.
//
//   • Select mode: a long-press anywhere on a row, or the
//     "Select" action in the AppBar, flips the list into bulk
//     delete mode. While in select mode:
//       – every row shows a leading checkbox
//       – the AppBar shows the current selection count and a
//         Select-all toggle
//       – a bottom action bar appears with a single red
//         "Delete selected (N)" button
//
// Delete operations go through [FishListingService] — single
// deletes hit `deleteListing`, bulk deletes use `deleteListingsBulk`
// (a Firestore WriteBatch) so 100 listings commit in a single
// network round trip.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums/fish_type.dart';
import '../../models/fish_listing_model.dart';
import '../../providers/admin_provider.dart';
import '../../utils/logger.dart';

class AdminAllListingsScreen extends ConsumerStatefulWidget {
  const AdminAllListingsScreen({super.key});

  @override
  ConsumerState<AdminAllListingsScreen> createState() =>
      _AdminAllListingsScreenState();
}

class _AdminAllListingsScreenState
    extends ConsumerState<AdminAllListingsScreen> {
  /// Selection state — only meaningful while [selectMode] is true.
  final Set<String> _selectedIds = <String>{};
  bool _selectMode = false;

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      if (!_selectMode) _selectedIds.clear();
    });
  }

  void _toggleSelection(String listingId) {
    setState(() {
      if (_selectedIds.contains(listingId)) {
        _selectedIds.remove(listingId);
      } else {
        _selectedIds.add(listingId);
      }
    });
  }

  void _selectAll(List<FishListingModel> listings) {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(listings.map((l) => l.listingId));
    });
  }

  void _deselectAll() {
    setState(_selectedIds.clear);
  }

  Future<void> _confirmBulkDelete(List<FishListingModel> listings) async {
    final l10n = AppLocalizations.of(context);
    final selected =
        listings.where((l) => _selectedIds.contains(l.listingId)).toList();
    if (selected.isEmpty) return;
    final ids = selected.map((l) => l.listingId).toList(growable: false);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSelected),
        content: Text(l10n.deleteListingsConfirmationAdmin(selected.length)),
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

    final service = ref.read(adminListingServiceProvider);
    try {
      final deleted = await service.deleteListingsBulk(ids);
      AppLogger.info('Admin bulk-deleted $deleted listings');
      ref.invalidate(adminAllListingsProvider);
      ref.invalidate(adminActiveListingsCountProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.listingsDeleted(deleted)),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() {
        _selectedIds.clear();
        _selectMode = false;
      });
    } catch (e) {
      if (mounted) {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final listingsAsync = ref.watch(adminAllListingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectMode
              ? l10n.selectedCount(_selectedIds.length)
              : l10n.allListings,
        ),
        actions: listingsAsync.maybeWhen(
          data: (listings) => [
            if (_selectMode) ...[
              // Select-all toggle — only meaningful when there is
              // something to select.
              if (_selectedIds.length < listings.length)
                IconButton(
                  tooltip: l10n.selectAll,
                  icon: const Icon(Icons.select_all_rounded),
                  onPressed: () => _selectAll(listings),
                )
              else
                IconButton(
                  tooltip: l10n.deselectAll,
                  icon: const Icon(Icons.deselect_rounded),
                  onPressed: _deselectAll,
                ),
            ] else
              IconButton(
                tooltip: l10n.selectMode,
                icon: const Icon(Icons.checklist_rounded),
                onPressed: _toggleSelectMode,
              ),
            IconButton(
              tooltip: _selectMode ? l10n.exitSelectMode : l10n.refresh,
              icon: Icon(
                _selectMode
                    ? Icons.close_rounded
                    : Icons.refresh_rounded,
              ),
              onPressed: () {
                if (_selectMode) {
                  _toggleSelectMode();
                } else {
                  ref.invalidate(adminAllListingsProvider);
                }
              },
            ),
          ],
          orElse: () => null,
        ),
      ),
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
          final selectedCount = _selectedIds.length;
          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminAllListingsProvider);
                  await Future<void>.delayed(
                    const Duration(milliseconds: 300),
                  );
                },
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    AppSizes.paddingLG,
                    AppSizes.paddingLG,
                    AppSizes.paddingLG,
                    _selectMode && selectedCount > 0
                        ? 96 // leave room for the bottom action bar
                        : AppSizes.paddingLG,
                  ),
                  itemCount: listings.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSizes.paddingMD),
                  itemBuilder: (_, i) {
                    final listing = listings[i];
                    final selected =
                        _selectedIds.contains(listing.listingId);
                    return _ListingRow(
                      listing: listing,
                      selectMode: _selectMode,
                      selected: selected,
                      onTap: () {
                        if (_selectMode) _toggleSelection(listing.listingId);
                      },
                      onLongPress: () {
                        if (!_selectMode) {
                          setState(() => _selectMode = true);
                        }
                        _toggleSelection(listing.listingId);
                      },
                      onSingleDelete: () =>
                          _confirmSingleDelete(context, ref, listing),
                      onToggleSelect: () =>
                          _toggleSelection(listing.listingId),
                    );
                  },
                ),
              ),
              // Bulk-delete action bar — slides in from the bottom
              // when at least one row is selected.
              if (_selectMode && selectedCount > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _BulkDeleteBar(
                    count: selectedCount,
                    onCancel: _toggleSelectMode,
                    onDelete: () => _confirmBulkDelete(listings),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmSingleDelete(
    BuildContext context,
    WidgetRef ref,
    FishListingModel listing,
  ) async {
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
}

// ── Listing row ──────────────────────────────────────────────────────────
//
// In browse mode this is a plain Material card with a trailing
// delete icon. In select mode the card grows a leading checkbox,
// gets tinted when selected, and the trailing icon switches to a
// standalone checkbox.

class _ListingRow extends StatelessWidget {
  final FishListingModel listing;
  final bool selectMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleSelect;
  final VoidCallback onSingleDelete;

  const _ListingRow({
    required this.listing,
    required this.selectMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleSelect,
    required this.onSingleDelete,
  });

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final statusColor = _statusColor(context);
    final fishTypeLabel =
        FishTypeExtension.fromString(listing.fishType).displayName;
    final price = listing.pricePerKg;
    final qty = listing.quantityKg;

    final borderColor = selected
        ? AppColors.errorRed
        : cs.outline.withValues(alpha: 0.25);

    return Material(
      color: selected
          ? AppColors.errorRed.withValues(alpha: 0.06)
          : cs.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLG),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.6 : 0.8,
            ),
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
              if (selectMode)
                Padding(
                  padding: const EdgeInsets.only(right: AppSizes.paddingSM),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Checkbox(
                      value: selected,
                      onChanged: (_) => onToggleSelect(),
                      activeColor: AppColors.errorRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
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
              if (!selectMode)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.errorRed,
                  ),
                  onPressed: onSingleDelete,
                  tooltip: l10n.deleteListing,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bulk-delete action bar ───────────────────────────────────────────────

class _BulkDeleteBar extends StatelessWidget {
  final int count;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const _BulkDeleteBar({
    required this.count,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSizes.paddingMD),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMD,
          vertical: AppSizes.paddingSM,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          border: Border.all(
            color: AppColors.errorRed.withValues(alpha: 0.45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.selectedCount(count),
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: onCancel,
              child: Text(l10n.cancel),
            ),
            const SizedBox(width: AppSizes.paddingSM),
            FilledButton.icon(
              onPressed: onDelete,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusMD),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMD,
                  vertical: AppSizes.paddingSM,
                ),
              ),
              icon: const Icon(Icons.delete_sweep_rounded, size: 18),
              label: Text(
                l10n.deleteSelected,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}