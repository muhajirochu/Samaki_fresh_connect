import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../config/theme_extensions.dart';
import '../../constants/app_sizes.dart';
import '../../models/enums/order_status.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/common/premium_components.dart';
import '../../widgets/timelines/order_timeline.dart';
import '../../utils/formatters.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final currentUser = ref.watch(currentUserStreamProvider).valueOrNull;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Order Details',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: orderAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => EmptyStateWidget(
          icon: Icons.error_rounded,
          title: 'Error loading order',
          subtitle: e.toString(),
        ),
        data: (order) {
          if (order == null) {
            return const EmptyStateWidget(
              icon: Icons.search_off_rounded,
              title: 'Order not found',
              subtitle: 'This order may have been deleted.',
            );
          }

          final status = OrderStatusExtension.fromString(order.orderStatus);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                    status: status,
                    isDalali: currentUser?.role.name == 'dalali',
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
  final OrderStatus status;
  final bool isDalali;

  const _OrderActions({
    required this.orderId,
    required this.status,
    required this.isDalali,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (status == OrderStatus.placed && isDalali) {
      return CustomButton(
        label: 'Assign Delivery',
        onPressed: () async {
          await ref.read(orderServiceProvider).updateOrderStatus(
                orderId,
                OrderStatus.assigned.name,
              );
          ref.invalidate(orderDetailProvider(orderId));
        },
        style: _actionStyle(),
      );
    }

    if (status == OrderStatus.assigned && isDalali) {
      return CustomButton(
        label: 'Confirm Pickup',
        onPressed: () async {
          await ref.read(orderServiceProvider).confirmPickup(orderId);
          ref.invalidate(orderDetailProvider(orderId));
        },
        style: _actionStyle(),
      );
    }

    if (status == OrderStatus.inTransit && isDalali) {
      return CustomButton(
        label: 'Confirm Delivery',
        onPressed: () async {
          await ref.read(orderServiceProvider).confirmDelivery(orderId);
          ref.invalidate(orderDetailProvider(orderId));
        },
        style: _actionStyle(),
      );
    }

    if (status == OrderStatus.pickedUp && isDalali) {
      return CustomButton(
        label: 'Mark In Transit',
        onPressed: () async {
          await ref.read(orderServiceProvider).updateOrderStatus(
                orderId,
                OrderStatus.inTransit.name,
              );
          ref.invalidate(orderDetailProvider(orderId));
        },
        style: _actionStyle(),
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
