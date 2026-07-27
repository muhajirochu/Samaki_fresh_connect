// Admin — Dashboard (v2 — 11 stats + recent activity).
//
// Layout (top → bottom):
//   1. Brand-gradient greeting header (admin-aware)
//   2. 4 stat cards: Total Sellers / Total Buyers / Total Listings
//      / Active Listings
//   3. 4 stat cards: Total Orders / Pending / Completed / Cancelled
//   4. 3 revenue / sales cards: Platform Revenue / Today's Orders
//      / This Week
//   5. Recent activity strip (5 most-recent audit log entries)
//   6. 6 quick-action tiles (User Mgmt, Categories, Orders,
//      Reports, Logs, Settings)
//
// Reads from Riverpod providers so every tile updates live as
// Firestore data changes.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/theme_extensions.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/common/premium_components.dart';
import '../../widgets/common/top_app_bar.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final userAsync = ref.watch(currentUserStreamProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const _AdminDashboardAppBar(),
      body: userAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text(l10n.loadingError(e.toString()))),
        data: (user) {
          if (user == null) {
            return Center(child: Text(l10n.notLoggedIn));
          }
          return CustomScrollView(
            slivers: [
              // Row 1 — People & Listings
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingLG,
                  AppSizes.paddingMD,
                  AppSizes.paddingLG,
                  0,
                ),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSizes.paddingMD,
                  crossAxisSpacing: AppSizes.paddingMD,
                  childAspectRatio: 1.5,
                  children: [
                    _TotalSellersCard(),
                    _TotalBuyersCard(),
                    _TotalListingsCard(),
                    _ActiveListingsCard(),
                  ],
                ),
              ),

              // Quick actions — Management (shown first)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingLG,
                    AppSizes.paddingXL,
                    AppSizes.paddingLG,
                    AppSizes.paddingSM,
                  ),
                  child: SectionHeader(
                    title: l10n.management,
                    leadingIcon: Icons.build_rounded,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingLG),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ActionTile(
                      icon: Icons.shopping_cart_rounded,
                      title: l10n.manageBuyers,
                      subtitle: l10n.manageBuyersSubtitle,
                      onTap: () => context.push('/admin/buyers'),
                      color: cs.secondary,
                    ),
                    const SizedBox(height: AppSizes.paddingMD),
                    _ActionTile(
                      icon: Icons.storefront_rounded,
                      title: l10n.manageStreetSellers,
                      subtitle: l10n.manageStreetSellersSubtitle,
                      onTap: () => context.push('/admin/sellers'),
                      color: cs.primary,
                      trailing: _PendingBadge(),
                    ),
                    const SizedBox(height: AppSizes.paddingMD),
                    _ActionTile(
                      icon: Icons.list_alt_rounded,
                      title: l10n.allListings,
                      subtitle: l10n.adminAllListingsSubtitle,
                      onTap: () => context.push('/admin/listings'),
                      color: cs.tertiary,
                    ),
                    const SizedBox(height: AppSizes.paddingMD),
                    _ActionTile(
                      icon: Icons.receipt_long_rounded,
                      title: l10n.transactionsTitle,
                      subtitle: l10n.transactionsScreenSubtitle,
                      onTap: () => context.push('/admin/transactions'),
                      color: cs.secondary,
                    ),
                    const SizedBox(height: AppSizes.paddingMD),
                    _ActionTile(
                      icon: Icons.bar_chart_rounded,
                      title: l10n.reportsTab,
                      subtitle: l10n.reportsSales,
                      onTap: () => context.push('/admin/reports'),
                      color: cs.primary,
                    ),
                    const SizedBox(height: AppSizes.paddingMD),
                    _ActionTile(
                      icon: Icons.history_rounded,
                      title: l10n.logsTitle,
                      subtitle: l10n.logsSubtitle,
                      onTap: () => context.push('/admin/logs'),
                      color: cs.tertiary,
                    ),
                    const SizedBox(height: AppSizes.paddingMD),
                  ]),
                ),
              ),
              // Recent activity — shown last
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingLG,
                    AppSizes.paddingSM,
                    AppSizes.paddingLG,
                    AppSizes.paddingSM,
                  ),
                  child: SectionHeader(
                    title: l10n.recentActivity,
                    leadingIcon: Icons.history_rounded,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingLG,
                    0,
                    AppSizes.paddingLG,
                    AppSizes.paddingXXL,
                  ),
                  child: _RecentActivityStrip(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Admin Dashboard AppBar ────────────────────────────────────────

class _AdminDashboardAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _AdminDashboardAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(164);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserStreamProvider).valueOrNull;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const TopAppBar(),
        if (user != null)
          _AdminGreetingHeader(
            greeting: l10n.hello(user.fullName.split(' ').first),
            subtitle: l10n.adminDashboardSubtitle,
          ),
      ],
    );
  }
}

// ── Greeting header ───────────────────────────────────────────────

class _AdminGreetingHeader extends StatelessWidget {
  final String greeting;
  final String subtitle;
  const _AdminGreetingHeader(
      {required this.greeting, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.of(context).brand,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppSizes.radiusXL),
          bottomRight: Radius.circular(AppSizes.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.onPrimary.withValues(alpha: 0.18),
                    cs.onPrimary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingLG,
              AppSizes.paddingMD,
              AppSizes.paddingLG,
              AppSizes.paddingLG,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.admin_panel_settings_rounded,
                        color: cs.onPrimary, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        greeting,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(
                    color: cs.onPrimary.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat cards (live) ────────────────────────────────────────────

class _TotalSellersCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final count = ref.watch(adminTotalSellersProvider).valueOrNull ?? 0;
    return _StatCard(
      title: l10n.totalSellers,
      value: count.toString(),
      icon: Icons.storefront_rounded,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}

class _TotalBuyersCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final count = ref.watch(adminTotalBuyersProvider).valueOrNull ?? 0;
    return _StatCard(
      title: l10n.totalBuyers,
      value: count.toString(),
      icon: Icons.shopping_bag_rounded,
      color: Theme.of(context).colorScheme.secondary,
    );
  }
}

class _TotalListingsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final count = ref.watch(adminTotalListingsProvider).valueOrNull ?? 0;
    return _StatCard(
      title: l10n.totalListings,
      value: count.toString(),
      icon: Icons.inventory_2_rounded,
      color: Theme.of(context).colorScheme.tertiary,
    );
  }
}

class _ActiveListingsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final count = ref.watch(adminActiveListingsCountProvider).valueOrNull ?? 0;
    return _StatCard(
      title: l10n.activeListings,
      value: count.toString(),
      icon: Icons.check_circle_rounded,
      color: Theme.of(context).colorScheme.primary,
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

// ── Recent activity strip ─────────────────────────────────────────

class _RecentActivityStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final logsAsync = ref.watch(adminRecentActivityProvider);
    return logsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSizes.paddingMD),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Text(l10n.loadingError(e.toString())),
      data: (logs) {
        final recent = logs.take(5).toList();
        if (recent.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSizes.paddingLG),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusLG),
              border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
            ),
            child: Text(l10n.noLogsYet),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLG),
            border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: List.generate(recent.length, (i) {
              final log = recent[i];
              return Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: Icon(_iconForType(log.type),
                        color: _colorForType(log.type, cs)),
                    title: Text(log.title,
                        style: tt.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: log.subtitle != null
                        ? Text(log.subtitle!,
                            style: tt.bodySmall?.copyWith(
                              color:
                                  cs.onSurface.withValues(alpha: 0.65),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)
                        : null,
                  ),
                  if (i != recent.length - 1)
                    Divider(
                      height: 1,
                      color: cs.outline.withValues(alpha: 0.25),
                    ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'login':
        return Icons.login_rounded;
      case 'registration':
        return Icons.person_add_rounded;
      case 'adminAction':
        return Icons.build_rounded;
      case 'disputeResolution':
        return Icons.gavel_rounded;
      case 'listingModeration':
        return Icons.inventory_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  Color _colorForType(String type, ColorScheme cs) {
    switch (type) {
      case 'login':
        return cs.primary;
      case 'registration':
        return cs.secondary;
      case 'adminAction':
        return cs.tertiary;
      case 'disputeResolution':
        return cs.error;
      default:
        return cs.primary;
    }
  }
}

// ── Quick action tile (shared with seller) ─────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;
  final Widget? trailing;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: AppSizes.paddingLG),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.60),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: AppSizes.paddingSM),
            ],
            Icon(Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.45)),
          ],
        ),
      ),
    );
  }
}
/// Small badge rendered on the "Manage Sellers" tile. Reflects
/// [adminPendingSellersCountProvider] — the live count of newly
/// registered street sellers awaiting approval. Hidden when the
/// count is zero so the dashboard stays clean.
class _PendingBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(adminPendingSellersCountProvider);
    final count = pendingAsync.valueOrNull ?? 0;
    if (count == 0) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSM,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        // Pending badge uses tertiary (warning amber on light, teal on
        // dark) so it stands out against the secondary-tile icons
        // around it without inheriting the primary accent.
        color: cs.tertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          color: cs.onTertiary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
