import 'package:flutter/material.dart';
import '../../models/enums/order_status.dart';
import '../../models/order_model.dart';

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
                  Text(
                    'Order #${order.orderId.substring(0, 8).toUpperCase()}',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  _StatusChip(status: order.status),
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
                  Text(
                    'TZS ${order.totalPrice.toStringAsFixed(0)}',
                    style: textTheme.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
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
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        label = 'Pending';
        break;
      case OrderStatus.accepted:
      case OrderStatus.preparing:
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        label = 'Preparing';
        break;
      case OrderStatus.pickupGenerated:
      case OrderStatus.arriving:
        bgColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        label = 'On the Way';
        break;
      case OrderStatus.completed:
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = 'Completed';
        break;
      case OrderStatus.cancelled:
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        label = 'Cancelled';
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
