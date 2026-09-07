import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/order_model.dart';
import '../../models/enums/order_status.dart';
import '../../models/enums/payment_status.dart';
import '../../models/enums/payout_status.dart';
import '../../providers/admin_provider.dart';
import '../../services/payout_service.dart';

class AdminTransactionsScreen extends ConsumerStatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  ConsumerState<AdminTransactionsScreen> createState() => _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends ConsumerState<AdminTransactionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final ordersAsync = ref.watch(adminAllOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactionsTitle),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          indicatorColor: cs.primary,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: [
            Tab(text: l10n.adminTabAll),
            Tab(text: l10n.adminTabHeld),
            Tab(text: l10n.adminTabReleased),
            Tab(text: l10n.adminTabPending),
            Tab(text: l10n.adminTabDisputed),
          ],
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.loadingError(e.toString()))),
        data: (orders) {
          return Column(
            children: [
              _RevenueSummaryCard(),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _OrderList(orders: orders),
                    _OrderList(
                      orders: orders.where((o) =>
                        o.paymentStatus == PaymentStatus.held ||
                        o.payoutStatus == PayoutStatus.held
                      ).toList(),
                      emptyLabel: l10n.adminNoHeldPayments,
                    ),
                    _OrderList(
                      orders: orders.where((o) =>
                        o.paymentStatus == PaymentStatus.released ||
                        o.buyerConfirmed
                      ).toList(),
                      emptyLabel: l10n.adminNoReleasedPayouts,
                    ),
                    _OrderList(
                      orders: orders.where((o) =>
                        o.paymentStatus == PaymentStatus.pending &&
                        o.status != OrderStatus.cancelled
                      ).toList(),
                      emptyLabel: l10n.adminNoPendingPayments,
                    ),
                    _OrderList(
                      orders: orders.where((o) =>
                        o.isDisputed ||
                        o.status == OrderStatus.disputed ||
                        o.payoutStatus == PayoutStatus.disputed
                      ).toList(),
                      emptyLabel: l10n.adminNoActiveDisputes,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RevenueSummaryCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final revenueAsync = ref.watch(adminPlatformRevenueProvider);
    final revenue = revenueAsync.valueOrNull ?? 0.0;
    final ordersAsync = ref.watch(adminAllOrdersProvider);
    final orders = ordersAsync.valueOrNull ?? [];
    final totalOrders = orders.length;
    final heldCount = orders.where((o) => o.paymentStatus == PaymentStatus.held).length;
    final releasedCount = orders.where((o) => o.buyerConfirmed).length;
    final disputeCount = orders.where((o) => o.isDisputed || o.status == OrderStatus.disputed).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(AppSizes.paddingLG, AppSizes.paddingMD, AppSizes.paddingLG, 0),
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: 0.85)],
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.onPrimary.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.account_balance_rounded, color: cs.onPrimary, size: 26),
              ),
              const SizedBox(width: AppSizes.paddingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.platformRevenue,
                      style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatAmount(revenue),
                      style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.4),
                    ),
                  ],
                ),
              ),
              Text(
                l10n.ordersCount(totalOrders),
                style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.85), fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statChip(l10n.adminTabHeld, heldCount.toString(), const Color(0xFFFDE68A), const Color(0xFF92400E))),
              const SizedBox(width: 6),
              Expanded(child: _statChip(l10n.adminTabReleased, releasedCount.toString(), const Color(0xFFBBF7D0), const Color(0xFF14532D))),
              const SizedBox(width: 6),
              Expanded(child: _statChip(l10n.adminTabDisputed, disputeCount.toString(), const Color(0xFFFECACA), const Color(0xFF991B1B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount == 0) return 'TZS 0';
    if (amount >= 1000) {
      final k = amount / 1000;
      return 'TZS ${k.toStringAsFixed(k >= 100 ? 0 : 1)}K';
    }
    return 'TZS ${amount.toStringAsFixed(0)}';
  }
}

class _OrderList extends StatelessWidget {
  final List<OrderModel> orders;
  final String? emptyLabel;

  const _OrderList({required this.orders, this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payments_outlined, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
              const SizedBox(height: AppSizes.paddingMD),
              Text(emptyLabel ?? AppLocalizations.of(context).adminNoTransactions, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.paddingLG),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSizes.paddingSM),
        itemBuilder: (_, i) => _OrderRow(orders[i], key: ValueKey(orders[i].orderId)),
      ),
    );
  }
}

class _OrderRow extends ConsumerWidget {
  final OrderModel order;
  const _OrderRow(this.order, {super.key});

  Color _statusColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (order.status) {
      case OrderStatus.completed: return Colors.green;
      case OrderStatus.cancelled: return cs.error;
      case OrderStatus.outForDelivery: return cs.primary;
      case OrderStatus.readyForPickup: return cs.primary;
      case OrderStatus.confirmed: return const Color(0xFF0369A1);
      case OrderStatus.preparing: return const Color(0xFFD97706);
      case OrderStatus.disputed: return const Color(0xFFD97706);
      default: return cs.outline;
    }
  }

  Color _payoutColor() {
    switch (order.payoutStatus) {
      case PayoutStatus.paid: return Colors.green;
      case PayoutStatus.held: return const Color(0xFFD97706);
      case PayoutStatus.disputed:
      case PayoutStatus.failed: return Colors.red;
      case PayoutStatus.refunded: return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (order.status) {
      case OrderStatus.pending: return l10n.adminStatusPending;
      case OrderStatus.confirmed: return l10n.adminStatusConfirmed;
      case OrderStatus.preparing: return l10n.adminStatusPreparing;
      case OrderStatus.readyForPickup: return l10n.adminStatusReady;
      case OrderStatus.outForDelivery: return l10n.adminStatusOnTheWay;
      case OrderStatus.completed: return l10n.adminStatusCompleted;
      case OrderStatus.cancelled: return l10n.adminStatusCancelled;
      case OrderStatus.disputed: return l10n.adminStatusDisputed;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final statusColor = _statusColor(context);
    final payoutColor = _payoutColor();
    final isDisputeActive = order.isDisputed || order.status == OrderStatus.disputed;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(
          color: isDisputeActive ? const Color(0xFFD97706) : cs.outline.withValues(alpha: 0.25),
          width: isDisputeActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(color: cs.shadow.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
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
                child: Icon(
                  isDisputeActive ? Icons.report_problem_rounded : Icons.receipt_long_rounded,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSizes.paddingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TZS ${order.totalPrice.toStringAsFixed(0)}',
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${order.quantity} kg',
                      style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              Text(
                '#${order.orderId.substring(0, order.orderId.length.clamp(0, 6)).toUpperCase()}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.5),
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip(_statusLabel(l10n), statusColor),
              _chip(
                order.paymentStatus == PaymentStatus.refunded
                    ? l10n.adminRefundedBadge
                    : order.isPaid
                        ? l10n.adminPaidBadge
                        : l10n.adminCashBadge,
                order.paymentStatus == PaymentStatus.refunded
                    ? Colors.blue
                    : order.isPaid
                        ? const Color(0xFF0369A1)
                        : Colors.grey,
              ),
              _chip(
                l10n.adminPayoutBadge(order.payoutStatus.name.toUpperCase()),
                payoutColor,
              ),
              if (order.buyerConfirmed)
                _chip(l10n.adminBuyerConfirmedBadge, Colors.green)
              else if (isDisputeActive)
                _chip(l10n.adminDisputeReportedBadge, const Color(0xFFD97706))
              else if (order.isPaid && order.status == OrderStatus.completed)
                _chip(l10n.adminAwaitingConfirmationBadge, const Color(0xFFD97706)),
            ],
          ),

          if (order.paymentReference.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Ref: ${order.paymentReference}',
              style: tt.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],

          // Dispute review box & Admin action buttons
          if (isDisputeActive) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        l10n.adminBuyerDisputeReview,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF92400E), fontSize: 13),
                      ),
                    ],
                  ),
                  if (order.buyerComment.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      l10n.adminComplaint(order.buyerComment),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF78350F), fontStyle: FontStyle.italic),
                    ),
                  ],
                  if (order.buyerFeedbackImageUrl.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        order.buyerFeedbackImageUrl,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Admin Refund button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleAdminRefund(context, ref, order),
                          icon: const Icon(Icons.assignment_return_rounded, size: 16),
                          label: Text(l10n.adminRefundBuyerBtn, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Admin Approve Payout button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleAdminApprovePayout(context, ref, order),
                          icon: const Icon(Icons.check_circle_rounded, size: 16),
                          label: Text(l10n.adminApprovePayoutBtn, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF15803D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          if (order.status == OrderStatus.completed && order.commissionAmount > 0) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _breakdownRow(
              context,
              l10n.adminOrderTotal,
              'TZS ${order.totalPrice.toStringAsFixed(0)}',
              cs.onSurface,
            ),
            const SizedBox(height: 4),
            _breakdownRow(
              context,
              l10n.adminPlatformCommission,
              'TZS ${order.commissionAmount.toStringAsFixed(0)}',
              cs.primary,
            ),
            const SizedBox(height: 4),
            _breakdownRow(
              context,
              l10n.adminSellerEarnings,
              'TZS ${order.sellerEarnings.toStringAsFixed(0)}',
              Colors.green,
            ),
          ],

          if (order.updatedAt.year > 2000) ...[
            const SizedBox(height: 8),
            Text(
              _formatDate(order.updatedAt),
              style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAdminRefund(BuildContext context, WidgetRef ref, OrderModel order) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.assignment_return_rounded, color: Color(0xFF0284C7)),
            const SizedBox(width: 8),
            Text(l10n.adminApproveRefundTitle),
          ],
        ),
        content: Text(
          l10n.adminApproveRefundMsg(order.totalPrice.toStringAsFixed(0), order.orderId.substring(0, 6)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.adminCancelBtn)),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
            child: Text(l10n.adminConfirmRefundBtn),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final payoutSvc = ref.read(payoutServiceProvider);
    await payoutSvc.issueRefund(order.orderId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.adminRefundApprovedMsg(order.totalPrice.toStringAsFixed(0), order.orderId.substring(0, 6))),
          backgroundColor: const Color(0xFF0284C7),
        ),
      );
    }
  }

  Future<void> _handleAdminApprovePayout(BuildContext context, WidgetRef ref, OrderModel order) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF15803D)),
            const SizedBox(width: 8),
            Text(l10n.adminApprovePayoutTitle),
          ],
        ),
        content: Text(
          l10n.adminApprovePayoutMsg((order.totalPrice * 0.95).toStringAsFixed(0)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.adminCancelBtn)),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D), foregroundColor: Colors.white),
            child: Text(l10n.adminApprovePayoutConfirmBtn),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final payoutSvc = ref.read(payoutServiceProvider);
    await payoutSvc.confirmReceived(
      orderId: order.orderId,
      totalAmount: order.totalPrice,
      paymentMethod: order.paymentMethod,
      paymentReference: order.paymentReference,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.adminPayoutReleasedMsg(order.orderId.substring(0, 6))),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
    }
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.3),
      ),
    );
  }

  Widget _breakdownRow(BuildContext context, String label, String value, Color valueColor) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: tt.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} — ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }
}
