import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../models/order_model.dart';
import '../../models/enums/order_status.dart';
import '../../utils/formatters.dart';
import '../common/premium_components.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = OrderStatusExtension.fromString(order.orderStatus);
    final statusColor = _colorForStatus(status, Theme.of(context).colorScheme);
    final cs = Theme.of(context).colorScheme;

    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      size: 18,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${_shortId(order.orderId)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        Formatters.formatRelativeTime(order.createdAt),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              // Status pill
              StatusPill(label: status.displayName, color: statusColor),
            ],
          ),
          const SizedBox(height: AppSizes.paddingMD),
          Divider(height: 1, color: cs.outlineVariant),
          const SizedBox(height: AppSizes.paddingMD),
          // ── Details ─────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DetailItem(
                label: 'Quantity',
                value: Formatters.formatQuantity(order.quantityKg),
              ),
              _DetailItem(
                label: 'Amount',
                value: Formatters.formatCurrency(order.finalPrice),
                valueColor: cs.primary,
              ),
              _DetailItem(
                label: 'Path',
                value: order.orderPath
                    .replaceAll(RegExp(r'(?=[A-Z])'), ' ')
                    .trim(),
              ),
            ],
          ),
          if (onTap != null) ...[
            const SizedBox(height: AppSizes.paddingMD),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'View Details →',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _shortId(String id) =>
      id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  Color _colorForStatus(OrderStatus status, ColorScheme cs) {
    switch (status) {
      case OrderStatus.pending:
        // Buyer has placed the order; awaiting seller confirmation.
        // Same colour family as `placed` so the two first-step
        // states read as related stages on the card.
        return cs.tertiary;
      case OrderStatus.placed:
        return cs.tertiary;
      case OrderStatus.assigned:
        return cs.primary;
      case OrderStatus.negotiating:
        // Purple is a distinct negotiation cue — kept as raw hex so
        // it reads the same in both themes. Not a theme token.
        return const Color(0xFF8B5CF6);
      case OrderStatus.pickedUp:
        return cs.tertiary;
      case OrderStatus.inTransit:
        return cs.primary;
      case OrderStatus.delivered:
        return cs.tertiary;
      case OrderStatus.completed:
        return cs.secondary;
      case OrderStatus.cancelled:
        return cs.error;
    }
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailItem(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}