import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme_extensions.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/common/top_app_bar.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Shared TopAppBar gives admin the same profile, notifications
      // and theme toggle affordances as buyer + street seller.
      appBar: const TopAppBar(),
      body: userAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text(l10n.loadingError(e.toString()))),
        data: (user) {
          if (user == null) {
            return Center(child: Text(l10n.notLoggedIn));
          }
          return CustomScrollView(
            slivers: [
              // ── Brand gradient greeting header ─────────────────────
              SliverToBoxAdapter(
                child: _AdminGreetingHeader(
                  greeting: l10n.hello(
                      user.fullName.split(' ').first),
                  subtitle: l10n.platformOverview,
                ),
              ),

              // ── Stats Grid ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(AppSizes.paddingLG),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSizes.paddingMD,
                  crossAxisSpacing: AppSizes.paddingMD,
                  childAspectRatio: 1.15,
                  children: [
                    _TotalUsersCard(),
                    _ActiveListingsCard(),
                    _OrdersTodayCard(),
                    _PlatformRevenueCard(),
                  ],
                ),
              ),

              // ── Quick Actions ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSizes.paddingMD),
                      Text(
                        l10n.management,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: AppSizes.paddingLG),
                      _ActionTile(
                        icon: Icons.people_outline_rounded,
                        title: l10n.manageStreetSellers,
                        subtitle: l10n.manageStreetSellersSubtitle,
                        onTap: () => context.push('/admin/sellers'),
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(height: AppSizes.paddingMD),
                      _ActionTile(
                        icon: Icons.list_alt_rounded,
                        title: l10n.allListings,
                        subtitle: l10n.allListingsSubtitle,
                        onTap: () => context.push('/admin/listings'),
                        color: AppColors.secondaryTeal,
                      ),
                      const SizedBox(height: AppSizes.paddingMD),
                      _ActionTile(
                        icon: Icons.payments_outlined,
                        title: l10n.transactionsTitle,
                        subtitle: l10n.transactionsScreenSubtitle,
                        onTap: () => context.push('/admin/transactions'),
                        color: AppColors.successGreen,
                      ),
                      const SizedBox(height: AppSizes.paddingXXL),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Live stat cards ─────────────────────────────────────────────────────
//
// Each card reads from a dedicated Riverpod stream so the value
// updates in real time as data lands in Firestore.

class _TotalUsersCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final countsAsync = ref.watch(adminUserCountsProvider);
    final total = countsAsync.maybeWhen(
      data: (counts) {
        final b = counts['buyer'] ?? 0;
        final s = counts['streetSeller'] ?? 0;
        final a = counts['admin'] ?? 0;
        return b + s + a;
      },
      orElse: () => 0,
    );
    return _StatCard(
      title: l10n.totalUsers,
      value: total.toString(),
      icon: Icons.people_alt_rounded,
      color: AppColors.primaryBlue,
    );
  }
}

class _ActiveListingsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final countAsync = ref.watch(adminActiveListingsCountProvider);
    final count = countAsync.valueOrNull ?? 0;
    return _StatCard(
      title: l10n.activeListings,
      value: count.toString(),
      icon: Icons.storefront_rounded,
      color: AppColors.secondaryTeal,
    );
  }
}

class _OrdersTodayCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final countAsync = ref.watch(adminTodaysOrdersProvider);
    final count = countAsync.valueOrNull?.length ?? 0;
    return _StatCard(
      title: l10n.ordersToday,
      value: count.toString(),
      icon: Icons.receipt_long_rounded,
      color: AppColors.infoBlue,
    );
  }
}

class _PlatformRevenueCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final revenueAsync = ref.watch(adminPlatformRevenueProvider);
    final revenue = revenueAsync.valueOrNull ?? 0.0;
    return _StatCard(
      title: l10n.platformRevenue,
      value: _formatRevenue(revenue),
      icon: Icons.account_balance_rounded,
      color: AppColors.successGreen,
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

/// Brand gradient greeting header for the admin dashboard — same
/// visual language as buyer + street seller greeting headers so all
/// three dashboards read as one product family.
class _AdminGreetingHeader extends StatelessWidget {
  final String greeting;
  final String subtitle;

  const _AdminGreetingHeader({
    required this.greeting,
    required this.subtitle,
  });

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
          // Decorative glow blob top-right
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
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          // Decorative glow blob bottom-left
          Positioned(
            bottom: -50,
            left: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0),
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
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontSize: 24,
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
                  style: TextStyle(
                    color: cs.onPrimary.withValues(alpha: 0.85),
                    fontSize: 14,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? cs.surfaceContainerHighest
        : color.withValues(alpha: 0.10);

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            value,
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
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
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
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
            Icon(Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.45)),
          ],
        ),
      ),
    );
  }
}
