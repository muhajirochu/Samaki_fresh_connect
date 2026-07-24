import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/fish_listing_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';

class BuyerSellerTrackingScreen extends ConsumerStatefulWidget {
  final String sellerId;

  const BuyerSellerTrackingScreen({super.key, required this.sellerId});

  @override
  ConsumerState<BuyerSellerTrackingScreen> createState() =>
      _BuyerSellerTrackingScreenState();
}

class _BuyerSellerTrackingScreenState
    extends ConsumerState<BuyerSellerTrackingScreen> {
  Future<void> _copyPhoneNumber(String phoneNumber, String message) async {
    await Clipboard.setData(ClipboardData(text: phoneNumber));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _launchContact(
    String scheme,
    String phoneNumber,
    String fallbackMessage,
  ) async {
    try {
      final launched = await launchUrl(Uri(scheme: scheme, path: phoneNumber));
      if (!launched) {
        await _copyPhoneNumber(phoneNumber, fallbackMessage);
      }
    } catch (_) {
      await _copyPhoneNumber(phoneNumber, fallbackMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sellerAsync = ref.watch(userModelStreamProvider(widget.sellerId));
    final listingsAsync = ref.watch(sellerListingsProvider(widget.sellerId));

    return Scaffold(
      appBar: AppBar(
        title: Text(sellerAsync.valueOrNull?.fullName ?? l10n.trackSeller),
        actions: [
          if (sellerAsync.valueOrNull case final seller?) ...[
            IconButton(
              tooltip: l10n.callSeller,
              icon: const Icon(Icons.phone_rounded),
              onPressed: () => _launchContact(
                'tel',
                seller.phoneNumber,
                l10n.callFailed,
              ),
            ),
            IconButton(
              tooltip: l10n.smsSeller,
              icon: const Icon(Icons.sms_rounded),
              onPressed: () => _launchContact(
                'sms',
                seller.phoneNumber,
                l10n.smsFailed,
              ),
            ),
          ],
        ],
      ),
      body: sellerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(l10n.loadingError(error.toString()))),
        data: (seller) {
          if (seller == null) {
            return Center(child: Text(l10n.noDataYet));
          }
          return _SellerTrackingBody(
            seller: seller,
            listingsAsync: listingsAsync,
            onCall: () => _launchContact(
              'tel',
              seller.phoneNumber,
              l10n.callFailed,
            ),
            onSms: () => _launchContact(
              'sms',
              seller.phoneNumber,
              l10n.smsFailed,
            ),
          );
        },
      ),
    );
  }
}

class _SellerTrackingBody extends StatelessWidget {
  final UserModel seller;
  final AsyncValue<List<FishListingModel>> listingsAsync;
  final VoidCallback onCall;
  final VoidCallback onSms;

  const _SellerTrackingBody({
    required this.seller,
    required this.listingsAsync,
    required this.onCall,
    required this.onSms,
  });

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  String _sellerLocation(UserModel seller) {
    final location = seller.location;
    if (location == null) return '';
    final values = [
      location['marketName'],
      location['regionName'],
    ].whereType<String>().where((value) => value.trim().isNotEmpty);
    return values.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final location = _sellerLocation(seller);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingLG),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingLG),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _SellerAvatar(
                          name: seller.fullName,
                          imageUrl: seller.profilePictureUrl,
                          initials: _initials(seller.fullName),
                        ),
                        const SizedBox(width: AppSizes.paddingMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                seller.fullName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                seller.phoneNumber,
                                style: theme.textTheme.bodyMedium,
                              ),
                              if (location.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingLG),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onCall,
                            icon: const Icon(Icons.phone_rounded),
                            label: Text(l10n.callSeller),
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingMD),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onSms,
                            icon: const Icon(Icons.sms_rounded),
                            label: Text(l10n.smsSeller),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingLG,
              0,
              AppSizes.paddingLG,
              AppSizes.paddingSM,
            ),
            child: Text(
              l10n.liveFishFromThisSeller,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        listingsAsync.when(
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(l10n.loadingError(error.toString()))),
          ),
          data: (listings) {
            final photos = <_FishPhoto>[];
            for (final listing in listings) {
              // Real listings always have at least one image, but a
              // listing created without a photo still needs a card
              // so the buyer sees something — fall back to a
              // generated placeholder URL so the grid stays full.
              final urls = listing.imageUrls.isNotEmpty
                  ? listing.imageUrls
                  : <String>[_placeholderImageFor(listing.fishType)];
              for (final imageUrl in urls) {
                if (imageUrl.trim().isNotEmpty) {
                  photos.add(_FishPhoto(listing: listing, imageUrl: imageUrl));
                }
              }
            }

            if (photos.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingXL),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 56,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppSizes.paddingSM),
                        Text(
                          l10n.noFishPhotos,
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingLG,
                AppSizes.paddingSM,
                AppSizes.paddingLG,
                AppSizes.paddingXXL,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSizes.paddingSM,
                  mainAxisSpacing: AppSizes.paddingSM,
                  childAspectRatio: 0.9,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _FishPhotoCard(photo: photos[index]),
                  childCount: photos.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Build a deterministic placeholder URL for a listing that has
/// no real photo. Uses an open service (picsum.photos) seeded by
/// the fish type so the tile never drifts to the empty-state and
/// the buyer still sees fish imagery — even when the seller
/// hasn't uploaded a photo yet.
String _placeholderImageFor(String fishType) {
  final cleaned = fishType.trim().isEmpty ? 'fish' : fishType.trim();
  final seed = Uri.encodeComponent(cleaned.toLowerCase());
  return 'https://picsum.photos/seed/$seed/600/600';
}

class _SellerAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String initials;

  const _SellerAvatar({
    required this.name,
    required this.imageUrl,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        initials,
        semanticsLabel: name,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
      ),
    );

    return CircleAvatar(
      radius: 34,
      backgroundColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
      child: ClipOval(
        child: imageUrl == null || imageUrl!.trim().isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                width: 68,
                height: 68,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => fallback,
              ),
      ),
    );
  }
}

class _FishPhoto {
  final FishListingModel listing;
  final String imageUrl;

  const _FishPhoto({required this.listing, required this.imageUrl});
}

class _FishPhotoCard extends StatelessWidget {
  final _FishPhoto photo;

  const _FishPhotoCard({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('${photo.listing.listingId}-${photo.imageUrl}'),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: photo.imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (_, __, ___) => const ColoredBox(
              color: Color(0xFFE6EEF5),
              child: Icon(Icons.broken_image_outlined),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingSM),
              color: Colors.black.withValues(alpha: 0.65),
              child: Text(
                photo.listing.fishType,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
