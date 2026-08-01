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
    // Maps the implemented order lifecycle onto theme tokens. The
    // happy path is `pending → confirmed → inTransit → completed`;
    // `cancelled` is the terminal off-path state. The enum only
    // contains these five values (see `OrderStatus`), so this
    // switch is exhaustive by construction.
    switch (status) {
      case OrderStatus.pending:
        // Buyer has placed the order; awaiting seller confirmation.
        return cs.tertiary;
      case OrderStatus.confirmed:
        // Seller has accepted the order; brand-primary to read as
        // an active milestone rather than a passive wait state.
        return cs.primary;
      case OrderStatus.inTransit:
        // Seller has handed the order off; still brand-primary to
        // signal an active, in-flight order.
        return cs.primary;
      case OrderStatus.completed:
        // Terminal happy-path state — secondary reads as a quieter
        // "done" colour distinct from the active primary.
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