import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/common_widgets.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: userAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          return CustomScrollView(
            slivers: [
              // ── Gradient AppBar ──────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 160,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.primaryBlueDark,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1E293B),
                          Color(0xFF334155),
                          Color(0xFF475569),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            Row(
                              children: [
                                const Icon(Icons.admin_panel_settings_rounded,
                                    color: Colors.white, size: 28),
                                const SizedBox(width: 10),
                                Text(
                                  'Hello, ${user?.fullName.split(' ').first ?? "Admin"}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Platform Overview & Management',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.account_circle_rounded),
                    color: Colors.white,
                    onPressed: () => context.push('/profile'),
                  ),
                ],
              ),

              // ── Stats Grid ───────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(AppSizes.paddingLG),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSizes.paddingMD,
                  crossAxisSpacing: AppSizes.paddingMD,
                  childAspectRatio: 1.15,
                  children: const [
                    _StatCard(
                      title: 'Total Users',
                      value: '42',
                      icon: Icons.people_alt_rounded,
                      color: AppColors.primaryBlue,
                      gradient: LinearGradient(
                        colors: [Color(0xFFE3F0FF), Color(0xFFCCE5FF)],
                      ),
                    ),
                    _StatCard(
                      title: 'Active Listings',
                      value: '18',
                      icon: Icons.storefront_rounded,
                      color: AppColors.secondaryTeal,
                      gradient: LinearGradient(
                        colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
                      ),
                    ),
                    _StatCard(
                      title: 'Orders Today',
                      value: '7',
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.accentOrange,
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                      ),
                    ),
                    _StatCard(
                      title: 'Platform Rev',
                      value: 'TZS 45K',
                      icon: Icons.account_balance_rounded,
                      color: AppColors.successGreen,
                      gradient: LinearGradient(
                        colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Quick Actions ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSizes.paddingMD),
                      Text(
                        'Management',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: AppSizes.paddingLG),
                      _ActionTile(
                        icon: Icons.people_outline_rounded,
                        title: 'Manage Dalalis',
                        subtitle: 'Register, approve or block brokers',
                        onTap: () => context.push('/admin/manage-dalalis'),
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(height: AppSizes.paddingMD),
                      _ActionTile(
                        icon: Icons.list_alt_rounded,
                        title: 'All Listings',
                        subtitle: 'Review and moderate marketplace',
                        onTap: () => context.push('/listings'),
                        color: AppColors.secondaryTeal,
                      ),
                      const SizedBox(height: AppSizes.paddingMD),
                      _ActionTile(
                        icon: Icons.payments_outlined,
                        title: 'Transactions',
                        subtitle: 'View payment history',
                        onTap: () {},
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final LinearGradient gradient;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.gray600,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}
