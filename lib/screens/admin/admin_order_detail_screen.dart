// Admin — Order Detail with Dispute Resolution.
//
// Mirrors the buyer / seller order detail but adds an Admin
// Actions card at the bottom: dispute resolution, force-cancel,
// force-complete, and direct links to the buyer / seller profile
// views.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/order_model.dart';
import '../../providers/admin_provider.dart';

class AdminOrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ordersAsync = ref.watch(adminAllOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.viewOrderDetail)),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(l10n.loadingError(e.toString()))),
        data: (orders) {
          OrderModel? order;
          for (final o in orders) {
            if (o.orderId == orderId) {
              order = o;
              break;
            }
          }
          if (order == null) {
            return Center(child: Text(l10n.loadingError('not found')));
          }
          return _OrderDetailBody(order: order);
        },
      ),
    );
  }
}

class _OrderDetailBody extends ConsumerWidget {
  final OrderModel order;
  const _OrderDetailBody({required this.order});

  Color _statusColor(BuildContext context) {
    switch (order.orderStatus) {
      case 'delivered':
        return AppColors.accentGreen;
      case 'cancelled':
        return AppColors.errorRed;
      case 'pending':
        return AppColors.accentOrange;
      case 'inTransit':
        return AppColors.infoBlue;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  Future<void> _resolveDispute(
    BuildContext context,
    WidgetRef ref, {
    required String action,
    required String statusValue,
  }) async {
    final l10n = AppLocalizations.of(context);
    final noteCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.disputeResolution),
        content: TextField(
          controller: noteCtl,
          decoration: InputDecoration(
            labelText: l10n.disputeNote,
            hintText: l10n.disputeNoteHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final orderService = ref.read(adminOrderServiceProvider);
    final logService = ref.read(adminActivityLogServiceProvider);
    final adminUid = ref.read(adminCurrentUidProvider) ?? '';
    try {
      await orderService.disputeResolution(
        orderId: order.orderId,
        action: action,
        resolvedByUid: adminUid,
        note: noteCtl.text.trim(),
      );
      ref.invalidate(adminAllOrdersProvider);
      await logService.write(
        type: 'disputeResolution',
        actorUid: adminUid,
        actorRole: 'admin',
        targetType: 'order',
        targetId: order.orderId,
        title: l10n.disputeResolution,
        subtitle: 'Order ${order.orderId} → $statusValue',
        metadata: <String, dynamic>{'note': noteCtl.text.trim()},
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final statusColor = _statusColor(context);
    final total = order.finalPrice * order.quantityKg;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingLG),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                border: Border.all(color: statusColor.withValues(alpha: 0.30)),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_rounded,
                      color: statusColor, size: 32),
                  const SizedBox(width: AppSizes.paddingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('#${order.orderId.substring(0, order.orderId.length.clamp(0, 8))}',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.65),
                              fontFamily: 'monospace',
                            )),
                        Text('TZS ${total.toStringAsFixed(0)}',
                            style: tt.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            )),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      order.orderStatus.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.paddingLG),

            // Items
            _Section(title: l10n.orderItems, children: [
              _Row(label: l10n.quantityKg, value: '${order.quantityKg.toStringAsFixed(1)} kg'),
              _Row(label: l10n.pricePerKg(order.finalPrice.toStringAsFixed(0)), value: ''),
              _Row(label: l10n.buyerName, value: order.buyerId),
              if (order.streetSellerId != null)
                _Row(label: l10n.sellerName, value: order.streetSellerId!),
            ]),

            const SizedBox(height: AppSizes.paddingLG),

            // Admin actions card
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                border: Border.all(
                  color: AppColors.errorRed.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.adminActionsSection,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.errorRed,
                      )),
                  const SizedBox(height: AppSizes.paddingSM),
                  if (order.orderStatus != 'cancelled')
                    _ActionButton(
                      label: 'Force cancel',
                      icon: Icons.cancel_rounded,
                      color: AppColors.errorRed,
                      onPressed: () => _resolveDispute(
                        context,
                        ref,
                        action: 'cancelled',
                        statusValue: 'CANCELLED',
                      ),
                    ),
                  if (order.orderStatus != 'completed')
                    _ActionButton(
                      label: 'Force complete',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.accentGreen,
                      onPressed: () => _resolveDispute(
                        context,
                        ref,
                        action: 'completed',
                        statusValue: 'COMPLETED',
                      ),
                    ),
                  if (order.orderStatus != 'inTransit')
                    _ActionButton(
                      label: 'Mark in transit',
                      icon: Icons.local_shipping_rounded,
                      color: AppColors.infoBlue,
                      onPressed: () => _resolveDispute(
                        context,
                        ref,
                        action: 'inTransit',
                        statusValue: 'IN_TRANSIT',
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingLG),

            // Buyer / seller profile links
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person_rounded),
                  label: Text(l10n.buyerName),
                  onPressed: () => context.push(
                      '/admin/users/${order.buyerId}'),
                ),
              ),
              const SizedBox(width: AppSizes.paddingSM),
              if (order.streetSellerId != null)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.storefront_rounded),
                    label: Text(l10n.sellerName),
                    onPressed: () => context.push(
                        '/admin/users/${order.streetSellerId!}'),
                  ),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: tt.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSizes.paddingSM),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(
          flex: 2,
          child: Text(label,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.60),
              )),
        ),
        Expanded(
          flex: 3,
          child: Text(value,
              style: tt.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          ),
        ),
        icon: Icon(icon),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
