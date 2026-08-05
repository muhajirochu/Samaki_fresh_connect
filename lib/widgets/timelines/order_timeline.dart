import 'package:flutter/material.dart';
import '../../models/enums/order_status.dart';

class OrderTimeline extends StatelessWidget {
  final OrderStatus currentStatus;

  const OrderTimeline({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimelineStep(
        title: 'Order Placed',
        isActive: true,
        isCompleted: currentStatus.index >= OrderStatus.pending.index,
      ),
      _TimelineStep(
        title: 'Accepted',
        isActive: currentStatus.index >= OrderStatus.accepted.index,
        isCompleted: currentStatus.index >= OrderStatus.accepted.index,
      ),
      _TimelineStep(
        title: 'Preparing Fish',
        isActive: currentStatus.index >= OrderStatus.preparing.index,
        isCompleted: currentStatus.index >= OrderStatus.preparing.index,
      ),
      _TimelineStep(
        title: 'Pickup Generated',
        isActive: currentStatus.index >= OrderStatus.pickupGenerated.index,
        isCompleted: currentStatus.index >= OrderStatus.pickupGenerated.index,
      ),
      _TimelineStep(
        title: 'On the Way',
        isActive: currentStatus.index >= OrderStatus.arriving.index,
        isCompleted: currentStatus.index >= OrderStatus.arriving.index,
      ),
      _TimelineStep(
        title: 'Arriving Soon',
        isActive: currentStatus.index >= OrderStatus.arriving.index,
        isCompleted: currentStatus.index >= OrderStatus.arriving.index,
      ),
      _TimelineStep(
        title: 'Completed',
        isActive: currentStatus.index >= OrderStatus.completed.index,
        isCompleted: currentStatus == OrderStatus.completed,
      ),
    ];

    if (currentStatus == OrderStatus.cancelled) {
      return const Center(
        child: Text(
          'Order Cancelled',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isLast = index == steps.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: step.isActive ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: step.isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: step.isCompleted ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    step.title,
                    style: TextStyle(
                      fontWeight: step.isActive ? FontWeight.bold : FontWeight.normal,
                      color: step.isActive ? Theme.of(context).colorScheme.onSurface : Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _TimelineStep {
  final String title;
  final bool isActive;
  final bool isCompleted;

  _TimelineStep({
    required this.title,
    required this.isActive,
    required this.isCompleted,
  });
}
