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
// Light and Dark. The status pills (success green / grey) keep their
// semantic colours — those are not backgrounds, they are accent dots.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/theme_extensions.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../features/map/utils/gps_helper.dart';
import '../../models/street_seller_model.dart';
import '../common/premium_components.dart';

/// Modal sheet showing a seller's full profile. Open via the static
/// [SellerProfileSheet.show] helper from anywhere that has a
/// `BuildContext` and a `StreetSellerModel`.
class SellerProfileSheet extends StatelessWidget {
  final StreetSellerModel seller;
  final double? buyerLatitude;
  final double? buyerLongitude;
  final VoidCallback? onSendRequest;

  const SellerProfileSheet({
    super.key,
    required this.seller,
    this.buyerLatitude,
    this.buyerLongitude,
    this.onSendRequest,
  });

  /// Show the seller profile as a modal bottom sheet. Designed to be
  /// called from `BuyerMapScreen.onSellerTap`.
  static Future<void> show(
    BuildContext context, {
    required StreetSellerModel seller,
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
                    _TrustSignals(seller: seller),
                    const SizedBox(height: AppSizes.paddingLG),
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
                      AppColors.successGreen.withValues(alpha: 0.22),
                      AppColors.primaryBlue.withValues(alpha: 0.18),
                    ]
                  : [
                      AppColors.darkNavy900,
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
                          const Tooltip(
                            message: 'Verified seller',
                            child: Icon(
                              Icons.verified_rounded,
                              size: 18,
                              color: AppColors.primaryBlue,
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
    const palette = [
      AppColors.primaryBlue,
      AppColors.secondaryTeal,
      AppColors.accentOrange,
      AppColors.successGreen,
      AppColors.infoBlue,
      AppColors.warningAmber,
    ];
    final hash = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    return palette[hash % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final url = seller.profilePictureUrl;
    final tokens = BackgroundStyle.of(context);
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
            color: Colors.black.withValues(alpha: 0.18),
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
        DateTime.now().difference(lastFix) <
            const Duration(minutes: 5);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    if (isFresh) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingXS,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.successGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSizes.radiusSM),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.successGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSizes.paddingXS),
            Text(
              'Online · live location',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.successGreen,
                fontWeight: FontWeight.w700,
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
            decoration: const BoxDecoration(
              color: AppColors.gray500,
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

/// Phone + SMS action row. Both copy the number to the clipboard
/// so the buyer can paste into their dialer / messaging app.
class _ContactStrip extends StatelessWidget {
  final StreetSellerModel seller;
  const _ContactStrip({required this.seller});

  void _copyToClipboard(
    BuildContext context,
    String text, {
    required String message,
  }) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ContactTile(
            icon: Icons.phone_rounded,
            label: 'Call',
            value: seller.phoneNumber,
            color: AppColors.successGreen,
            onTap: () => _copyToClipboard(context, seller.phoneNumber,
                message: 'Phone number copied — paste into your dialer'),
          ),
        ),
        const SizedBox(width: AppSizes.paddingMD),
        Expanded(
          child: _ContactTile(
            icon: Icons.sms_rounded,
            label: 'SMS',
            value: seller.phoneNumber,
            color: AppColors.primaryBlue,
            onTap: () => _copyToClipboard(context, seller.phoneNumber,
                message: 'Phone number copied — paste into your messaging app'),
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
class _LocationCard extends StatelessWidget {
  final StreetSellerModel seller;
  final double? distanceKm;
  const _LocationCard({required this.seller, required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return PremiumCard(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 18,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 6),
              Text(
                'LOCATION',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              if (distanceKm != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingXS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                  ),
                  child: Text(
                    '${distanceKm!.toStringAsFixed(1)} km away',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSM),
          _LocationRow(
            icon: Icons.store_mall_directory_outlined,
            label: 'Market',
            value: seller.marketName ?? 'Unknown market',
          ),
          _LocationRow(
            icon: Icons.map_outlined,
            label: 'Region',
            value: seller.regionName ?? 'Zanzibar',
          ),
          _LocationRow(
            icon: Icons.signpost_outlined,
            label: 'Street',
            value: seller.streetName ?? '—',
          ),
          _LocationRow(
            icon: Icons.my_location_rounded,
            label: 'Coordinates',
            value:
                '${seller.latitude.toStringAsFixed(5)}, ${seller.longitude.toStringAsFixed(5)}',
            monospace: true,
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool monospace;

  const _LocationRow({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 16, color: cs.onSurface.withValues(alpha: 0.55)),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: monospace ? 'monospace' : null,
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

/// Rating + ratings count + total orders + verified badge.
class _TrustSignals extends StatelessWidget {
  final StreetSellerModel seller;
  const _TrustSignals({required this.seller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TrustTile(
            icon: Icons.star_rounded,
            iconColor: AppColors.warningAmber,
            label: 'Rating',
            value: seller.totalRatings == 0
                ? '—'
                : seller.averageRating.toStringAsFixed(1),
            subtitle: seller.totalRatings == 0
                ? 'No ratings yet'
                : '${seller.totalRatings} reviews',
          ),
        ),
        const SizedBox(width: AppSizes.paddingSM),
        Expanded(
          child: _TrustTile(
            icon: Icons.shopping_bag_rounded,
            iconColor: AppColors.primaryBlue,
            label: 'Orders',
            value: '${seller.totalOrders}',
            subtitle: 'Completed',
          ),
        ),
        const SizedBox(width: AppSizes.paddingSM),
        Expanded(
          child: _TrustTile(
            icon: seller.isVerified
                ? Icons.verified_rounded
                : Icons.verified_outlined,
            iconColor: seller.isVerified
                ? AppColors.successGreen
                : AppColors.gray500,
            label: 'Status',
            value: seller.isVerified ? 'Verified' : 'Pending',
            subtitle: seller.isVerified ? 'Admin approved' : 'In review',
          ),
        ),
      ],
    );
  }
}

class _TrustTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;

  const _TrustTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingSM),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        border: Border.all(color: iconColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w700,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: iconColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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