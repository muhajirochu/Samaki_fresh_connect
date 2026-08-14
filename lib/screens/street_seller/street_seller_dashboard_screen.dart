// Street seller dashboard — premium version.
//
// Layout (top → bottom):
//   1. Greeting header with brand gradient (Modern Blue → Elegant Green)
//   2. Stats row: Active Listings + Total Stock
//   3. Quick actions grid: Buy Stock, My Orders, Sell Stock, My Listings
//
// Branding matches the buyer dashboard — Modern Blue primary and
// Elegant Green accent. The orange theme was removed so the whole app
// reads as one product family.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_sizes.dart';
import '../../config/route_paths.dart';
import '../../config/theme_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/order_tracking_provider.dart';
import '../../services/seller_mirror_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/premium_components.dart';
import '../../widgets/common/top_app_bar.dart';

class StreetSellerDashboardScreen extends ConsumerWidget {
  const StreetSellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensures `streetSellers/{uid}` mirror exists on first paint after
    // sign-in. The provider itself is fire-and-forget; it never throws.
    ref.watch(sellerMirrorBootstrapProvider);

    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    final userAsync = ref.watch(currentUserStreamProvider);
    final listingsAsync = userAsync.maybeWhen(
      data: (user) => user == null
          ? const AsyncValue.data(<dynamic>[])
          : ref.watch(sellerListingsProvider(user.userId)),
      orElse: () => const AsyncValue.data(<dynamic>[]),
    );

    // Live count of pending orders for the "My Orders" badge.
    // Updates without navigation as soon as a buyer places an order.
    final pendingOrdersAsync = userAsync.maybeWhen(
      data: (user) => user == null
          ? const AsyncValue.data(<OrderModel>[])
          : ref.watch(sellerPendingOrdersProvider(user.userId)),
      orElse: () => const AsyncValue.data(<OrderModel>[]),
    );
    final pendingOrders = pendingOrdersAsync.valueOrNull?.length ?? 0;

    final activeListings = listingsAsync.valueOrNull ?? const [];
    final totalStockKg = activeListings
        .where((l) => l.status == 'active')
        .fold<double>(0, (acc, l) => acc + l.quantityKg);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // TopAppBar moved into the scrollable body so the hero gradient
      // can seamlessly reach the top edge of the screen.
      // top: false — the AppBar owns the status-bar inset. The bottom
      // inset keeps the last grid row clear of the gesture nav pill on
      // real phones; emulators rarely show one.
      body: SafeArea(
        top: false,
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text(l10n.loadingError(error.toString()))),
          data: (user) {
            if (user == null) {
              return Center(child: Text(l10n.notLoggedIn));
            }

            if (!user.isApproved) {
              return _buildPendingApprovalBody(context, ref, user);
            }

            return CustomScrollView(
              slivers: [
                // ── Brand gradient greeting header ───────────────────────────
                SliverToBoxAdapter(
                  child: _SellerGreetingHeader(
                    greeting: l10n.habari(user.fullName),
                    subtitle: l10n.yourStreetSellingHub,
                  ),
                ),

                // ── Stats Row ────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingLG,
                      AppSizes.paddingLG,
                      AppSizes.paddingLG,
                      0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: l10n.activeListings,
                            value:
                                '${activeListings.where((l) => l.status == 'active').length}',
                            icon: Icons.inventory_2_rounded,
                            accent: cs.primary,
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingMD),
                        Expanded(
                          child: _StatCard(
                            title: l10n.totalStock,
                            value: Formatters.formatQuantity(totalStockKg),
                            icon: Icons.scale_rounded,
                            accent: cs.secondary,
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
                      AppSizes.paddingSM,
                    ),
                    child: SectionHeader(
                      title: l10n.quickActions,
                      leadingIcon: Icons.bolt_rounded,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingLG,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSizes.paddingMD,
                      mainAxisSpacing: AppSizes.paddingMD,
                      childAspectRatio: 1.15,
                    ),
                    delegate: SliverChildListDelegate([
                      _ActionCard(
                        title: l10n.buyStock,
                        subtitle: l10n.buyStockSubtitle,
                        icon: Icons.shopping_cart_rounded,
                        accent: cs.primary,
                        onTap: () => context.pushNamed(AppRouteNames.listings),
                      ),
                      _ActionCard(
                        title: l10n.myOrders,
                        subtitle: l10n.myOrdersSubtitle,
                        icon: Icons.receipt_long_rounded,
                        accent: cs.tertiary,
                        badgeCount: pendingOrders,
                        onTap: () => context.pushNamed(AppRouteNames.orders),
                      ),
                      _ActionCard(
                        title: l10n.sellStock,
                        subtitle: l10n.sellStockSubtitle,
                        icon: Icons.add_business_rounded,
                        accent: cs.secondary,
                        onTap: () =>
                            context.pushNamed(AppRouteNames.listingsCreate),
                      ),
                      _ActionCard(
                        title: l10n.myListings,
                        subtitle: l10n.myListingsSubtitle,
                        icon: Icons.format_list_bulleted_rounded,
                        accent: cs.primary,
                        onTap: () =>
                            context.pushNamed(AppRouteNames.listingsMine),
                      ),
                    ]),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSizes.paddingXXL + 48),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: (userAsync.valueOrNull?.isApproved ?? false)
          ? FloatingActionButton.extended(
              heroTag: 'streetSellerDashboardFab',
              onPressed: () => context.pushNamed(AppRouteNames.listingsCreate),
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.sellStock,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildPendingApprovalBody(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _SellerGreetingHeader(
            greeting: 'Habari, ${user.fullName}!',
            subtitle: 'Akaunti Yako Inasubiri Uhakiki',
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSizes.paddingLG),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Main Pending Approval Banner Card
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingLG),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0284C7).withValues(alpha: 0.12),
                      const Color(0xFF0369A1).withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                  border: Border.all(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.hourglass_top_rounded,
                        color: Color(0xFF0EA5E9),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingMD),
                    Text(
                      'Akaunti Inasubiri Idhini ya Admin',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'PENDING VERIFICATION',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingMD),
                    Text(
                      'Usajili wako umepokelewa kikamilifu! Akaunti yako ya muuzaji ipo kwenye mchakato wa kuhakikiwa na Admin wa SamakiFresh.\n\nHutaweza kuingiza samaki wapya, kuanzisha uuzaji wa live, wala kupokea oda hadi akaunti yako ithibitishwe na Admin.',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.75),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.paddingLG),

              // Process Timeline
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingLG),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                  border: Border.all(
                    color: cs.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hatua za Usajili',
                      style:
                          tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSizes.paddingMD),
                    const _StepTile(
                      icon: Icons.check_circle_rounded,
                      iconColor: Color(0xFF0369A1),
                      title: '1. Usajili Umekamilika',
                      subtitle: 'Taarifa zako zimehifadhiwa salama',
                      isDone: true,
                    ),
                    const Divider(height: 24),
                    _StepTile(
                      icon: Icons.hourglass_bottom_rounded,
                      iconColor: Color(0xFF0284C7),
                      title: '2. Uhakiki wa Admin',
                      subtitle:
                          'Admin anapitia taarifa zako (Kawaida chini ya masaa 24)',
                      isDone: false,
                      isActive: true,
                    ),
                    const Divider(height: 24),
                    const _StepTile(
                      icon: Icons.store_rounded,
                      iconColor: Colors.grey,
                      title: '3. Anza Kuuza Samaki',
                      subtitle: 'Utafunguliwa milango ya kuuza samaki sokoni',
                      isDone: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.paddingLG),

              // Refresh Status Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(currentUserStreamProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Inakagua hali ya akaunti yako...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Kagua Hali ya Akaunti (Refresh)'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                    ),
                    side: BorderSide(color: cs.primary),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingMD),

              // Logout Action
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFF0369A1)),
                  label: const Text(
                    'Ondoka (Sign Out)',
                    style: TextStyle(
                        color: Color(0xFF0369A1), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isActive;

  const _StepTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDone,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: AppSizes.paddingMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: isActive || isDone
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isActive
                      ? iconColor
                      : (isDone
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.5)),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Stat card — themed surface with accent-coloured icon and a soft
/// ring of the accent colour around the edge so it matches the
/// `PremiumCard` look used elsewhere.
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
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
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? accent.withValues(alpha: 0.45)
              : accent.withValues(alpha: 0.30),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(height: AppSizes.paddingSM),
          Text(
            value,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
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

/// Action card — matches `_StatCard`'s surface treatment but with a
/// centred icon and label so it reads as a tappable target.
///
/// Optional [badgeCount] overlays a small red count chip in the
/// top-right when > 0 — used to surface pending-order counts on
/// the "My Orders" tile without forcing the seller to navigate.
class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final int badgeCount;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final card = Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLG),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? accent.withValues(alpha: 0.40)
                  : cs.outline.withValues(alpha: 0.30),
            ),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingXS),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(height: AppSizes.paddingXS),
              Text(
                title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              // Flexible, not a bare Text: on a 360dp phone the tile is
              // ~150dp tall and a two-line Swahili subtitle is exactly
              // what tips the column past its constraint. Letting this
              // child shrink keeps the icon and title intact instead of
              // painting overflow stripes across the card.
              Flexible(
                child: Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.60),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (badgeCount <= 0) return card;

    // Pending-order badge — small red count chip in the top-right.
    // Mirrors the global TopAppBar bell's badge treatment so the
    // seller recognises the signal immediately.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: -6,
          right: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            decoration: BoxDecoration(
              color: cs.error,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.surface, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                badgeCount > 9 ? '9+' : '$badgeCount',
                style: TextStyle(
                  color: cs.onError,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ],
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
                color: Colors.white.withValues(alpha: 0.6 - (t * 0.4)),
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

/// Brand gradient greeting header for the street seller dashboard.
///
/// Mirrors the buyer dashboard's hero header treatment — Modern Blue
/// → Elegant Green gradient, decorative radial glow blobs, white
/// typography — so buyer and seller share the same visual identity.
///
/// Slots an [onlineToggle] action into the top-right of the gradient
/// (replaces the old SliverAppBar actions slot) so the live-status
/// pill stays one tap away without duplicating the global TopAppBar.
class _SellerGreetingHeader extends StatelessWidget {
  final String greeting;
  final String subtitle;

  const _SellerGreetingHeader({
    required this.greeting,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.of(context).hero,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TopAppBar(transparentHero: true),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingLG,
                  AppSizes.paddingSM,
                  AppSizes.paddingLG,
                  AppSizes.paddingLG,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
