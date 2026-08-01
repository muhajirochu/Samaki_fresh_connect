// Full seller profile sheet — opens when the buyer taps a marker on
// the buyer map. Shows every piece of seller data we have:
//   - Profile picture (or initials avatar if no URL),
//   - Full name,
//   - Verified badge,
//   - Online status + last fix timestamp,
//   - Market + region + street,
//   - Coordinates (with copy-to-clipboard),
//   - Phone number (with copy-to-clipboard),
//   - Trust signals: rating, total ratings, total orders,
//   - Action row: "Send fish request".
//
// Theme: the sheet surface, the avatar ring, the location card, and the
// trust tiles all read colours from `Theme.of(context).colorScheme` and
// `BackgroundStyle.of(context)` so the sheet renders correctly in both
// Light and Dark. The status pills (success / warning / info tokens) are
// semantic accents — they're meant to read the same across themes.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme_extensions.dart';
import '../../constants/app_sizes.dart';
import '../../utils/gps_helper.dart';
import '../../services/listing_location_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/fish_item_model.dart';
import '../../models/street_seller_model.dart';
import '../common/premium_components.dart';

// Semantic palette used by the avatar tint + trust tiles. These
// colours are NOT theme tokens — they're identifier hues that stay
// constant so users can recognise sellers and statuses at a glance.
// They're declared here at the call-site because they're only used in
// this widget and are not part of the brand palette.
const _avatarPalette = <Color>[
  Color(0xFF2563EB), // Modern Blue (matches brand seed)
  Color(0xFF14B8A6), // Teal Green
  Color(0xFFF59E0B), // Amber
  Color(0xFF16A34A), // Elegant Green
  Color(0xFF3B82F6), // Bright Blue
  Color(0xFFEF4444), // Red (warning/alert)
];

/// Modal sheet showing a seller's full profile. Open via the static
/// [SellerProfileSheet.show] helper from anywhere that has a
/// `BuildContext` and a `StreetSellerModel`.
class SellerProfileSheet extends StatelessWidget {
  final StreetSellerModel seller;
  final List<FishItemModel> fishItems;
  final double? buyerLatitude;
  final double? buyerLongitude;
  final VoidCallback? onSendRequest;

  const SellerProfileSheet({
    super.key,
    required this.seller,
    this.fishItems = const [],
    this.buyerLatitude,
    this.buyerLongitude,
    this.onSendRequest,
  });

  /// Show the seller profile as a modal bottom sheet. Designed to be
  /// called from `BuyerMapScreen.onSellerTap`.
  static Future<void> show(
    BuildContext context, {
    required StreetSellerModel seller,
    List<FishItemModel> fishItems = const [],
    double? buyerLatitude,
    double? buyerLongitude,
    VoidCallback? onSendRequest,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => SellerProfileSheet(
        seller: seller,
        fishItems: fishItems,
        buyerLatitude: buyerLatitude,
        buyerLongitude: buyerLongitude,
        onSendRequest: onSendRequest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = BackgroundStyle.of(context);
    final distanceKm = (buyerLatitude != null && buyerLongitude != null)
        ? seller.distanceKmFrom(buyerLatitude!, buyerLongitude!)
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.4,
      maxChildSize: 0.98,
      expand: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXL),
            ),
            border: Border(
              top: BorderSide(color: tokens.border, width: 0.6),
            ),
          ),
          child: Column(
            children: [
              _DragHandle(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingLG,
                    0,
                    AppSizes.paddingLG,
                    AppSizes.paddingXL,
                  ),
                  children: [
                    _ProfileHeader(seller: seller),
                    const SizedBox(height: AppSizes.paddingLG),
                    _ContactStrip(seller: seller),
                    const SizedBox(height: AppSizes.paddingLG),
                    _LocationCard(
                      seller: seller,
                      distanceKm: distanceKm,
                    ),
                    const SizedBox(height: AppSizes.paddingLG),
                    if (fishItems.isNotEmpty) ...[
                      _SellerFishGallery(fishItems: fishItems),
                      const SizedBox(height: AppSizes.paddingLG),
                    ],
                    _ActionRow(onSendRequest: onSendRequest),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = BackgroundStyle.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSM),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: tokens.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// Top section — large avatar + name + verified badge.
class _ProfileHeader extends StatelessWidget {
  final StreetSellerModel seller;
  const _ProfileHeader({required this.seller});

  @override
  Widget build(BuildContext context) {
    final tokens = BackgroundStyle.of(context);
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        // Cover banner tinted by online status — uses deep-navy hero
        // gradient (brand surface, acceptable per spec) for offline
        // sellers, and a green→blue live tint for online ones.
        Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: seller.isOnline
                  ? [
                      _avatarPalette[3].withValues(alpha: 0.22), // elegant green
                      _avatarPalette[0].withValues(alpha: 0.18), // modern blue
                    ]
                  : [
                      _avatarPalette[0], // deep navy in dark mode, brand in light
                      cs.surfaceContainerHighest,
                    ],
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusLG),
            border: Border.all(color: tokens.border, width: 0.6),
          ),
        ),
        // Avatar + identity row.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingMD,
            24, // sits over the banner
            AppSizes.paddingMD,
            0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _SellerAvatar(
                seller: seller,
                size: 72,
              ),
              const SizedBox(width: AppSizes.paddingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            seller.fullName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (seller.isVerified) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'Verified seller',
                            child: Icon(
                              Icons.verified_rounded,
                              size: 18,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    _OnlineStatusPill(seller: seller),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Avatar — uses the cached_network_image if a URL is available,
/// falls back to a tinted initials chip when not.
class _SellerAvatar extends StatelessWidget {
  final StreetSellerModel seller;
  final double size;
  const _SellerAvatar({required this.seller, this.size = 72});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Color _tintFor(String seed) {
    // Stable colour per seller so the same seller always renders the
    // same avatar tint even before the network image arrives.
    final hash = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    return _avatarPalette[hash % _avatarPalette.length];
  }

  @override
  Widget build(BuildContext context) {
    final url = seller.profilePictureUrl;
    final tokens = BackgroundStyle.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _tintFor(seller.sellerId).withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(
          color: tokens.surface,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            // Theme-aware shadow for the avatar ring.
            color: cs.shadow.withValues(alpha: 0.32),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: (url == null || url.isEmpty)
            ? Center(
                child: Text(
                  _initials(seller.fullName),
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.w800,
                    color: _tintFor(seller.sellerId),
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _tintFor(seller.sellerId),
                  ),
                ),
                errorWidget: (_, __, ___) => Center(
                  child: Text(
                    _initials(seller.fullName),
                    style: TextStyle(
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.w800,
                      color: _tintFor(seller.sellerId),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Green / grey pill showing live-presence.
class _OnlineStatusPill extends StatelessWidget {
  final StreetSellerModel seller;
  const _OnlineStatusPill({required this.seller});

  @override
  Widget build(BuildContext context) {
    final lastFix = seller.lastLocationUpdateAt;
    final isFresh = seller.isOnline &&
        lastFix != null &&
        DateTime.now().difference(lastFix) < const Duration(minutes: 5);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    if (isFresh) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingXS,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          // Live-status uses the secondary (Elegant Green) so it
          // matches the "online" semantic across buyer/seller screens.
          color: cs.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSizes.radiusSM),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: cs.secondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSizes.paddingXS),
            Flexible(
              child: Text(
                'Online · live location',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (lastFix == null && !seller.isOnline) {
      return Text(
        'Street seller · Zanzibar',
        style: theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurface.withValues(alpha: 0.65),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingXS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSizes.paddingXS),
          Text(
            lastFix == null
                ? 'Offline'
                : 'Last seen ${GpsHelper.formatRelativeTime(lastFix)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Phone + SMS action row. Both launch the appropriate platform app and
/// fall back to copying the number when a launch is unavailable.
class _ContactStrip extends StatelessWidget {
  final StreetSellerModel seller;
  const _ContactStrip({required this.seller});

  void _copyToClipboard(
    BuildContext context,
    String text, {
    required String message,
  }) {
    Clipboard.setData(ClipboardData(text: text));
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: cs.secondary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _callSeller(BuildContext context, String phoneNumber) async {
    try {
      final launched = await launchUrl(Uri(scheme: 'tel', path: phoneNumber));
      if (!launched && context.mounted) {
        final l10n = Localizations.of<AppLocalizations>(
          context,
          AppLocalizations,
        );
        _copyToClipboard(
          context,
          phoneNumber,
          message: l10n?.callFailed ??
              'Phone number copied — paste into your dialer',
        );
      }
    } catch (_) {
      if (context.mounted) {
        final l10n = Localizations.of<AppLocalizations>(
          context,
          AppLocalizations,
        );
        _copyToClipboard(
          context,
          phoneNumber,
          message: l10n?.callFailed ??
              'Phone number copied — paste into your dialer',
        );
      }
    }
  }

  Future<void> _smsSeller(BuildContext context, String phoneNumber) async {
    try {
      final launched = await launchUrl(Uri(scheme: 'sms', path: phoneNumber));
      if (!launched && context.mounted) {
        final l10n = Localizations.of<AppLocalizations>(
          context,
          AppLocalizations,
        );
        _copyToClipboard(
          context,
          phoneNumber,
          message: l10n?.smsFailed ??
              'Phone number copied — paste into your messaging app',
        );
      }
    } catch (_) {
      if (context.mounted) {
        final l10n = Localizations.of<AppLocalizations>(
          context,
          AppLocalizations,
        );
        _copyToClipboard(
          context,
          phoneNumber,
          message: l10n?.smsFailed ??
              'Phone number copied — paste into your messaging app',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _ContactTile(
            icon: Icons.phone_rounded,
            label: 'Call',
            value: seller.phoneNumber,
            color: cs.secondary,
            onTap: () => _callSeller(context, seller.phoneNumber),
          ),
        ),
        const SizedBox(width: AppSizes.paddingMD),
        Expanded(
          child: _ContactTile(
            icon: Icons.sms_rounded,
            label: 'SMS',
            value: seller.phoneNumber,
            color: cs.primary,
            onTap: () => _smsSeller(context, seller.phoneNumber),
          ),
        ),
      ],
    );
  }
}

/// Tile with an icon + label + value, tap to copy / dial.
class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: AppSizes.paddingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Market + region + street + lat/lng tile.
class _LocationCard extends StatefulWidget {
  final StreetSellerModel seller;
  final double? distanceKm;
  const _LocationCard({required this.seller, required this.distanceKm});

  @override
  State<_LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<_LocationCard> {
  Future<String?>? _addressFuture;
  late double _lat;
  late double _lng;

  @override
  void initState() {
    super.initState();
    _initFuture();
  }

  void _initFuture() {
    _lat = widget.seller.latitude;
    _lng = widget.seller.longitude;
    if (widget.seller.isOnline) {
      _addressFuture = ListingLocationService().reverseGeocodeLabel(_lat, _lng);
    }
  }

  @override
  void didUpdateWidget(_LocationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seller.isOnline &&
        (widget.seller.latitude != _lat || widget.seller.longitude != _lng)) {
      _initFuture();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isMobile = widget.seller.isOnline;

    // speed in m/s to km/h (1 m/s = 3.6 km/h)
    final speedKmh = (widget.seller.speedMps ?? 0) * 3.6;
    final isMoving = speedKmh > 3.0;

    return PremiumCard(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isMobile ? Icons.explore_rounded : Icons.location_on_rounded,
                size: 18,
                color: cs.primary,
              ),
              const SizedBox(width: 6),
              Text(
                isMobile ? 'LIVE LOCATION' : 'REGISTERED BASE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              if (widget.distanceKm != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingXS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                  ),
                  child: Text(
                    '${widget.distanceKm!.toStringAsFixed(1)} km away',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSM),
          
          if (isMobile) ...[
            FutureBuilder<String?>(
              future: _addressFuture,
              builder: (context, snapshot) {
                final address = snapshot.data;
                return _LocationRow(
                  icon: Icons.streetview_rounded,
                  label: 'Address',
                  value: snapshot.connectionState == ConnectionState.waiting
                      ? 'Resolving...'
                      : (address ?? 'Unknown Location'),
                );
              },
            ),
            if (isMoving)
              _LocationRow(
                icon: Icons.pedal_bike_rounded,
                label: 'Status',
                value: 'On the move (${speedKmh.toStringAsFixed(1)} km/h)',
              ),
          ] else ...[
            _LocationRow(
              icon: Icons.store_mall_directory_outlined,
              label: 'Market',
              value: widget.seller.marketName ?? 'Unknown market',
            ),
            _LocationRow(
              icon: Icons.map_outlined,
              label: 'Region',
              value: widget.seller.regionName ?? 'Zanzibar',
            ),
            _LocationRow(
              icon: Icons.signpost_outlined,
              label: 'Street',
              value: widget.seller.streetName ?? '—',
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _LocationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withValues(alpha: 0.55)),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerFishGallery extends StatelessWidget {
  final List<FishItemModel> fishItems;
  const _SellerFishGallery({required this.fishItems});

  @override
  Widget build(BuildContext context) {
    if (fishItems.isEmpty) return const SizedBox.shrink();
    
    // We want to extract all image URLs from the fish items.
    final itemsWithImages = fishItems.where((item) => item.imageUrls.isNotEmpty).toList();
    if (itemsWithImages.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Samaki Wanaopatikana',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSizes.paddingMD),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: itemsWithImages.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSizes.paddingSM),
            itemBuilder: (context, index) {
              final item = itemsWithImages[index];
              return Container(
                width: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                  border: Border.all(
                    color: cs.outline.withValues(alpha: 0.15),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: item.imageUrls.first,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: cs.surfaceContainerHighest,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: cs.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                        ),
                      ),
                      // Gradient overlay for text readability
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        height: 60,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Text
                      Positioned(
                        bottom: 8, left: 8, right: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${item.quantityKg.toStringAsFixed(1)} kg',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Bottom action row — "Send fish request".
class _ActionRow extends StatelessWidget {
  final VoidCallback? onSendRequest;
  const _ActionRow({this.onSendRequest});

  @override
  Widget build(BuildContext context) {
    final canRequest = onSendRequest != null;
    return SizedBox(
      width: double.infinity,
      child: GradientButton(
        label: 'Tuma Ombi la Samaki',
        onPressed: canRequest ? onSendRequest : null,
        prefixIcon: Icons.send_rounded,
      ),
    );
  }
}
