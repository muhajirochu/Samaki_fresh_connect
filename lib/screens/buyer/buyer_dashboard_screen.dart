// Buyer Dashboard — Phase 3 layout.
//
// Layout (top → bottom):
//   1. Greeting header
//   2. Summary tiles: Fish Available / Active Requests / Nearest Seller
//   3. Autocomplete search bar
//   4. "Ramani ya Wauzaji" CTA card (jumps to /buyer/map)
//   5. My Requests CTA
//   6. "Browse Other Fish" horizontal scroller
//   7. "Popular Near You" recommendations
//
// Every section reads from Riverpod providers, so updates flow in real time
// when fish go out of stock, requests open/close, or the buyer's location
// changes.
//
// Note: the previous "Reseed demo marketplace" dev tile was removed
// when demo street-seller data was taken out — sellers must register
// themselves, so there is nothing to reseed.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/theme_extensions.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/fish_item_model.dart';
import '../../models/street_seller_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/buyer_provider.dart';
import '../../widgets/common/premium_components.dart';
import '../../widgets/common/top_app_bar.dart';
import '../../widgets/dashboard/browse_fish_section.dart';
import '../../widgets/dashboard/popular_fish_section.dart';
import '../../widgets/dashboard/search_bar.dart';
import '../../widgets/dashboard/summary_header.dart';
import '../../widgets/notifications/wishlist_match_banner.dart';

class BuyerDashboardScreen extends ConsumerWidget {
  const BuyerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // The new global TopAppBar carries the profile, notifications
      // and theme toggle. It slots straight into the Scaffold's appBar
      // slot so Material handles status-bar / safe-area / elevation.
      appBar: const TopAppBar(),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text(l10n.loadingError(error.toString()))),
        data: (user) {
          if (user == null) {
            return Center(child: Text(l10n.notLoggedIn));
          }
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingLG,
                AppSizes.paddingMD,
                AppSizes.paddingLG,
                AppSizes.paddingSM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Habari, ${userName.split(' ').first} 👋',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pata samaki fresh karibu nawe',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.65),
                        ),
                  ),
                ],
              ),
            ),
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

          // ── 4a. My Requests CTA ────────────────────────────────────
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

          // ── 4b. Sellers near you (track-seller entry point) ─────────
          SliverToBoxAdapter(
            child: _SellersNearYouSection(
              onTapSeller: (sellerId) =>
                  context.push('/buyer/seller/$sellerId'),
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
              child: SectionHeader(
                title: 'Vinjari Samaki Wengine',
                subtitle: 'Karibu nawe · Bei mpya',
                actionLabel: 'Ona Ramani',
                actionIcon: Icons.arrow_forward_rounded,
                leadingIcon: Icons.set_meal_rounded,
                onAction: () => _openMap(context),
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
              child: SectionHeader(
                title: 'Maarufu Karibu Nawe',
                subtitle: 'Mapendekezo kwa eneo lako',
                leadingIcon: Icons.local_fire_department_rounded,
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
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppGradients.of(context).brand,
            borderRadius: BorderRadius.circular(AppSizes.radiusLG),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
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
                    // Translucent white wash on the icon container —
                    // this sits ON TOP of the brand gradient, so the
                    // foreground colour is `cs.onPrimary` to track
                    // theme changes.
                    color: cs.onPrimary.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  ),
                  child: Icon(Icons.map_rounded,
                      color: cs.onPrimary, size: 28),
                ),
                const SizedBox(width: AppSizes.paddingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fungua Ramani',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Wauzaji karibu, njia, na muda unaotarajiwa',
                        style: TextStyle(
                          color: cs.onPrimary.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: cs.onPrimary),
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        child: Ink(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLG),
            border: Border.all(
              color: cs.outline.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.06),
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
                    // Accent amber tile on the active requests CTA —
                    // uses tertiary so it contrasts with the primary
                    // gradient above without sharing its colour.
                    color: cs.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  ),
                  child: Icon(Icons.send_rounded,
                      color: cs.tertiary, size: 24),
                ),
                const SizedBox(width: AppSizes.paddingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maombi Yangu',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activeCount == 0
                            ? 'Hakuna maombi yanayoendelea'
                            : '$activeCount maombi yanayoendelea',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                if (activeCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.tertiary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$activeCount',
                      style: TextStyle(
                        color: cs.onTertiary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: cs.onSurface.withValues(alpha: 0.45), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Sellers near you" — horizontally-scrolling strip of live street
/// sellers. Each card pushes `/buyer/seller/:sellerId` so the buyer
/// can track the seller (see profile, listings, call / SMS).
///
/// Implementation note: inline (not in a separate file) because this
/// is tightly coupled to the dashboard's live-sellers slice. The
/// widget falls back to an empty-state tile when the live sellers
/// stream is empty so the dashboard layout doesn't jump.
class _SellersNearYouSection extends ConsumerWidget {
  final void Function(String sellerId) onTapSeller;
  const _SellersNearYouSection({required this.onTapSeller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = BackgroundStyle.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final sellersAsync = ref.watch(activeStreetSellersProvider);

    return sellersAsync.when(
      loading: () => const SizedBox(
        height: 132,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingLG),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLG),
            border: Border.all(color: tokens.border, width: 0.6),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent),
              const SizedBox(width: AppSizes.paddingSM),
              Expanded(
                child: Text(
                  l10n.loadingError(e.toString()),
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (allSellers) {
        final sellers = allSellers.take(5).toList(growable: false);
        if (sellers.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.paddingLG),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                border: Border.all(color: tokens.border, width: 0.6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: AppSizes.paddingSM),
                  Expanded(
                    child: Text(
                      l10n.sellersNearby(0),
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(
            top: AppSizes.paddingSM,
            bottom: AppSizes.paddingMD,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingLG,
                ),
                child: Row(
                  children: [
                    Icon(Icons.storefront_rounded, color: cs.primary, size: 20),
                    const SizedBox(width: AppSizes.paddingSM),
                    Expanded(
                      child: Text(
                        l10n.sellersNearYou,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Text(
                      l10n.sellersNearby(sellers.length),
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.paddingSM),
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingLG,
                  ),
                  itemCount: sellers.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSizes.paddingMD),
                  itemBuilder: (context, i) => _SellerNearbyCard(
                    seller: sellers[i],
                    onTap: () => onTapSeller(sellers[i].sellerId),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Compact card for a single street seller in the "Sellers near you"
/// strip — avatar, name, online dot, and tap-to-track.
class _SellerNearbyCard extends StatelessWidget {
  final StreetSellerModel seller;
  final VoidCallback onTap;
  const _SellerNearbyCard({required this.seller, required this.onTap});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Color _tintFor(String seed) {
    // Stable colour per seller so the same seller always renders the
    // same avatar tint even before the network image arrives. These
    // are identifier hues that stay constant across themes — they
    // are NOT theme tokens, they are seller identifiers.
    const palette = [
      Color(0xFF2563EB), // Modern Blue
      Color(0xFF14B8A6), // Teal
      Color(0xFFF59E0B), // Amber
      Color(0xFF16A34A), // Elegant Green
      Color(0xFF3B82F6), // Bright Blue
      Color(0xFFEF4444), // Red (warning/alert)
    ];
    final hash = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    return palette[hash % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final tokens = BackgroundStyle.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tint = _tintFor(seller.sellerId);
    return SizedBox(
      width: 168,
      child: Material(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusLG),
              border: Border.all(color: tokens.border, width: 0.6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: tint.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(seller.fullName),
                        style: tt.titleSmall?.copyWith(
                          color: tint,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (seller.isOnline)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          // Live dot uses the secondary (Elegant
                          // Green) so it tracks the active-status
                          // semantic across light + dark.
                          color: cs.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingSM),
                Text(
                  seller.fullName,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // Star rating stays amber across themes — it's
                    // the universal "rating" cue.
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFF59E0B), size: 14),
                    const SizedBox(width: 2),
                    Text(
                      seller.totalRatings == 0
                          ? '—'
                          : seller.averageRating.toStringAsFixed(1),
                      style: tt.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        seller.marketName ?? '',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
