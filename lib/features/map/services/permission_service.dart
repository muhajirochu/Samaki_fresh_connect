import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../constants/map_constants.dart';
import '../../../utils/logger.dart';

/// The four discrete outcomes of "can I get the device's location right now?".
///
/// The service exposes both an enum-style result ([LocationPermissionState])
/// for the provider and a sealed class ([PermissionCheckResult]) so the
/// caller can pattern-match exhaustively.
enum LocationPermissionState {
  /// The user (or the system) has granted location access.
  granted,

  /// The user denied the in-app prompt. The OS may show the prompt again
  /// on the next request.
  denied,

  /// The user denied twice or checked "Don't ask again". They have to go
  /// to the system settings to re-enable.
  permanentlyDenied,

  /// The OS reports the GPS hardware is off, regardless of app permission.
  serviceDisabled,
}

/// Sealed result returned by [PermissionService.checkCurrentState] and
/// [PermissionService.requestLocationPermission]. Lets the provider branch
/// on a known set of cases without inspecting strings.
sealed class PermissionCheckResult {
  const PermissionCheckResult();
}

class PermissionGranted extends PermissionCheckResult {
  const PermissionGranted();
}

class PermissionDenied extends PermissionCheckResult {
  const PermissionDenied();
}

class PermissionPermanentlyDenied extends PermissionCheckResult {
  const PermissionPermanentlyDenied();
}

class ServiceDisabled extends PermissionCheckResult {
  const ServiceDisabled();
}

/// Bridges between the OS (geolocator + permission_handler) and the Map
/// feature. The service is the **only** place that calls `geolocator` /
/// `permission_handler` directly.
///
/// All public methods are safe to call from a test — they don't touch
/// `BuildContext` or `showDialog`. Dialogs are shown by the screen.
class PermissionService {
  const PermissionService();

  /// Returns the current permission + service state **without** prompting
  /// the user. Useful as a first read at app start.
  Future<PermissionCheckResult> checkCurrentState() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const ServiceDisabled();
      }

      final permission = await Geolocator.checkPermission();
      return _mapGeolocatorPermission(permission);
    } catch (e, st) {
      AppLogger.error('PermissionService.checkCurrentState failed', e, st);
      return const PermissionDenied();
    }
  }

  /// If the permission is not yet granted, prompts the user. If the user
  /// has already permanently denied, returns [PermissionPermanentlyDenied]
  /// without prompting.
  Future<PermissionCheckResult> requestLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const ServiceDisabled();
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return _mapGeolocatorPermission(permission);
    } catch (e, st) {
      AppLogger.error(
        'PermissionService.requestLocationPermission failed',
        e,
        st,
      );
      return const PermissionDenied();
    }
  }

  /// Opens the app's system-settings page so the user can re-enable a
  /// permanently denied permission. Returns `true` if the settings app was
  /// opened.
  Future<bool> openAppSettings() async {
    try {
      // Try geolocator first (works on all platforms), fall back to
      // permission_handler for older Android flavors.
      final opened = await Geolocator.openAppSettings();
      if (opened) return true;
      return await ph.openAppSettings();
    } catch (e) {
      AppLogger.error('openAppSettings failed', e);
      return false;
    }
  }

  /// Opens the device's location-services settings (so the user can turn
  /// GPS on). Best-effort; on iOS this opens the app's settings if the
  /// global location settings page is unavailable.
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      AppLogger.warning('openLocationSettings failed, falling back', e);
      await openAppSettings();
    }
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────
  // Dialogs are kept here for cohesion: they all relate to the same
  // permission states the service knows about. The dialogs don't take a
  // [BuildContext] via the provider — the screen passes its own context
  // when it decides to show one.

  /// Dialog shown when GPS hardware is off.
  Future<void> showGpsDisabledDialog(
    BuildContext context, {
    required VoidCallback onEnable,
  }) async {
    await _showDialog(
      context: context,
      icon: Icons.location_off_rounded,
      iconColor: AppColors.errorRed,
      title: 'GPS Disabled',
      message:
          'Location services are disabled on your device. Please turn on '
          'GPS so we can show your position on the map.',
      primaryLabel: MapConstants.actionEnableGps,
      onPrimary: onEnable,
    );
  }

  /// Dialog shown when the user has just denied the permission once.
  Future<void> showPermissionDeniedDialog(
    BuildContext context, {
    required VoidCallback onGrant,
  }) async {
    await _showDialog(
      context: context,
      icon: Icons.gpp_bad_rounded,
      iconColor: AppColors.warningAmber,
      title: 'Location Permission Needed',
      message:
          'Fresh Connect uses your location to center the map and to '
          'find nearby fish markets. Please allow location access.',
      primaryLabel: MapConstants.actionGrantPermission,
      onPrimary: onGrant,
    );
  }

  /// Dialog shown when the user has permanently denied the permission.
  Future<void> showPermissionPermanentlyDeniedDialog(
    BuildContext context, {
    required VoidCallback onOpenSettings,
  }) async {
    await _showDialog(
      context: context,
      icon: Icons.settings_suggest_rounded,
      iconColor: AppColors.errorRed,
      title: 'Permission Blocked',
      message:
          'Location permission is permanently denied. Open the app '
          'settings and enable Location to continue.',
      primaryLabel: MapConstants.actionOpenSettings,
      onPrimary: onOpenSettings,
    );
  }

  Future<void> _showDialog({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String primaryLabel,
    required VoidCallback onPrimary,
  }) async {
    final theme = Theme.of(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          ),
          title: Row(
            children: [
              Icon(icon, color: iconColor, size: AppSizes.iconMD),
              const SizedBox(width: AppSizes.paddingSM),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
          content: Text(message, style: theme.textTheme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                MapConstants.actionCancel,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onPrimary();
              },
              child: Text(primaryLabel),
            ),
          ],
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  PermissionCheckResult _mapGeolocatorPermission(LocationPermission p) {
    switch (p) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return const PermissionGranted();
      case LocationPermission.denied:
        return const PermissionDenied();
      case LocationPermission.deniedForever:
      case LocationPermission.unableToDetermine:
        return const PermissionPermanentlyDenied();
    }
  }
}
