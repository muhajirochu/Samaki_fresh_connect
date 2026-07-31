// Buyer — Cart.
//
// Lists everything the buyer has staged for ordering, lets them adjust
// quantities, and turns the whole cart into orders in one action.
//
// ── Why checkout re-reads every listing ──────────────────────────────
// `CartItem` snapshots `pricePerKg` at add-time so the list renders
// without an N-way join. That snapshot is display-only. At checkout we
// re-fetch each listing and build the order from the LIVE price and
// the LIVE seller — otherwise a buyer who left the app open overnight
// would place an order at yesterday's price, and the seller would be
// held to it. Listings that have gone inactive or vanished are skipped
// and left in the cart so the buyer can see what did not go through.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/route_paths.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cart_model.dart';
import '../../models/enums/notification_type.dart';
import '../../models/enums/order_path.dart';
import '../../models/enums/order_status.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/common/top_app_bar.dart';

class CartScreen extends HookConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final cartAsync = ref.watch(cartProvider);
    final isCheckingOut = useState(false);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const TopAppBar(),
      body: SafeArea(
        top: false,
        child: cartAsync.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => EmptyStateWidget(
            icon: Icons.error_rounded,
            title: l10n.loadingError(e.toString()),
          ),
          data: (items) {
            if (items.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.shopping_cart_outlined,
                title: l10n.cartEmptyTitle,
                subtitle: l10n.cartEmptySubtitle,
              );
            }
            return _CartList(
              items: items,
              isCheckingOut: isCheckingOut,
            );
          },
        ),
      ),
      bottomNavigationBar: cartAsync.valueOrNull?.isNotEmpty == true
          ? _CheckoutBar(
              isCheckingOut: isCheckingOut,
              onCheckout: () => _checkout(context, ref, isCheckingOut),
            )
          : null,
      floatingActionButton: cartAsync.valueOrNull?.isNotEmpty == true
          ? TextButton.icon(
              onPressed: isCheckingOut.value
                  ? null
                  : () => _confirmClear(context, ref),
              icon: Icon(Icons.delete_sweep_outlined, color: cs.error),
              label: Text(
                l10n.cartClear,
                style: TextStyle(color: cs.error),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cartClearConfirmTitle),
        content: Text(l10n.cartClearConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.cartClear),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(cartActionsProvider).clear();
    }
  }

  /// Turns the cart into one order per listing.
  ///
  /// Orders are created sequentially rather than in a batch because
  /// `OrderService.createOrder` is a single-document write per order
  /// and each one needs its own generated id to attach the seller
  /// notification to. Only listings that succeed are removed from the
  /// cart.
  Future<void> _checkout(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isCheckingOut,
  ) async {
    if (isCheckingOut.value) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cs = Theme.of(context).colorScheme;

    final buyer = ref.read(currentUserStreamProvider).valueOrNull;
    final items = ref.read(cartProvider).valueOrNull ?? const <CartItem>[];
    if (buyer == null || items.isEmpty) return;

    isCheckingOut.value = true;
    try {
      final listingService = ref.read(fishListingServiceProvider);
      final orderService = ref.read(orderServiceProvider);
      final notifSvc = ref.read(notificationServiceProvider);

      final placed = <String>[];
      final touchedSellers = <String>{};

      for (final item in items) {
        // Re-read live. A cart row is a stale snapshot by definition.
        final listing = await listingService.getListingById(item.listingId);
        if (listing == null || listing.status != 'active') continue;

        // Clamp to what the seller actually still has. Ordering more
        // than the listing holds would create an order the seller
        // cannot fulfil.
        final qty = item.quantityKg > listing.quantityKg
            ? listing.quantityKg
            : item.quantityKg;
        if (qty <= 0) continue;

        // Price off the LIVE listing, and the same 7% platform margin
        // the single-listing buy flow applies in
        // `fish_listing_detail_screen.dart`.
        final originalPrice = listing.pricePerKg * qty;
        final order = OrderModel(
          orderId: '',
          orderPath: OrderPath.directFromDalali.name,
          buyerId: buyer.userId,
          // The listing's seller — not the buyer's role — decides
          // whose queue this lands in. Same rule as the detail screen.
          streetSellerId: listing.sellerId,
          listingId: listing.listingId,
          originalPrice: originalPrice,
          finalPrice: originalPrice * 1.07,
          quantityKg: qty,
          orderStatus: OrderStatus.pending.name,
          pickupConfirmed: false,
          deliveryConfirmed: false,
          createdAt: DateTime.now(),
        );

        final orderId = await orderService.createOrder(order);
        placed.add(item.listingId);
        touchedSellers.add(listing.sellerId);

        await notifSvc.writeNotification(
          userId: listing.sellerId,
          title: l10n.orderPlacedSellerTitle,
          body: l10n.orderPlacedSellerBody(buyer.fullName.split(' ').first),
          type: NotificationType.orderStatusChanged,
          relatedId: orderId,
        );
      }

      // Only the successful lines leave the cart; anything sold out
      // stays put so the buyer can see it did not go through.
      if (placed.isNotEmpty) {
        await ref.read(cartActionsProvider).removeMany(placed);
        ref.invalidate(buyerOrdersProvider(buyer.userId));
        for (final sellerId in touchedSellers) {
          ref.invalidate(streetSellerOrdersProvider(sellerId));
        }
      }

      if (!context.mounted) return;
      if (placed.isEmpty) {
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.cartCheckoutFailed),
          backgroundColor: cs.error,
          behavior: SnackBarBehavior.floating,
        ));
      } else if (placed.length < items.length) {
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.cartCheckoutPartial(placed.length, items.length)),
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.cartCheckoutSuccess(placed.length)),
          backgroundColor: cs.secondary,
          behavior: SnackBarBehavior.floating,
        ));
        context.pushNamed(AppRouteNames.orders);
      }
    } catch (_) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.cartCheckoutFailed),
        backgroundColor: cs.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      isCheckingOut.value = false;
    }
  }
}

class _CartList extends ConsumerWidget {
  final List<CartItem> items;
  final ValueNotifier<bool> isCheckingOut;

  const _CartList({required this.items, required this.isCheckingOut});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingLG,
        AppSizes.paddingMD,
        AppSizes.paddingLG,
        // Leaves room for the clear-cart FAB above the checkout bar.
        AppSizes.paddingXXL + 48,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.paddingMD),
      itemBuilder: (context, i) => _CartRow(
        item: items[i],
        enabled: !isCheckingOut.value,
      ),
    );
  }
}

class _CartRow extends ConsumerWidget {
  final CartItem item;
  final bool enabled;

  const _CartRow({required this.item, required this.enabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final actions = ref.read(cartActionsProvider);

    return Dismissible(
      key: ValueKey(item.listingId),
      direction: enabled ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.paddingLG),
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        ),
        child: Icon(Icons.delete_outline_rounded, color: cs.error),
      ),
      onDismissed: (_) async {
        await actions.remove(item.listingId);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.cartItemRemoved),
          behavior: SnackBarBehavior.floating,
        ));
      },
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingSM),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMD),
              child: SizedBox(
                width: 64,
                height: 64,
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumbFallback(cs),
                      )
                    : _thumbFallback(cs),
              ),
            ),
            const SizedBox(width: AppSizes.paddingSM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.fishType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.cartPricePerKg(
                      Formatters.formatCurrency(item.pricePerKg),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.formatCurrency(item.lineTotal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            _QuantityStepper(
              quantityKg: item.quantityKg,
              enabled: enabled,
              onChanged: (q) => actions.updateQuantity(item.listingId, q),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbFallback(ColorScheme cs) => ColoredBox(
        color: cs.primary.withValues(alpha: 0.10),
        child: Icon(Icons.set_meal_rounded, color: cs.primary),
      );
}

class _QuantityStepper extends StatelessWidget {
  final double quantityKg;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _QuantityStepper({
    required this.quantityKg,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepButton(
              icon: Icons.remove_rounded,
              // At 1kg the next step down is 0, which the service
              // treats as a removal — so stop here and let the swipe
              // gesture be the one deliberate way to delete a row.
              onTap: enabled && quantityKg > 1
                  ? () => onChanged(quantityKg - 1)
                  : null,
            ),
            SizedBox(
              width: 44,
              child: Text(
                Formatters.formatQuantity(quantityKg),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            _StepButton(
              icon: Icons.add_rounded,
              onTap: enabled ? () => onChanged(quantityKg + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: onTap == null
          ? cs.onSurface.withValues(alpha: 0.06)
          : cs.primary.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: onTap == null
                ? cs.onSurface.withValues(alpha: 0.35)
                : cs.primary,
          ),
        ),
      ),
    );
  }
}

class _CheckoutBar extends ConsumerWidget {
  final ValueNotifier<bool> isCheckingOut;
  final VoidCallback onCheckout;

  const _CheckoutBar({required this.isCheckingOut, required this.onCheckout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final total = ref.watch(cartTotalProvider);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.paddingLG,
          AppSizes.paddingSM,
          AppSizes.paddingLG,
          AppSizes.paddingSM,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outline.withValues(alpha: 0.20)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.cartTotal,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Formatters.formatCurrency(total),
                      maxLines: 1,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.paddingSM),
            FilledButton.icon(
              onPressed: isCheckingOut.value ? null : onCheckout,
              icon: isCheckingOut.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(l10n.cartCheckout),
            ),
          ],
        ),
      ),
    );
  }
}
