import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/route_paths.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/cards/fish_listing_card.dart';
import '../../widgets/common/common_widgets.dart';

class FishListingsScreen extends ConsumerWidget {
  const FishListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(activeListingsProvider);
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.marketplace),
        elevation: 0,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // ref.invalidate re-subscribes the StreamProvider so the
          // screen re-renders with a fresh snapshot. Await one frame
          // so the spinner has time to appear.
          ref.invalidate(activeListingsProvider);
          await Future<void>.delayed(const Duration(milliseconds: 400));
        },
        child: listingsAsync.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: 320,
                child: LoadingIndicator(message: l10n.loadingFreshCatch),
              ),
            ],
          ),
          error: (error, stack) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.paddingLG),
            children: [
              SizedBox(
                height: 320,
                child: EmptyStateWidget(
                  icon: Icons.error_outline,
                  title: l10n.failedToLoadListings,
                  subtitle: _describeListingError(error),
                  onRetry: () => ref.invalidate(activeListingsProvider),
                ),
              ),
              // Debug panel — shows the raw exception so a user can
              // copy the Firestore index URL or permission rule that
              // is blocking the read. Only visible when an error is
              // being rendered; otherwise the empty/data branches
              // take over and this card scrolls off-screen.
              Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingLG,
                  vertical: AppSizes.paddingMD,
                ),
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMD),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bug_report_rounded,
                              size: 18, color: Colors.brown.shade700),
                          const SizedBox(width: 6),
                          Text(
                            'Debug detail',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.brown.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        error.toString(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          data: (listings) {
            if (listings.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSizes.paddingLG),
                children: [
                  SizedBox(
                    height: 320,
                    child: EmptyStateWidget(
                      icon: Icons.set_meal_outlined,
                      title: l10n.noFishAvailable,
                      subtitle: l10n.checkBackLater,
                      onRetry: () => ref.invalidate(activeListingsProvider),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.paddingLG),
              itemCount: listings.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSizes.paddingMD),
              itemBuilder: (context, index) {
                final listing = listings[index];
                return FishListingCard(
                  listing: listing,
                  onTap: () => context.pushNamed(
                    AppRouteNames.listingDetail,
                    pathParameters: {'id': listing.listingId},
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Translates the raw Firestore exception into a human-readable
  /// hint. The full error string is appended (truncated) so admins
  /// can still see the index URL or permission rule when needed.
  static String _describeListingError(Object error) {
    final raw = error.toString();
    final short = raw.length > 200 ? '${raw.substring(0, 200)}…' : raw;
    if (raw.contains('failed-precondition')) {
      return 'Missing Firestore index — the data is loading fine but '
          'Firestore refused the query. $short';
    }
    if (raw.contains('permission-denied')) {
      return 'Your account is not allowed to read this collection. '
          '$short';
    }
    if (raw.contains('unavailable')) {
      return 'Network unavailable — check your connection and retry. '
          '$short';
    }
    return short;
  }
}