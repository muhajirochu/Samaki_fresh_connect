import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/route_paths.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../models/cart_model.dart';
import '../../models/fish_listing_model.dart';
import '../../models/order_model.dart';
import '../../models/enums/order_status.dart';
import '../../models/enums/order_path.dart';
import '../../models/enums/notification_type.dart';
import '../../models/enums/user_role.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/common/premium_components.dart';

class FishListingDetailScreen extends HookConsumerWidget {
  final String listingId;

  const FishListingDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final listingAsync = ref.watch(listingDetailProvider(listingId));
    final currentUser = ref.watch(currentUserStreamProvider).valueOrNull;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.listingDetails,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        // AppBar foreground stays white-on-image so the back button
        // remains legible against the colourful listing image. The
        // scrim under the back button is a translucent black wash.
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.30),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: listingAsync.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => EmptyStateWidget(
            icon: Icons.error_rounded,
            title: l10n.errorLoadingListing,
            subtitle: e.toString(),
          ),
          data: (listing) {
            if (listing == null) {
              return EmptyStateWidget(
                icon: Icons.search_off_rounded,
                title: l10n.listingNotFound,
                subtitle: l10n.listingMayBeRemoved,
              );
            }

            final isOwner = currentUser?.userId == listing.sellerId;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Image Header ──────────────────────────────────────────────
                  Stack(
                    children: [
                      Container(
                        height: 320,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.10),
                        ),
                        child: listing.imageUrls.isNotEmpty
                            ? Image.network(listing.imageUrls.first,
                                fit: BoxFit.cover)
                            : Center(
                                child: Icon(Icons.set_meal_rounded,
                                    size: 80,
                                    color:
                                        cs.onSurface.withValues(alpha: 0.45)),
                              ),
                      ),
                      // Gradient overlay for better text visibility
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 120,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                listing.fishType,
                                // Bounded: an unclamped 28px title wrapped to
                                // three lines for longer fish names and spilled
                                // out past the gradient overlay it sits on.
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: listing.status == 'active'
                                    ? cs.secondary
                                    : cs.onSurface.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                listing.status.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Content ───────────────────────────────────────────────────
                  Transform.translate(
                    offset: const Offset(0, -10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24)),
                      ),
                      padding: const EdgeInsets.all(AppSizes.paddingLG),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pricing Grid
                          PremiumCard(
                            padding: const EdgeInsets.all(AppSizes.paddingLG),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatColumn(
                                  icon: Icons.scale_rounded,
                                  label: 'Quantity',
                                  value: Formatters.formatQuantity(
                                      listing.quantityKg),
                                ),
                                Container(
                                    width: 1,
                                    height: 40,
                                    color: cs.outline.withValues(alpha: 0.30)),
                                _StatColumn(
                                  icon: Icons.sell_rounded,
                                  label: 'Price/kg',
                                  value: Formatters.formatCurrency(
                                      listing.pricePerKg),
                                ),
                                Container(
                                    width: 1,
                                    height: 40,
                                    color: cs.outline.withValues(alpha: 0.30)),
                                _StatColumn(
                                  icon: Icons.payments_rounded,
                                  label: 'Total',
                                  value: Formatters.formatCurrency(
                                      listing.totalPrice),
                                  valueColor: cs.primary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingXL),

                          // Description
                          Text(
                            'Description',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            listing.description?.isEmpty ?? true
                                ? 'No description provided for this listing.'
                                : listing.description!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.65),
                                  height: 1.5,
                                ),
                          ),
                          const SizedBox(height: AppSizes.paddingXXL),

                          // Action Buttons
                          if (!isOwner && listing.status == 'active') ...[
                            _AddToCartButton(
                              listing: listing,
                              currentUser: currentUser,
                            ),
                            const SizedBox(height: AppSizes.paddingSM),
                            _BuyButton(
                                listing: listing, currentUser: currentUser),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatColumn({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 20, color: cs.onSurface.withValues(alpha: 0.55)),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: valueColor ?? cs.onSurface,
              ),
        ),
      ],
    );
  }
}

class _BuyButton extends HookConsumerWidget {
  final FishListingModel listing;
  final UserModel? currentUser;

  const _BuyButton({required this.listing, required this.currentUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    final cs = Theme.of(context).colorScheme;

    Future<void> placeOrder() async {
      if (currentUser == null) return;
      isLoading.value = true;

      final l10n = AppLocalizations.of(context);
      final messenger = ScaffoldMessenger.of(context);

      try {
        final orderService = ref.read(orderServiceProvider);

        // Buyer creates a pending order. The Firestore rules at
        // `firestore.rules` match /orders/{orderId} require
        // `orderStatus == 'pending'` on create, and they let the
        // buyer write that order — but the buyer is NOT allowed to
        // flip the listing's `status` (that would require seller
        // ownership). So the listing stays `active` until the seller
        // confirms; the seller's confirmation path in
        // `OrderService.confirmOrderAndMarkListingSold` atomically
        // transitions the order to `confirmed` AND the listing to
        // `sold`. If two buyers race, both orders stay `pending`
        // and the seller manually picks one.
        final order = OrderModel(
          orderId: '', // Service sets this
          orderPath: OrderPath.directFromDalali.name,
          buyerId: currentUser!.userId,
          // Stamp the order with the LISTING'S seller — that's who
          // needs to see this order in their queue and who will
          // confirm the order. The previous role-check
          // (`currentUser!.role == UserRole.streetSeller`) only
          // worked for street-seller-bought-from-street-seller
          // flows; in the (common) buyer-from-seller case it
          // resolved to `null`, so the seller's
          // `streamOrdersByStreetSeller` query (filtered by
          // `streetSellerId == sellerId`) silently missed every
          // order. Buyers can also act as sellers — see the
          // `currentUser.role == streetSeller` branch — so this is
          // a per-listing decision, not a per-user decision.
          streetSellerId: listing.sellerId,
          listingId: listing.listingId,
          originalPrice: listing.totalPrice,
          finalPrice: listing.totalPrice * 1.07,
          quantityKg: listing.quantityKg,
          orderStatus: OrderStatus.pending.name,
          pickupConfirmed: false,
          deliveryConfirmed: false,
          createdAt: DateTime.now(),
        );

        final orderId = await orderService.createOrder(order);

        // Invalidate the relevant providers so the seller dashboard
        // and buyer orders feed re-render immediately rather than
        // waiting for the next Firestore snapshot event.
        ref.invalidate(sellerListingsProvider(listing.sellerId));
        ref.invalidate(activeListingsProvider);
        ref.invalidate(adminAllListingsProvider);
        ref.invalidate(buyerOrdersProvider(currentUser!.userId));
        ref.invalidate(streetSellerOrdersProvider(listing.sellerId));

        // Notify the seller so the order shows up on their bell +
        // dashboard's pending-orders badge. `writeNotification`
        // returns null gracefully if Firebase is unavailable
        // (mirrors the wishlist pattern); we fire-and-await so the
        // doc is written before the buyer is navigated away.
        final notifSvc = ref.read(notificationServiceProvider);
        final sellerTitle = l10n.orderPlacedSellerTitle;
        final sellerBody = l10n.orderPlacedSellerBody(
          currentUser!.fullName.split(' ').first,
        );
        await notifSvc.writeNotification(
          userId: listing.sellerId,
          title: sellerTitle,
          body: sellerBody,
          type: NotificationType.orderStatusChanged,
          relatedId: orderId,
        );
        await notifSvc.showLocal(
          title: sellerTitle,
          body: sellerBody,
          type: NotificationType.orderStatusChanged,
        );

        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.orderPlacedSuccess),
              backgroundColor: cs.secondary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pushReplacementNamed(
            AppRouteNames.orderDetail,
            pathParameters: {'id': orderId},
          );
        }
      } catch (e) {
        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.errorWithMessage(e.toString())),
              backgroundColor: cs.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CustomButton(
        label:
            'Purchase Now - ${Formatters.formatCurrency(listing.totalPrice * 1.07)}',
        isLoading: isLoading.value,
        onPressed: placeOrder,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Stages this listing in the buyer's cart instead of ordering it
/// immediately. Secondary to [_BuyButton] — outlined, not filled — so
/// "Purchase Now" stays the primary action.
///
/// Only buyers see this. A street seller browsing stock still buys
/// through the direct path; the cart is a buyer-side construct and
/// `cartProvider` is gated on `currentBuyerSessionProvider`, so adding
/// from a seller account would silently no-op.
class _AddToCartButton extends HookConsumerWidget {
  final FishListingModel listing;
  final UserModel? currentUser;

  const _AddToCartButton({required this.listing, required this.currentUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdding = useState(false);
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    if (currentUser?.role != UserRole.buyer) return const SizedBox.shrink();

    final inCart = ref.watch(cartProvider).valueOrNull?.any(
              (i) => i.listingId == listing.listingId,
            ) ??
        false;

    Future<void> addToCart() async {
      if (isAdding.value || inCart) return;
      isAdding.value = true;
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref.read(cartActionsProvider).add(
              CartItem(
                listingId: listing.listingId,
                sellerId: listing.sellerId,
                fishType: listing.fishType,
                pricePerKg: listing.pricePerKg,
                // Default to the whole listing, matching what the
                // direct-purchase button orders. The buyer can dial
                // this down with the stepper in the cart.
                quantityKg: listing.quantityKg,
                imageUrl: listing.imageUrls.isNotEmpty
                    ? listing.imageUrls.first
                    : null,
                addedAt: DateTime.now(),
              ),
            );
        if (!context.mounted) return;
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.cartAddedToCart),
          backgroundColor: cs.secondary,
          behavior: SnackBarBehavior.floating,
        ));
      } catch (e) {
        if (!context.mounted) return;
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.errorWithMessage(e.toString())),
          backgroundColor: cs.error,
          behavior: SnackBarBehavior.floating,
        ));
      } finally {
        isAdding.value = false;
      }
    }

    return OutlinedButton.icon(
      onPressed: inCart || isAdding.value ? null : addToCart,
      icon: isAdding.value
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(inCart
              ? Icons.shopping_cart_rounded
              : Icons.add_shopping_cart_rounded),
      label: Text(inCart ? l10n.cartAlreadyInCart : l10n.addToCart),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
