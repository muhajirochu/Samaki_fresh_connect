// Admin — Reports.
//
// Tabbed layout with five sections:
//   1. Sales       — today / week / month totals + per-day bars
//   2. Orders      — total + by-status breakdown
//   3. Sellers     — top sellers by `totalSales`
//   4. Buyers      — top buyers by order count
//   5. Revenue     — platform revenue summary
//
// Charts are intentionally hand-rolled (no `fl_chart` dep) to keep
// the admin module dependency-free.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/order_model.dart';
import '../../providers/admin_provider.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).reportsTab),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Sales'),
              Tab(text: 'Orders'),
              Tab(text: 'Sellers'),
              Tab(text: 'Buyers'),
              Tab(text: 'Revenue'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OverviewTab(),
            _SalesTab(),
            _OrdersTab(),
            _SellersTab(),
            _BuyersTab(),
            _RevenueTab(),
          ],
        ),
      ),
    );
  }
}

String _formatRevenue(double v) {
  if (v == 0) return 'TZS 0';
  if (v >= 1000000) return 'TZS ${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return 'TZS ${(v / 1000).toStringAsFixed(1)}K';
  return 'TZS ${v.toStringAsFixed(0)}';
}

// ── Sales tab ──────────────────────────────────────────────────────

class _SalesTab extends ConsumerWidget {
  const _SalesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final daily = ref.watch(adminDailyOrdersProvider).valueOrNull ?? [];
    final weekly = ref.watch(adminWeeklyOrdersProvider).valueOrNull ?? [];
    final monthly = ref.watch(adminMonthlyOrdersProvider).valueOrNull ?? [];

    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingLG),
      children: [
        _MetricRow(
          title: 'Today',
          count: daily.length,
          revenue: _sumRevenue(daily),
        ),
        const SizedBox(height: AppSizes.paddingMD),
        _MetricRow(
          title: l10n.thisWeek,
          count: weekly.length,
          revenue: _sumRevenue(weekly),
        ),
        const SizedBox(height: AppSizes.paddingMD),
        _MetricRow(
          title: l10n.thisMonth,
          count: monthly.length,
          revenue: _sumRevenue(monthly),
        ),
        const SizedBox(height: AppSizes.paddingXL),
        Text(l10n.reportsSales,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
        const SizedBox(height: AppSizes.paddingMD),
        _WeeklyBars(orders: weekly),
      ],
    );
  }

  double _sumRevenue(List<OrderModel> orders) {
    return orders
        .where((o) => o.orderStatus == 'delivered')
        .fold<double>(0, (acc, o) => acc + (o.finalPrice * o.quantityKg));
  }
}

class _MetricRow extends StatelessWidget {
  final String title;
  final int count;
  final double revenue;

  const _MetricRow({
    required this.title,
    required this.count,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                Text('$count orders',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65),
                        )),
              ],
            ),
          ),
          Text(_formatRevenue(revenue),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w800,
                  )),
        ],
      ),
    );
  }
}

/// Hand-rolled 7-bar chart for the current week. Each bar's
/// height is proportional to that day's delivered revenue.
class _WeeklyBars extends StatelessWidget {
  final List<OrderModel> orders;
  const _WeeklyBars({required this.orders});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      return d;
    });

    final dailyRevenue = days.map((d) {
      final next = d.add(const Duration(days: 1));
      final total = orders
          .where((o) =>
              o.orderStatus == 'delivered' &&
              o.createdAt.isAfter(d) &&
              o.createdAt.isBefore(next))
          .fold<double>(0, (acc, o) => acc + (o.finalPrice * o.quantityKg));
      return total;
    }).toList();

    final maxValue = dailyRevenue.fold<double>(0, (acc, v) => v > acc ? v : acc);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
      ),
      child: SizedBox(
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final value = dailyRevenue[i];
            final pct = maxValue == 0 ? 0.0 : value / maxValue;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 100 * pct + 4,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Orders tab ─────────────────────────────────────────────────────

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final all = ref.watch(adminAllOrdersProvider).valueOrNull ?? [];
    if (all.isEmpty) {
      return Center(child: Text(l10n.noTransactions));
    }
    final byStatus = <String, int>{};
    for (final o in all) {
      byStatus[o.orderStatus] = (byStatus[o.orderStatus] ?? 0) + 1;
    }
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingLG),
      children: [
        _MetricRow(title: 'Total', count: all.length, revenue: 0),
        const SizedBox(height: AppSizes.paddingMD),
        ...byStatus.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MetricRow(title: e.key, count: e.value, revenue: 0),
          ),
        ),
      ],
    );
  }
}

// ── Sellers tab ────────────────────────────────────────────────────

class _SellersTab extends ConsumerWidget {
  const _SellersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sellers = ref.watch(adminAllSellersProvider).valueOrNull ?? [];
    if (sellers.isEmpty) {
      return Center(child: Text(l10n.noStreetSellers));
    }
    final top = [...sellers]..sort((a, b) => b.totalSales.compareTo(a.totalSales));
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingLG),
      itemCount: top.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSizes.paddingSM),
      itemBuilder: (_, i) {
        final s = top[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.15),
            child: Text('#${i + 1}',
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w800,
                )),
          ),
          title: Text(s.fullName),
          subtitle: Text(s.email),
          trailing: Text(_formatRevenue(s.totalSales),
              style: const TextStyle(
                color: AppColors.accentGreen,
                fontWeight: FontWeight.w800,
              )),
        );
      },
    );
  }
}

// ── Buyers tab ─────────────────────────────────────────────────────

class _BuyersTab extends ConsumerWidget {
  const _BuyersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buyers = ref.watch(adminAllBuyersProvider).valueOrNull ?? [];
    final orders = ref.watch(adminAllOrdersProvider).valueOrNull ?? [];

    if (buyers.isEmpty) {
      return const Center(child: Text('No buyers yet'));
    }
    final byBuyer = <String, int>{};
    for (final o in orders) {
      byBuyer[o.buyerId] = (byBuyer[o.buyerId] ?? 0) + 1;
    }
    final top = [...buyers]..sort((a, b) {
      final ca = byBuyer[a.userId] ?? 0;
      final cb = byBuyer[b.userId] ?? 0;
      return cb.compareTo(ca);
    });

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingLG),
      itemCount: top.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSizes.paddingSM),
      itemBuilder: (_, i) {
        final b = top[i];
        final count = byBuyer[b.userId] ?? 0;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.accentGreen.withValues(alpha: 0.15),
            child: Text('#${i + 1}',
                style: const TextStyle(
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.w800,
                )),
          ),
          title: Text(b.fullName),
          subtitle: Text(b.email),
          trailing: Text('$count orders',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        );
      },
    );
  }
}

// ── Revenue tab ────────────────────────────────────────────────────

class _RevenueTab extends ConsumerWidget {
  const _RevenueTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final revenue = ref.watch(adminPlatformRevenueProvider).valueOrNull ?? 0;
    final daily = ref.watch(adminDailyRevenueProvider).valueOrNull ?? 0;
    final weekly = ref.watch(adminWeeklyRevenueProvider).valueOrNull ?? 0;
    final monthly = ref.watch(adminMonthlyRevenueProvider).valueOrNull ?? 0;
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingLG),
      children: [
        _MetricRow(title: l10n.platformRevenue, count: 0, revenue: revenue),
        const SizedBox(height: AppSizes.paddingMD),
        _MetricRow(title: 'Today', count: 0, revenue: daily),
        const SizedBox(height: AppSizes.paddingMD),
        _MetricRow(title: l10n.thisWeek, count: 0, revenue: weekly),
        const SizedBox(height: AppSizes.paddingMD),
        _MetricRow(title: l10n.thisMonth, count: 0, revenue: monthly),
      ],
    );
  }
}

// ── Overview Tab (Moved from Dashboard) ────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingLG),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppSizes.paddingMD,
          crossAxisSpacing: AppSizes.paddingMD,
          childAspectRatio: 1.5,
          children: [
            _TotalOrdersCard(),
            _PendingOrdersCard(),
            _CompletedOrdersCard(),
            _CancelledOrdersCard(),
          ],
        ),
        const SizedBox(height: AppSizes.paddingLG),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppSizes.paddingMD,
          crossAxisSpacing: AppSizes.paddingMD,
          childAspectRatio: 1.6,
          children: [
            _DailySalesCard(),
            _WeeklySalesCard(),
            _MonthlySalesCard(),
            _PlatformRevenueCard(),
          ],
        ),
      ],
    );
  }
}

class _TotalOrdersCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final count = ref.watch(adminTotalOrdersProvider).valueOrNull ?? 0;
    return _StatCard(
      title: l10n.totalOrders,
      value: count.toString(),
      icon: Icons.receipt_long_rounded,
      color: AppColors.primaryBlue,
    );
  }
}

class _PendingOrdersCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final count = ref.watch(adminPendingOrdersProvider).valueOrNull ?? 0;
    return _StatCard(
      title: l10n.pendingOrders,
      value: count.toString(),
      icon: Icons.hourglass_top_rounded,
      color: AppColors.accentOrange,
    );
  }
}

class _CompletedOrdersCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final count = ref.watch(adminCompletedOrdersProvider).valueOrNull ?? 0;
    return _StatCard(
      title: l10n.completedOrders,
      value: count.toString(),
      icon: Icons.check_circle_rounded,
      color: AppColors.accentGreen,
    );
  }
}

class _CancelledOrdersCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final count = ref.watch(adminCancelledOrdersProvider).valueOrNull ?? 0;
    return _StatCard(
      title: l10n.cancelledOrders,
      value: count.toString(),
      icon: Icons.cancel_rounded,
      color: AppColors.errorRed,
    );
  }
}

class _DailySalesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final orders = ref.watch(adminDailyOrdersProvider).valueOrNull ?? [];
    final revenue = orders
        .where((o) => o.orderStatus == 'delivered')
        .fold<double>(0, (acc, o) => acc + (o.finalPrice * o.quantityKg));
    return _StatCard(
      title: l10n.dailySales,
      value: 'TZS ${(revenue / 1000).toStringAsFixed(0)}K',
      icon: Icons.today_rounded,
      color: AppColors.successGreen,
    );
  }
}

class _WeeklySalesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final orders = ref.watch(adminWeeklyOrdersProvider).valueOrNull ?? [];
    final revenue = orders
        .where((o) => o.orderStatus == 'delivered')
        .fold<double>(0, (acc, o) => acc + (o.finalPrice * o.quantityKg));
    return _StatCard(
      title: l10n.weeklySales,
      value: 'TZS ${(revenue / 1000).toStringAsFixed(0)}K',
      icon: Icons.date_range_rounded,
      color: AppColors.primaryBlue,
    );
  }
}

class _MonthlySalesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final orders = ref.watch(adminMonthlyOrdersProvider).valueOrNull ?? [];
    final revenue = orders
        .where((o) => o.orderStatus == 'delivered')
        .fold<double>(0, (acc, o) => acc + (o.finalPrice * o.quantityKg));
    return _StatCard(
      title: l10n.monthlySales,
      value: 'TZS ${(revenue / 1000).toStringAsFixed(0)}K',
      icon: Icons.calendar_month_rounded,
      color: AppColors.accentOrange,
    );
  }
}

class _PlatformRevenueCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final revenue = ref.watch(adminPlatformRevenueProvider).valueOrNull ?? 0;
    return _StatCard(
      title: l10n.platformRevenue,
      value: 'TZS ${(revenue / 1000).toStringAsFixed(0)}K',
      icon: Icons.account_balance_rounded,
      color: AppColors.accentGreen,
    );
  }
}

// ── Stat card (shared) ────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
