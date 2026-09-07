import 'package:flutter/material.dart';
import 'package:samakifresh_connect/l10n/app_localizations.dart';
import '../../models/enums/order_status.dart';
import '../../models/order_model.dart';

/// Returns true when [s] is not a terminal state — i.e., the buyer or
/// seller can still act on this order (accept, prepare, deliver, etc.).
/// Used to decide whether the "Track" CTA is shown on the order card.
bool isActiveOrderStatus(OrderStatus s) =>
    s.index < OrderStatus.completed.index && s != OrderStatus.cancelled;

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.orderId.substring(0, order.orderId.length > 8 ? 8 : order.orderId.length).toUpperCase()}',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PaymentChip(isPaid: order.isPaid, paymentMethod: order.paymentMethod),
                      const SizedBox(width: 6),
                      _StatusChip(status: order.status),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Text('${order.quantity}x Fish Item', style: textTheme.bodyLarge),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TZS ${order.totalPrice.toStringAsFixed(0)}',
                        style: textTheme.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.bold),
                      ),
                      if (order.isPaid && order.paymentReference.isNotEmpty)
                        Text(
                          'Ref: ${order.paymentReference}',
                          style: textTheme.bodySmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (isActiveOrderStatus(order.status)) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.directions),
                    label: const Text('Track'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case OrderStatus.pending:
        bgColor = const Color(0xFFE0F2FE);   // sky-100
        textColor = const Color(0xFF0369A1);  // sky-700
        label = 'Pending';
        break;
      case OrderStatus.confirmed:
        bgColor = const Color(0xFFDBEAFE);   // blue-100
        textColor = const Color(0xFF1D4ED8);  // blue-700
        label = '🔒 Paid (Held)';
        break;
      case OrderStatus.preparing:
        bgColor = const Color(0xFFBAE6FD);   // sky-200
        textColor = const Color(0xFF0284C7);  // sky-600
        label = 'Preparing';
        break;
      case OrderStatus.readyForPickup:
      case OrderStatus.outForDelivery:
        bgColor = const Color(0xFF7DD3FC);   // sky-300
        textColor = const Color(0xFF075985);  // sky-800
        label = 'On the Way';
        break;
      case OrderStatus.completed:
        bgColor = const Color(0xFF0369A1);   // sky-700
        textColor = const Color(0xFFFFFFFF);  // white
        label = 'Completed';
        break;
      case OrderStatus.cancelled:
        bgColor = const Color(0xFF1E3A55);   // dark navy
        textColor = const Color(0xFFBAE6FD);  // sky-200
        label = 'Cancelled';
        break;
      case OrderStatus.disputed:
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        label = AppLocalizations.of(context).statusDisputed;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final bool isPaid;
  final String paymentMethod;

  const _PaymentChip({required this.isPaid, required this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    if (isPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0369A1),   // sky-700
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'IMELPIWA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFBAE6FD),  // sky-200
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0284C7), width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.payments_outlined, size: 12, color: Color(0xFF0369A1)),
          SizedBox(width: 4),
          Text(
            'PESA TASLIMU',
            style: TextStyle(
              color: Color(0xFF075985),
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
