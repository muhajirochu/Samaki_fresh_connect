import 'package:flutter/material.dart';
import '../../models/enums/order_status.dart';

class HorizontalOrderTimeline extends StatelessWidget {
  final OrderStatus currentStatus;

  const HorizontalOrderTimeline({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    // The design only shows 4 primary steps in the horizontal timeline.
    final steps = [
      _HStep(
        title: 'Accepted',
        icon: Icons.check,
        isActive: currentStatus.index >= OrderStatus.accepted.index,
        isCompleted: currentStatus.index > OrderStatus.accepted.index,
      ),
      _HStep(
        title: 'On the Way',
        icon: Icons.directions_bike,
        isActive: currentStatus.index >= OrderStatus.arriving.index,
        isCompleted: currentStatus.index > OrderStatus.arriving.index,
      ),
      _HStep(
        title: 'Arriving Soon',
        // Use a call/phone icon as shown in the mockup
        icon: Icons.phone_callback_rounded,
        isActive: currentStatus.index >= OrderStatus.arriving.index,
        isCompleted: currentStatus == OrderStatus.completed,
      ),
      _HStep(
        title: 'Delivered',
        icon: Icons.flag,
        isActive: currentStatus == OrderStatus.completed,
        isCompleted: currentStatus == OrderStatus.completed,
      ),
    ];

    if (currentStatus == OrderStatus.cancelled) {
      return const Center(
        child: Text(
          'Order Cancelled',
          style: TextStyle(color: Color(0xFF075985), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            final isCompleted = steps[stepIndex].isCompleted;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 20), // align with center of circle
                height: 2,
                color: isCompleted ? cs.primary : Colors.grey.shade300,
              ),
            );
          } else {
            // Node
            final stepIndex = index ~/ 2;
            final step = steps[stepIndex];
            return SizedBox(
              width: 70, // Fixed width for each node to align text properly
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: step.isActive ? cs.primary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: step.isActive ? cs.primary : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      step.icon,
                      color: step.isActive ? Colors.white : Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.title,
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: step.isActive ? FontWeight.bold : FontWeight.normal,
                      color: step.isActive ? cs.primary : Colors.grey.shade500,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            );
          }
        }),
      ),
    );
  }
}

class _HStep {
  final String title;
  final IconData icon;
  final bool isActive;
  final bool isCompleted;

  _HStep({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.isCompleted,
  });
}
