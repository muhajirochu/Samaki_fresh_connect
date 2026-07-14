import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/order_model.dart';
import '../../models/enums/order_status.dart';
import '../../utils/formatters.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = OrderStatusExtension.fromString(order.orderStatus);
    final statusColor = _colorForStatus(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        size: 18,
                        color: AppColors.primaryBlue,
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
                              ?.copyWith(color: AppColors.gray500),
                        ),
                      ],
                    ),
                  ],
                ),
                // Status chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                  ),
                  child: Text(
                    status.displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingMD),
            const Divider(height: 1, color: AppColors.gray100),
            const SizedBox(height: AppSizes.paddingMD),
            // ── Details ───────────────────────────────────────────────────────
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
                  valueColor: AppColors.primaryBlue,
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
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _shortId(String id) =>
      id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  Color _colorForStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return AppColors.warningAmber;
      case OrderStatus.assigned:
        return AppColors.infoBlue;
      case OrderStatus.negotiating:
        return Colors.purple;
      case OrderStatus.pickedUp:
        return AppColors.accentOrange;
      case OrderStatus.inTransit:
        return AppColors.primaryBlue;
      case OrderStatus.delivered:
        return AppColors.secondaryTeal;
      case OrderStatus.completed:
        return AppColors.successGreen;
      case OrderStatus.cancelled:
        return AppColors.errorRed;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.gray500),
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
