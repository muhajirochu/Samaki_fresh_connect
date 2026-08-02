// "Recently Buy" — auto-advancing horizontal carousel of the buyer's
// most recent purchases. Each card surfaces the fish image, name, the
// quantity they bought, the price they paid, and the time elapsed since
// the order completed. Cards are read-only: tapping re-opens the listing
// detail so the buyer can reorder.
//
// Data flow:
//   1. Watch `buyerOrdersProvider(buyerId)` to get the buyer's orders.
//   2. Filter to terminal states (completed / confirmed) and de-dupe by
//      `listingId` — we only want one card per fish, even if the buyer
//      bought the same fish three times.
//   3. Sort by order `createdAt` desc and take the most recent 10.
//   4. Try to enrich each entry with the live `FishItemModel` from
//      `buyerFishFeedProvider` (gives us display name + image URLs).
//      If the listing is gone, fall back to a minimal card driven by
//      order fields alone so the carousel never stalls.
//
// Auto-advance: a Timer.periodic advances `PageController.nextPage`
// every `_autoAdvanceInterval`. User drag pauses the timer (so the
// buyer can actually read the card) and resumes 4s after the touch
// ends.

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/theme_extensions.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/fish_item_model.dart';
import '../../models/order_model.dart';
import '../../providers/buyer_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/formatters.dart';

/// A recent purchase enriched with whatever live listing data we can
/// find in the buyer feed. If the live listing is gone (typically
/// because it was marked `sold` after the order completed), the card
/// falls back to the order's stored fields. The widget layer attaches
/// the active locale to the entry before rendering.
class RecentPurchaseEntry {
  final OrderModel order;
  final FishItemModel? liveListing;
  const RecentPurchaseEntry({required this.order, this.liveListing});

  /// Display name — prefer the live listing's displayName (so the
  /// buyer sees the same name they'd see on the marketplace today)
  /// and fall back to a localized "Order #…" label.
  String displayName(AppLocalizations l10n) =>
      liveListing?.displayName ?? l10n.orderFallbackName(_short(order.orderId));

  String? get imageUrl {
    final urls = liveListing?.imageUrls;
    if (urls == null || urls.isEmpty) return null;
    return urls.first;
  }

  String get formattedPrice =>
      Formatters.formatCurrency(order.finalPrice);

  String get formattedQuantity =>
      Formatters.formatQuantity(order.quantityKg);

  static String _short(String id) =>
      id.length > 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase();
}

/// Resolves the most recent distinct purchases for the signed-in buyer.
/// Distinct by `listingId` — a buyer who re-orders the same fish sees
/// one card per fish, anchored to the most recent order.
///
/// Each entry is enriched in two passes:
///   1. The live `buyerFishFeedProvider` snapshot is consulted first
///      (cheap, already cached). This catches listings that are still
///      `active` and in stock.
///   2. If the listing isn't in the live feed (typically because it
///      flipped to `sold` after the buyer completed the order),
///      `listingDetailProvider` is watched for that one id. Riverpod
///      keeps the FutureProvider cached so a re-mount doesn't re-hit
///      Firestore, and only listings actually shown in the carousel
///      trigger a fetch — capped at 10 cards.
final recentPurchasesProvider = Provider<List<RecentPurchaseEntry>>((ref) {
  final session = ref.watch(currentBuyerSessionProvider);
  if (session == null) return const [];
  final ordersAsync = ref.watch(buyerOrdersProvider(session.buyerId));
  final orders = ordersAsync.valueOrNull ?? const <OrderModel>[];

  // Build a lookup of live listings by id so each card can enrich
  // itself with current name + image.
  final fish = ref.watch(buyerFishFeedProvider).valueOrNull ??
      const <FishItemModel>[];
  final byListingId = {for (final f in fish) f.listingId: f};

  // Keep only terminal-happy states — those are the ones the buyer
  // actually "bought". `cancelled` orders are excluded on purpose so
  // the carousel never shows a card the buyer refunded / never
  // received.
  final terminal = orders.where((o) =>
      o.orderStatus == 'completed' ||
      o.orderStatus == 'confirmed' ||
      o.orderStatus == 'in_transit' ||
      o.orderStatus == 'delivered');

  // De-dupe by listingId, keeping the most recent order.
  final seen = <String>{};
  final deduped = <OrderModel>[];
  for (final o in terminal) {
    if (seen.add(o.listingId)) deduped.add(o);
  }

  final entries = <RecentPurchaseEntry>[];
  for (final o in deduped.take(10)) {
    FishItemModel? enriched = byListingId[o.listingId];
    if (enriched == null) {
      // The live feed drops sold listings. Fall back to a one-shot
      // detail fetch — this is the path that surfaces the image for
      // completed orders. `autoDispose: false` keeps the cache warm
      // across re-mounts and `ref.watch` triggers a rebuild as soon
      // as the fetch lands.
      final detail =
          ref.watch(listingDetailProvider(o.listingId)).valueOrNull;
      if (detail != null) {
        enriched = FishItemModel.fromMap(detail.toJson(),
            docId: detail.listingId);
      }
    }
    entries.add(RecentPurchaseEntry(order: o, liveListing: enriched));
  }
  return entries;
});

class RecentlyBoughtSection extends ConsumerStatefulWidget {
  /// Called when the buyer taps a card. Receives the order's listingId
  /// so the caller can route to the existing `/listings/{id}` detail.
  final void Function(String listingId) onTap;
  final AppLocalizations l10n;

  const RecentlyBoughtSection({
    super.key,
    required this.onTap,
    required this.l10n,
  });

  @override
  ConsumerState<RecentlyBoughtSection> createState() =>
      _RecentlyBoughtSectionState();
}

class _RecentlyBoughtSectionState extends ConsumerState<RecentlyBoughtSection> {
  static const Duration _autoAdvanceInterval = Duration(milliseconds: 3500);
  static const Duration _resumeAfterTouch = Duration(seconds: 4);

  final PageController _controller = PageController(viewportFraction: 0.86);
  Timer? _timer;
  bool _userInteracting = false;
  int _currentPage = 0;
  List<RecentPurchaseEntry> _tracked = const [];

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!_userInteracting && _tracked.length > 1) {
      _timer = Timer.periodic(_autoAdvanceInterval, (_) {
        if (!mounted || !_controller.hasClients) return;
        final next = (_currentPage + 1) % _tracked.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  void _handleInteractionStart() {
    if (!_userInteracting) {
      setState(() => _userInteracting = true);
      _timer?.cancel();
    }
  }

  void _handleInteractionEnd() {
    // Resume auto-advance after a short delay so the user can finish
    // reading the card they were inspecting.
    Future.delayed(_resumeAfterTouch, () {
      if (!mounted) return;
      setState(() => _userInteracting = false);
      _restartTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(recentPurchasesProvider);
    final cs = Theme.of(context).colorScheme;

    // Hide the section entirely if the buyer has no purchases yet —
    // a placeholder would only add noise to the dashboard.
    if (entries.isEmpty) return const SizedBox.shrink();

    // If the order list shrank (e.g. the user just cancelled their
    // last order), keep the controller in sync so the next rebuild
    // doesn't index past the end.
    if (entries.length != _tracked.length) {
      _tracked = entries;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        if (_currentPage >= _tracked.length) {
          _controller.jumpToPage(0);
          setState(() => _currentPage = 0);
        }
        _restartTimer();
      });
    } else {
      _tracked = entries;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 196,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is UserScrollNotification) {
                if (n.direction != ScrollDirection.idle) {
                  _handleInteractionStart();
                } else {
                  _handleInteractionEnd();
                }
              }
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              physics: const BouncingScrollPhysics(),
              padEnds: true,
              onPageChanged: (i) {
                setState(() => _currentPage = i);
                // Treat the page-settle as the end of an interaction
                // so the timer resumes 4s later.
                _handleInteractionEnd();
              },
              itemCount: entries.length,
              itemBuilder: (context, i) => _RecentPurchaseCard(
                entry: entries[i],
                onTap: () => widget.onTap(entries[i].order.listingId),
                l10n: widget.l10n,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.paddingSM),
        // Page indicator — small dots, active one uses primary.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < entries.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: i == _currentPage ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _currentPage
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RecentPurchaseCard extends StatelessWidget {
  final RecentPurchaseEntry entry;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  const _RecentPurchaseCard({
    required this.entry,
    required this.onTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = BackgroundStyle.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = entry.imageUrl;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingXS,
        vertical: AppSizes.paddingXS,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          child: Ink(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusLG),
              border: Border.all(color: tokens.border, width: 0.6),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? cs.shadow.withValues(alpha: 0.40)
                      : cs.shadow.withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingSM),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // `double.infinity` here would resolve to 0 inside a
                  // Row that hasn't been given a finite cross-axis
                  // size, collapsing the image to a sliver. Pin the
                  // thumbnail to a fixed height and let `Row.stretch`
                  // (above) keep the rest of the card aligned to it.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                    child: SizedBox(
                      width: 120,
                      height: 156,
                      child: imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              fadeInDuration:
                                  const Duration(milliseconds: 220),
                              placeholder: (_, __) => _imgFallback(context),
                              errorWidget: (_, __, ___) =>
                                  _imgFallback(context),
                            )
                          : _imgFallback(context),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.secondary.withValues(alpha: 0.14),
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusSM),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.history_rounded,
                                    size: 11,
                                    color: cs.secondary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    l10n.recentlyBoughtChip,
                                    style: TextStyle(
                                      color: cs.secondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.displayName(l10n),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entry.formattedQuantity} · ${entry.formattedPrice}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.70),
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          Formatters.formatRelativeTime(entry.order.createdAt),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.55),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imgFallback(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: BackgroundStyle.of(context).surfaceAlt,
      child: Icon(
        Icons.set_meal_rounded,
        color: cs.onSurface.withValues(alpha: 0.45),
        size: 32,
      ),
    );
  }
}
