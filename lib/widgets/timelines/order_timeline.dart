import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/enums/order_status.dart';
import '../../utils/formatters.dart';

class OrderTimeline extends StatelessWidget {
  final OrderStatus currentStatus;
  final DateTime createdAt;
  final DateTime? completedAt;

  const OrderTimeline({
    super.key,
    required this.currentStatus,
    required this.createdAt,
    this.completedAt,
  });

  @override
  Widget build(BuildContext context) {
    // Define the generic happy path
    final steps = [
      OrderStatus.placed,
      OrderStatus.assigned,
      OrderStatus.pickedUp,
      OrderStatus.inTransit,
      OrderStatus.delivered,
    ];

    if (currentStatus == OrderStatus.cancelled) {
      return const Padding(
        padding: EdgeInsets.all(AppSizes.paddingMD),
        child: Text(
          'Order was Cancelled',
          style: TextStyle(
            color: AppColors.errorRed,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    int currentIndex = steps.indexOf(currentStatus);
    if (currentIndex == -1) {
      // Handle edge cases like 'negotiating' or 'completed'
      if (currentStatus == OrderStatus.completed) {
        currentIndex = steps.length - 1; // All done
      } else {
        currentIndex = 0; // Fallback
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        final stepStatus = steps[index];
        final isCompleted = index <= currentIndex;
        final isLast = index == steps.length - 1;
        final isCurrent = index == currentIndex;

        // Determine timestamp logic
        String? timeStr;
        if (index == 0) timeStr = Formatters.formatDateTime(createdAt);
        if (isLast &&
            currentStatus == OrderStatus.completed &&
            completedAt != null) {
          timeStr = Formatters.formatDateTime(completedAt!);
        }

        return _TimelineNode(
          title: stepStatus.displayName,
          subtitle: timeStr,
          isCompleted: isCompleted,
          isLast: isLast,
          isCurrent: isCurrent,
        );
      }),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isCompleted;
  final bool isLast;
  final bool isCurrent;

  const _TimelineNode({
    required this.title,
    this.subtitle,
    required this.isCompleted,
    required this.isLast,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Line & Dot ──────────────────────────────────────────────────────
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isCompleted ? AppColors.primaryBlue : AppColors.gray200,
                  border: isCurrent
                      ? Border.all(color: AppColors.secondaryTeal, width: 3)
                      : null,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: AppColors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color:
                        isCompleted ? AppColors.primaryBlue : AppColors.gray200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSizes.paddingMD),
          // ── Content ─────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.paddingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isCompleted
                              ? AppColors.gray900
                              : AppColors.gray500,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.w500,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.gray500,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
