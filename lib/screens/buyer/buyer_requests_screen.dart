import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/order_model.dart';
import '../../models/enums/order_status.dart';
import '../../providers/buyer_provider.dart';
import '../../providers/order_tracking_provider.dart';
import 'package:go_router/go_router.dart';

class BuyerRequestsScreen extends ConsumerStatefulWidget {
  const BuyerRequestsScreen({super.key});

  @override
  ConsumerState<BuyerRequestsScreen> createState() =>
      _BuyerRequestsScreenState();
}

class _BuyerRequestsScreenState extends ConsumerState<BuyerRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentBuyerSessionProvider);
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.myRequestsTitle)),
        body: Center(child: Text(l10n.notLoggedIn)),
      );
    }
    final allAsync = ref.watch(buyerAllRequestsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.myRequestsTitle,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: cs.onPrimary,
          labelColor: cs.onPrimary,
          unselectedLabelColor: cs.onPrimary.withValues(alpha: 0.70),
          tabs: [
            Tab(text: l10n.filterActive),
            Tab(text: l10n.logsTitle),
          ],
        ),
      ),
      body: allAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.loadingError(e.toString()))),
        data: (all) {
          final active = all
              .where((r) =>
                  r.status == OrderStatus.pending ||
                  r.status == OrderStatus.confirmed ||
                  r.status == OrderStatus.readyForPickup ||
                  r.status == OrderStatus.outForDelivery)
              .toList();
          final history = all
              .where((r) =>
                  r.status == OrderStatus.cancelled ||
                  r.status == OrderStatus.completed)
              .toList();
          return TabBarView(
            controller: _tab,
            children: [
              _RequestsList(requests: active, isActive: true),
              _RequestsList(requests: history, isActive: false),
            ],
          );
        },
      ),
    );
  }
}

class _RequestsList extends ConsumerWidget {
  final List<OrderModel> requests;
  final bool isActive;
  const _RequestsList({required this.requests, required this.isActive});

  Future<void> _cancel(BuildContext context, WidgetRef ref, OrderModel order) async {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLG)),
        title: Text(l10n.cancelOrderDialogTitle),
        content: Text(l10n.cancelOrderDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.no),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
            ),
            child: Text(l10n.cancelOrderBtn),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    
    await ref.read(orderTrackingProvider).updateOrderStatus(order, OrderStatus.cancelled);
    
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.orderCancelledSnackbar),
        backgroundColor: cs.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingLG),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: cs.outline.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Icon(
                  isActive
                      ? Icons.send_rounded
                      : Icons.history_rounded,
                  size: 56,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: AppSizes.paddingMD),
              Text(
                isActive ? l10n.noActiveRequests : l10n.noOrdersYetTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withValues(alpha: 0.85),
                    ),
              ),
              const SizedBox(height: AppSizes.paddingSM),
              Text(
                isActive
                    ? l10n.noActiveRequestsSubtitle
                    : l10n.noOrdersSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.65),
                    height: 1.4),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      itemCount: requests.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSizes.paddingSM),
      itemBuilder: (context, i) =>
          _RequestTile(request: requests[i], onCancel: _cancel),
    );
  }
}

class _RequestTile extends ConsumerWidget {
  final OrderModel request;
  final Future<void> Function(BuildContext, WidgetRef, OrderModel) onCancel;
  const _RequestTile({required this.request, required this.onCancel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final (statusColor, statusLabel) = _statusVisuals(request.status, cs, l10n);
    final cancellable = request.status == OrderStatus.pending;
    
    return InkWell(
      onTap: () {
        context.push('/buyer/track-order/${request.orderId}');
      },
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                    ),
                    child: Icon(Icons.shopping_bag_rounded, color: statusColor),
                  ),
                  const SizedBox(width: AppSizes.paddingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.orderId.isNotEmpty
                              ? l10n.orderId(request.orderId.substring(0, request.orderId.length > 5 ? 5 : request.orderId.length).toUpperCase())
                              : l10n.orderNewPrefix,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${request.quantity} kg · TZS ${request.totalPrice.toStringAsFixed(0)}\n'
                          '${_relativeTime(request.createdAt)}',
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.65),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingSM, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11),
                    ),
                  ),
                ],
              ),
              if (cancellable) ...[
                const SizedBox(height: AppSizes.paddingSM),
                Divider(height: 1, color: cs.outlineVariant),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => onCancel(context, ref, request),
                    icon: Icon(Icons.cancel_outlined,
                        color: cs.primary, size: 18),
                    label: Text(
                      l10n.cancelOrderBtn,
                      style: TextStyle(color: cs.primary),
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

  (Color, String) _statusVisuals(OrderStatus s, ColorScheme cs, AppLocalizations l10n) {
    switch (s) {
      case OrderStatus.pending:
        return (cs.primary, l10n.statusPending);
      case OrderStatus.confirmed:
        return (const Color(0xFF0369A1), l10n.statusPaid);
      case OrderStatus.preparing:
        return (cs.primary, l10n.statusPreparing);
      case OrderStatus.readyForPickup:
      case OrderStatus.outForDelivery:
        return (cs.primary, l10n.statusOnTheWay);
      case OrderStatus.completed:
        return (cs.primary, l10n.statusCompleted);
      case OrderStatus.cancelled:
        return (const Color(0xFF1E3A55), l10n.statusCancelled);
      case OrderStatus.disputed:
        return (Colors.red, l10n.statusDisputed);
    }
  }

  String _relativeTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${t.day}/${t.month}';
  }
}