// Admin — Transactions.
//
// Lists every order placed on the platform with buyer / seller,
// fish type (via the listing lookup), quantity, total price and
// status. The list is reactive via Firestore snapshots so new
// orders appear instantly.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/order_model.dart';
import '../../providers/admin_provider.dart';

class AdminTransactionsScreen extends ConsumerWidget {
  const AdminTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ordersAsync = ref.watch(adminAllOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactionsTitle)),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(l10n.loadingError(e.toString()))),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingXL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payments_outlined,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5)),
                    const SizedBox(height: AppSizes.paddingMD),
                    Text(
                      l10n.noTransactions,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSizes.paddingSM),
                    Text(
                      l10n.noTransactionsSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminAllOrdersProvider);
              ref.invalidate(adminPlatformRevenueProvider);
              await Future<void>.delayed(
                const Duration(milliseconds: 300),
              );
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSizes.paddingLG),
              itemCount: orders.length + 1,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSizes.paddingSM),
              itemBuilder: (_, i) {
                if (i == 0) return _RevenueSummaryCard();
                final order = orders[i - 1];
                return _OrderRow(order, key: ValueKey(order.orderId));
              },
            ),
          );
        },
      ),
    );
  }
}

class _RevenueSummaryCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final revenueAsync = ref.watch(adminPlatformRevenueProvider);
    final revenue = revenueAsync.valueOrNull ?? 0.0;
    final ordersAsync = ref.watch(adminAllOrdersProvider);
    final totalOrders = ordersAsync.valueOrNull?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary,
            cs.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // Translucent white wash — sits ON TOP of the primary
              // gradient, so we read the foreground through onPrimary.
              color: cs.onPrimary.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_rounded,
              color: cs.onPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSizes.paddingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.platformRevenue,
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRevenue(revenue),
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.ordersCount(totalOrders),
                style: TextStyle(
                  color: cs.onPrimary.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRevenue(double amount) {
    if (amount == 0) return 'TZS 0';
    if (amount >= 1000) {
      final k = amount / 1000;
      return 'TZS ${k.toStringAsFixed(k >= 100 ? 0 : 1)}K';
    }
    return 'TZS ${amount.toStringAsFixed(0)}';
  }
}

class _OrderRow extends StatelessWidget {
  final OrderModel order;
  const _OrderRow(this.order, {super.key});

  Color _statusColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (order.orderStatus) {
      case 'delivered':
        return cs.secondary;
      case 'cancelled':
        return cs.error;
      case 'pending':
        return cs.tertiary;
      case 'inTransit':
        return cs.primary;
      default:
        return cs.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final statusColor = _statusColor(context);
    final total = order.finalPrice * order.quantityKg;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusMD),
            ),
            child: Icon(Icons.receipt_long_rounded, color: statusColor),
          ),
          const SizedBox(width: AppSizes.paddingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TZS ${total.toStringAsFixed(0)}',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${order.quantityKg.toStringAsFixed(1)} kg · ${order.orderStatus}',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.orderStatus.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '#${order.orderId.substring(0, order.orderId.length.clamp(0, 6))}',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
