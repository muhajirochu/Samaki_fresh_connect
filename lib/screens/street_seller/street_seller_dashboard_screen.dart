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
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/seller_location_provider.dart';
import '../../services/seller_location_tracker.dart';
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
          ? const AsyncValue.data(0)
          : ref.watch(streetSellerPendingOrdersProvider(user.userId)),
      orElse: () => const AsyncValue.data(0),
    );
    final pendingOrders = pendingOrdersAsync.valueOrNull ?? 0;

    final activeListings = listingsAsync.valueOrNull ?? const [];
    final totalStockKg = activeListings
        .where((l) => l.status == 'active')
        .fold<double>(0, (acc, l) => acc + l.quantityKg);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // The new global TopAppBar carries the profile, notifications
      // and theme toggle so seller + buyer share the same chrome.
      appBar: const TopAppBar(),
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

            return CustomScrollView(
              slivers: [
                // ── Brand gradient greeting header ───────────────────────────
                SliverToBoxAdapter(
                  child: _SellerGreetingHeader(
                    greeting: l10n.habari(user.fullName.split(' ').first),
                    subtitle: l10n.yourStreetSellingHub,
                    onlineToggle: _OnlineToggleButton(),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(AppRouteNames.listingsCreate),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.sellStock,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
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

/// Pulsing "Go online / Go offline" pill button. Stays in the dashboard
/// app bar so the seller can flip their live status without entering a
/// dedicated screen. Uses `Elegant Green` for online (matches buyer
/// dashboard semantic colour) and white-tint for offline.
class _OnlineToggleButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(sellerOnlineStatusProvider);
    final tracker = ref.watch(sellerLocationTrackerProvider);
    final isOnline = status == SellerTrackerStatus.online;
    final isBusy = status == SellerTrackerStatus.waitingForPermission;
    final cs = Theme.of(context).colorScheme;

    final (label, icon) = switch (status) {
      SellerTrackerStatus.online => (
          AppLocalizations.of(context).online,
          Icons.radio_button_checked_rounded
        ),
      SellerTrackerStatus.waitingForPermission => (
          AppLocalizations.of(context).starting,
          Icons.hourglass_top_rounded
        ),
      SellerTrackerStatus.error => (
          tracker.errorMessage ?? AppLocalizations.of(context).offline,
          Icons.error_outline_rounded
        ),
      SellerTrackerStatus.idle => (
          AppLocalizations.of(context).offline,
          Icons.radio_button_unchecked_rounded
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Material(
        color: isOnline ? cs.secondary : cs.onPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isBusy
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final actions = ref.read(sellerOnlineActionsProvider);
                  final l10n = AppLocalizations.of(context);
                  if (isOnline) {
                    await actions.goOffline();
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.youAreNowOffline),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    final ok = await actions.goOnline();
                    if (!context.mounted) return;
                    if (!ok) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            tracker.errorMessage ?? l10n.callFailed,
                          ),
                          backgroundColor: cs.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(l10n.youAreNowOnline),
                          backgroundColor: cs.secondary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOnline)
                  const _PulsingDot()
                else
                  Icon(icon, color: cs.onPrimary, size: 14),
                const SizedBox(width: 6),
                // Bounded: in the error state `label` is a raw
                // `tracker.errorMessage` sentence, not a short status
                // word. Unbounded it blew the greeting row off the
                // right edge of a 360dp phone.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 96),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
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
  final Widget onlineToggle;

  const _SellerGreetingHeader({
    required this.greeting,
    required this.subtitle,
    required this.onlineToggle,
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
                    cs.onPrimary.withValues(alpha: 0.18),
                    cs.onPrimary.withValues(alpha: 0),
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
                    cs.onPrimary.withValues(alpha: 0.10),
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
                // Top row: greeting + online toggle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.storefront_rounded,
                        color: cs.onPrimary, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        greeting,
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    onlineToggle,
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
