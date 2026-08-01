import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../config/theme_extensions.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums/order_status.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/common/premium_components.dart';
import '../../widgets/timelines/order_timeline.dart';
import '../../utils/formatters.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final currentUser = ref.watch(currentUserStreamProvider).valueOrNull;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.orderDetails,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: orderAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => EmptyStateWidget(
          icon: Icons.error_rounded,
          title: l10n.errorLoadingOrder,
          subtitle: e.toString(),
        ),
        data: (order) {
          if (order == null) {
            return EmptyStateWidget(
              icon: Icons.search_off_rounded,
              title: l10n.orderNotFound,
              subtitle: l10n.orderMayBeDeleted,
            );
          }

          final status = OrderStatusExtension.fromString(order.orderStatus);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Completion Banner ──────────────────────────────────────
                // Shown only when the order has reached the terminal
                // `completed` state. Without this banner the only
                // visible difference between `inTransit` and `completed`
                // is the timeline's last dot, which is easy to miss.
                // The banner gives the buyer an unambiguous "order is
                // done" confirmation in the header area.
                if (status == OrderStatus.completed)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSizes.paddingLG),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingMD, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMD),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 24),
                        const SizedBox(width: AppSizes.paddingMD),
                        Expanded(
                          child: Text(
                            'Order completed successfully',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Header Summary ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingLG),
                  decoration: BoxDecoration(
                    gradient: AppGradients.of(context).brand,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total Amount',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onPrimary.withValues(alpha: 0.80),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Formatters.formatCurrency(order.finalPrice),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: AppSizes.paddingLG),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.onPrimary.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMD),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tag_rounded,
                                color: cs.onPrimary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              order.orderId
                                  .substring(0, 8)
                                  .toUpperCase(), // Shortened for display
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: cs.onPrimary,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.0,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXXL),

                // ── Timeline ──────────────────────────────────────────────────
                PremiumCard(
                  padding: const EdgeInsets.all(AppSizes.paddingLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.route_rounded,
                              color: cs.primary, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Order Status',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.paddingLG),
                      OrderTimeline(
                        currentStatus: status,
                        createdAt: order.createdAt,
                        completedAt: order.completedAt,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXXL),

                // ── Actions ───────────────────────────────────────────────────
                if (status != OrderStatus.cancelled &&
                    status != OrderStatus.completed)
                  _OrderActions(
                    orderId: order.orderId,
                    listingId: order.listingId,
                    status: status,
                    isStreetSeller: order.streetSellerId != null &&
                        currentUser?.userId == order.streetSellerId,
                    isBuyer: currentUser?.userId == order.buyerId,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OrderActions extends ConsumerWidget {
  final String orderId;
  final String listingId;
  final OrderStatus status;
  final bool isStreetSeller;
  final bool isBuyer;

  const _OrderActions({
    required this.orderId,
    required this.listingId,
    required this.status,
    required this.isStreetSeller,
    required this.isBuyer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Seller: pending order — Confirm (atomic with listing → sold)
    // or Reject.
    if (status == OrderStatus.pending && isStreetSeller) {
      return Row(
        children: [
          Expanded(
            child: CustomButton(
              label: 'Confirm Order',
              style: _actionStyle(),
              onPressed: () async {
                try {
                  await ref
                      .read(orderServiceProvider)
                      .confirmOrderAndMarkListingSold(
                        orderId: orderId,
                        listingId: listingId,
                      );
                  ref.invalidate(orderDetailProvider(orderId));
                  ref.invalidate(activeListingsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order confirmed; listing marked sold.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to confirm: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(width: AppSizes.paddingMD),
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusLG),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                  width: 1.5,
                ),
              ),
              onPressed: () async {
                try {
                  await ref
                      .read(orderServiceProvider)
                      .rejectPendingOrder(orderId);
                  ref.invalidate(orderDetailProvider(orderId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order rejected.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to reject: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Reject'),
            ),
          ),
        ],
      );
    }

    // Seller: confirmed order — Mark In Transit (handed off to
    // buyer / out for delivery). Firestore rules permit
    // `confirmed → in_transit` for the seller at
    // match /orders/{orderId} (see firestore.rules).
    if (status == OrderStatus.confirmed && isStreetSeller) {
      return CustomButton(
        label: 'Mark In Transit',
        style: _actionStyle(),
        onPressed: () async {
          try {
            await ref
                .read(orderServiceProvider)
                .updateOrderStatus(orderId, 'inTransit');
            ref.invalidate(orderDetailProvider(orderId));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order marked as in transit.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update: $e'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      );
    }

    // Buyer: in-transit order — Confirm Receipt (terminal
    // transition to `completed`). Closes the lifecycle and unlocks
    // payout analytics. See [OrderService.confirmReceipt].
    if (status == OrderStatus.inTransit && isBuyer) {
      return CustomButton(
        label: 'Confirm Receipt',
        style: _actionStyle(),
        onPressed: () async {
          try {
            await ref.read(orderServiceProvider).confirmReceipt(orderId);
            ref.invalidate(orderDetailProvider(orderId));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Receipt confirmed. Order completed.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to confirm receipt: $e'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      );
    }

    return const SizedBox.shrink();
  }

  ButtonStyle _actionStyle() {
    return FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
    );
  }
}
