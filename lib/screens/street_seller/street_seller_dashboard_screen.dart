import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/seller_location_provider.dart';
import '../../services/seller_location_tracker.dart';
import '../../services/seller_mirror_service.dart';
import '../../utils/formatters.dart';

class StreetSellerDashboardScreen extends ConsumerWidget {
  const StreetSellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensures `streetSellers/{uid}` mirror exists on first paint after
    // sign-in. The provider itself is fire-and-forget; it never throws.
    ref.watch(sellerMirrorBootstrapProvider);

    final userAsync = ref.watch(currentUserStreamProvider);
    final listingsAsync = userAsync.maybeWhen(
      data: (user) => user == null
          ? const AsyncValue.data(<dynamic>[])
          : ref.watch(sellerListingsProvider(user.userId)),
      orElse: () => const AsyncValue.data(<dynamic>[]),
    );

    final activeListings = listingsAsync.valueOrNull ?? const [];
    final totalStockKg = activeListings
        .where((l) => l.status == 'active')
        .fold<double>(0, (acc, l) => acc + l.quantityKg);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));

          return CustomScrollView(
            slivers: [
              // ── Gradient AppBar ──────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 160,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFFBF360C),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFBF360C),
                          Color(0xFFE65100),
                          Color(0xFFFF8A50),
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
                                const Icon(Icons.storefront_rounded,
                                    color: Colors.white, size: 28),
                                const SizedBox(width: 10),
                                Text(
                                  'Hi, ${user.fullName.split(' ').first}! 🛒',
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
                              'Your street selling hub',
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
                  _OnlineToggleButton(),
                  IconButton(
                    icon: const Icon(Icons.notifications_rounded),
                    color: Colors.white,
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.account_circle_rounded),
                    color: Colors.white,
                    onPressed: () => context.push('/profile'),
                  ),
                ],
              ),

              // ── Stats Row ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.paddingLG,
                      AppSizes.paddingLG, AppSizes.paddingLG, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Active Listings',
                          value: '${activeListings.where((l) => l.status == 'active').length}',
                          icon: Icons.inventory_2_rounded,
                          color: const Color(0xFFE65100),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingMD),
                      Expanded(
                        child: _StatCard(
                          title: 'Total Stock',
                          value: Formatters.formatQuantity(totalStockKg),
                          icon: Icons.scale_rounded,
                          color: AppColors.successGreen,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Quick Actions ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingLG,
                      AppSizes.paddingXL,
                      AppSizes.paddingLG,
                      AppSizes.paddingSM),
                  child: Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                  ),
                ),
              ),
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSizes.paddingMD,
                    mainAxisSpacing: AppSizes.paddingMD,
                    childAspectRatio: 1.15,
                  ),
                  delegate: SliverChildListDelegate([
                    _ActionCard(
                      title: 'Buy Stock',
                      subtitle: 'Browse marketplace',
                      icon: Icons.shopping_cart_rounded,
                      color: AppColors.primaryBlue,
                      onTap: () => context.push('/listings'),
                    ),
                    _ActionCard(
                      title: 'My Orders',
                      subtitle: 'Track purchases',
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.infoBlue,
                      onTap: () => context.push('/orders'),
                    ),
                    _ActionCard(
                      title: 'Sell Stock',
                      subtitle: 'Post a listing',
                      icon: Icons.add_business_rounded,
                      color: AppColors.secondaryTeal,
                      onTap: () => context.push('/listings/create'),
                    ),
                    _ActionCard(
                      title: 'My Listings',
                      subtitle: 'Manage your stock',
                      icon: Icons.format_list_bulleted_rounded,
                      color: AppColors.accentOrange,
                      onTap: () => context.push('/listings/mine'),
                    ),
                  ]),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSizes.paddingXXL),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/listings/create'),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: AppColors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Sell Stock',
            style: TextStyle(fontWeight: FontWeight.w600)),
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
          const SizedBox(height: AppSizes.paddingSM),
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

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLG),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingSM),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: AppSizes.paddingSM),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.gray500,
                      fontSize: 11,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pulsing "Go online / Go offline" pill button. Stays in the dashboard
/// app bar so the seller can flip their live status without entering a
/// dedicated screen.
class _OnlineToggleButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(sellerOnlineStatusProvider);
    final tracker = ref.watch(sellerLocationTrackerProvider);
    final isOnline = status == SellerTrackerStatus.online;
    final isBusy = status == SellerTrackerStatus.waitingForPermission;

    final (label, icon) = switch (status) {
      SellerTrackerStatus.online => (
        'Online', Icons.radio_button_checked_rounded
      ),
      SellerTrackerStatus.waitingForPermission => (
        'Starting…', Icons.hourglass_top_rounded
      ),
      SellerTrackerStatus.error => (
        tracker.errorMessage ?? 'Offline', Icons.error_outline_rounded
      ),
      SellerTrackerStatus.idle => (
        'Offline', Icons.radio_button_unchecked_rounded
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Material(
        color: isOnline
            ? AppColors.successGreen
            : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isBusy
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final actions = ref.read(sellerOnlineActionsProvider);
                  if (isOnline) {
                    await actions.goOffline();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('You are now offline'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    final ok = await actions.goOnline();
                    if (!ok && context.mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            tracker.errorMessage ??
                                'Could not go online',
                          ),
                          backgroundColor: AppColors.errorRed,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else if (context.mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'You are now online · sharing location',
                          ),
                          backgroundColor: AppColors.successGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOnline)
                  const _PulsingDot()
                else
                  Icon(icon, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value; // 0..1
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 1.0 - (t * 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.white
                    .withValues(alpha: 0.6 - (t * 0.4)),
                blurRadius: 4 + (t * 6),
                spreadRadius: 1 + (t * 2),
              ),
            ],
          ),
        );
      },
    );
  }
}
