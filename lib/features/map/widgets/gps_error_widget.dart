import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../constants/map_constants.dart';

/// The discrete failure categories the error widget can render.
///
/// Decoupled from [MapErrorType] in `map_constants.dart` so this widget
/// doesn't take a dependency on the provider's internal error vocabulary —
/// the screen does the mapping.
enum GpsErrorType {
  gpsDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  locationUnavailable,
  network,
  unknown,
}

/// Reusable error widget for any GPS / permission failure.
///
/// Reads colors from the active [Theme] so it renders correctly in dark mode.
class GpsErrorWidget extends StatelessWidget {
  const GpsErrorWidget({
    super.key,
    required this.errorType,
    required this.title,
    required this.description,
    required this.onRetry,
  });

  final GpsErrorType errorType;
  final String title;
  final String description;
  final VoidCallback onRetry;

  IconData get _icon {
    switch (errorType) {
      case GpsErrorType.gpsDisabled:
        return Icons.location_off_rounded;
      case GpsErrorType.permissionDenied:
        return Icons.gpp_bad_rounded;
      case GpsErrorType.permissionPermanentlyDenied:
        return Icons.settings_suggest_rounded;
      case GpsErrorType.locationUnavailable:
        return Icons.gps_off_rounded;
      case GpsErrorType.network:
        return Icons.wifi_off_rounded;
      case GpsErrorType.unknown:
        return Icons.error_outline_rounded;
    }
  }

  Color _iconColor(ColorScheme scheme) {
    switch (errorType) {
      case GpsErrorType.gpsDisabled:
      case GpsErrorType.permissionPermanentlyDenied:
        return AppColors.errorRed;
      case GpsErrorType.permissionDenied:
      case GpsErrorType.locationUnavailable:
        return AppColors.warningAmber;
      case GpsErrorType.network:
        return scheme.tertiary;
      case GpsErrorType.unknown:
        return scheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconColor = _iconColor(scheme);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingXL),
        margin: const EdgeInsets.all(AppSizes.paddingXL),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: iconColor, size: AppSizes.iconXL),
            ),
            const SizedBox(height: AppSizes.paddingLG),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingSM),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingXL),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(MapConstants.actionRetry),
            ),
          ],
        ),
      ),
    );
  }
}