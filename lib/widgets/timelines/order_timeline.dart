import 'package:flutter/material.dart';
import '../../config/theme_extensions.dart';
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
    final cs = Theme.of(context).colorScheme;
    // Define the generic happy path. `pending` is the buyer's
    // initial state on create; `confirmed` is the seller's accept;
    // `inTransit` is the seller marking the order handed off;
    // `completed` is the buyer's receipt confirmation (terminal).
    // The remaining enum values (`placed`, `assigned`, `pickedUp`,
    // `delivered`, `negotiating`) are intentionally not rendered
    // here — the lifecycle no longer passes through them.
    final steps = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.inTransit,
      OrderStatus.completed,
    ];

    if (currentStatus == OrderStatus.cancelled) {
      return Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Text(
          'Order was Cancelled',
          style: TextStyle(
            color: cs.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    int currentIndex = steps.indexOf(currentStatus);
    if (currentIndex == -1) {
      // Fallback for statuses outside the happy path (e.g.
      // `negotiating` if it ever gets written). Default to the
      // first step so the timeline doesn't render empty.
      currentIndex = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        final stepStatus = steps[index];
        final isCompleted = index <= currentIndex;
        final isLast = index == steps.length - 1;
        final isCurrent = index == currentIndex;
        // The terminal `completed` step gets a distinct colour so the
        // buyer can tell at a glance that the order reached its
        // end-state — without this, the last filled dot reads the
        // same as the in-progress primary step.
        final isTerminalCompleted = isLast &&
            currentStatus == OrderStatus.completed;

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
          isTerminalCompleted: isTerminalCompleted,
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
  final bool isTerminalCompleted;

  const _TimelineNode({
    required this.title,
    this.subtitle,
    required this.isCompleted,
    required this.isLast,
    required this.isCurrent,
    this.isTerminalCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = BackgroundStyle.of(context);
    // Pending dot / line colour tracks the theme's muted surface so the
    // "not yet reached" parts of the timeline still look intentional in
    // dark mode rather than gray-on-navy.
    final pendingColor = tokens.border;
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
                  // Completed steps use the theme primary so the
                  // "done" portion of the timeline reads as brand
                  // colour; pending steps use the muted border so
                  // they stay neutral on either theme. The terminal
                  // `completed` step uses the secondary token so the
                  // buyer can see at a glance that the order is
                  // fully done — distinct from the in-progress
                  // primary colour used by earlier completed steps.
                  color: isTerminalCompleted
                      ? cs.secondary
                      : (isCompleted ? cs.primary : pendingColor),
                  border: isCurrent
                      // Active step uses tertiary so it visually pops
                      // against the primary-coloured completed steps.
                      ? Border.all(color: cs.tertiary, width: 3)
                      : null,
                ),
                child: isCompleted
                    ? Icon(Icons.check, size: 14, color: cs.onPrimary)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color:
                        isCompleted ? cs.primary : pendingColor,
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
                              ? cs.onSurface
                              : cs.onSurface.withValues(alpha: 0.55),
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.w500,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.60),
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
