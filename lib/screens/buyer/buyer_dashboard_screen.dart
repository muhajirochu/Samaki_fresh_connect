// Buyer Dashboard — Phase 3 layout.
//
// Layout (top → bottom):
//   1. Greeting header (existing)
//   2. Summary tiles (Phase 3): Fish Available / Active Requests / Nearest Seller
//   3. Autocomplete search bar (Phase 3)
//   4. "Ramani ya Wauzaji" CTA card (jumps to /buyer/map)
//   5. "Browse Other Fish" horizontal scroller (Phase 3)
//   6. "Popular Near You" recommendations (Phase 3)
//   7. Existing action grid + fresh catch section (kept for navigation)
//
// Every section reads from Riverpod providers, so updates flow in real time
// when fish go out of stock, requests open/close, or the buyer's location
// changes.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/fish_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/buyer_provider.dart';
import '../../providers/listing_provider.dart';
import '../../services/demo_seeder.dart';
import '../../utils/logger.dart';
import '../../widgets/dashboard/browse_fish_section.dart';
import '../../widgets/dashboard/popular_fish_section.dart';
import '../../widgets/dashboard/search_bar.dart';
import '../../widgets/dashboard/summary_header.dart';
import '../../widgets/notifications/wishlist_match_banner.dart';
import '../../widgets/common/app_bar_actions_bar.dart';

class BuyerDashboardScreen extends ConsumerWidget {
  const BuyerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));
          return Stack(
            children: [
              _DashboardBody(userName: user.fullName),
              // No-op listener that pops a SnackBar whenever the wishlist
              // cross-trigger fires. Mounted once at the root of the
              // buyer shell.
              const WishlistMatchBanner(),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  final String userName;
  const _DashboardBody({required this.userName});

  void _openMap(BuildContext context, {String? fishType, String? query}) {
    context.push('/map-foundation');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        // The streams are real-time; RefreshIndicator just gives the user
        // a tactile "I'm asking for fresh data" affordance. We await a
        // single frame so the spinner doesn't disappear instantly.
        await Future<void>.delayed(const Duration(milliseconds: 400));
      },
      child: CustomScrollView(
        slivers: [
          // ── 1. Greeting header ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 150,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primaryBlue,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF003D6B),
                      Color(0xFF0066B4),
                      Color(0xFF00A896),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          'Habari, ${userName.split(' ').first} 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pata samaki fresh karibu nawe',
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
              const AppBarActionsBar(),
              IconButton(
                tooltip: 'Profile',
                icon: const Icon(Icons.account_circle_rounded),
                color: Colors.white,
                onPressed: () => context.push('/profile'),
              ),
            ],
          ),

          // ── 2. Summary tiles ────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSizes.paddingLG,
                AppSizes.paddingMD,
                AppSizes.paddingLG,
                0,
              ),
              child: DashboardSummaryHeader(),
            ),
          ),

          // ── 3. Search bar (autocomplete) ────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSizes.paddingLG,
                AppSizes.paddingLG,
                AppSizes.paddingLG,
                AppSizes.paddingSM,
              ),
              child: DashboardSearchBar(),
            ),
          ),

          // ── 4. Map CTA card ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingLG,
                AppSizes.paddingMD,
                AppSizes.paddingLG,
                0,
              ),
              child: _MapCtaCard(
                onTap: () => _openMap(context),
              ),
            ),
          ),

          // ── 4a. Reseed Marketplace (dev-only safety net) ─────────────
          // If the buyer's map shows zero sellers, the seeder either
          // didn't run or wrote nothing usable. This tile re-runs it
          // on demand so we don't have to bounce the app.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingLG,
                AppSizes.paddingSM,
                AppSizes.paddingLG,
                0,
              ),
              child: _ReseedMarketplaceTile(
                onReseeded: () =>
                    ref.invalidate(activeListingsProvider),
              ),
            ),
          ),

          // ── 4b. My Requests CTA ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingLG,
                AppSizes.paddingMD,
                AppSizes.paddingLG,
                0,
              ),
              child: _RequestsCtaCard(
                onTap: () => context.push('/buyer/requests'),
                activeCount: ref.watch(activeRequestsCountProvider),
              ),
            ),
          ),

          // ── 5. Browse Other Fish ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                top: AppSizes.paddingXL,
                left: AppSizes.paddingLG,
                right: AppSizes.paddingLG,
                bottom: AppSizes.paddingSM,
              ),
              child: _SectionTitle(
                title: 'Vinjari Samaki Wengine',
                subtitle: 'Karibu nawe · Bei mpya',
                onAction: () => _openMap(context),
                actionLabel: 'Ona Ramani',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BrowseFishSection(
              onTap: (FishItemModel item) =>
                  context.push('/listings/${item.listingId}'),
            ),
          ),

          // ── 6. Popular Near You ────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: AppSizes.paddingXL,
                left: AppSizes.paddingLG,
                right: AppSizes.paddingLG,
                bottom: AppSizes.paddingSM,
              ),
              child: _SectionTitle(
                title: 'Maarufu Karibu Nawe',
                subtitle: 'Mapendekezo kwa eneo lako',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: PopularFishSection(
              onTap: (String fishName, String? fishTypeValue) =>
                  _openMap(context, fishType: fishTypeValue, query: fishName),
            ),
          ),

          // ── Bottom spacing ─────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSizes.paddingXXL),
          ),
        ],
      ),
    );
  }
}

class _MapCtaCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MapCtaCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00A896), Color(0xFF0066B4)],
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusLG),
            boxShadow: const [
              BoxShadow(
                color: Color(0x400066B4),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  ),
                  child: const Icon(Icons.map_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: AppSizes.paddingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fungua Ramani',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Wauzaji karibu, njia, na muda unaotarajiwa',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestsCtaCard extends StatelessWidget {
  final VoidCallback onTap;
  final int activeCount;
  const _RequestsCtaCard({required this.onTap, required this.activeCount});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusLG),
            border: Border.all(color: AppColors.gray200),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: AppColors.accentOrange, size: 24),
                ),
                const SizedBox(width: AppSizes.paddingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maombi Yangu',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activeCount == 0
                            ? 'Hakuna maombi yanayoendelea'
                            : '$activeCount maombi yanayoendelea',
                        style: const TextStyle(
                          color: AppColors.gray600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (activeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$activeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.gray400, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gray600,
                      ),
                ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: Text(actionLabel!),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
            ),
          ),
      ],
    );
  }
}

/// Dev-only tile that re-runs [DemoSeeder.seedDemoAccounts]. If the
/// buyer sees an empty map, this is the fast path: tap to re-seed
/// without bouncing the app. The `onReseeded` callback is used by
/// the parent to invalidate providers so the dashboard refreshes.
class _ReseedMarketplaceTile extends ConsumerStatefulWidget {
  final VoidCallback onReseeded;
  const _ReseedMarketplaceTile({required this.onReseeded});

  @override
  ConsumerState<_ReseedMarketplaceTile> createState() =>
      _ReseedMarketplaceTileState();
}

class _ReseedMarketplaceTileState
    extends ConsumerState<_ReseedMarketplaceTile> {
  bool _busy = false;

  Future<void> _reseed() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await DemoSeeder.seedDemoAccounts();
      if (!mounted) return;
      widget.onReseeded();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demo marketplace reseeded'),
          backgroundColor: AppColors.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e, st) {
      AppLogger.error('Manual reseed failed', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reseed failed: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.gray100,
      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      child: InkWell(
        onTap: _busy ? null : _reseed,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMD,
            vertical: AppSizes.paddingSM,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: _busy
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: AppColors.primaryBlue,
                      ),
              ),
              const SizedBox(width: AppSizes.paddingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Empty map? Reseed demo marketplace',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      'Taps run the demo seeder again (5 sellers + fish)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.gray600,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.gray500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}