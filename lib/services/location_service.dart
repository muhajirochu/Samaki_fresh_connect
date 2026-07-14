// Device location lookup. Wraps `geolocator` so the rest of the app
// doesn't have to know about platform permissions, error codes, or
// service-disabled fallbacks.
//
// Resolution order for the buyer's coordinates:
//   1. Live GPS fix (geolocator).
//   2. The buyer's saved `location` field on the user doc (Zanzibar
//      centroid as a last-resort default so the map always renders).

import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/user_model.dart';
import '../utils/logger.dart';
import '../providers/buyer_provider.dart';

class BuyerLocation {
  final double latitude;
  final double longitude;
  final String source; // 'gps' | 'profile' | 'fallback'
  final double? accuracyMeters;

  const BuyerLocation({
    required this.latitude,
    required this.longitude,
    required this.source,
    this.accuracyMeters,
  });
}

class LocationService {
  /// Zanzibar (Stone Town) — used only when both GPS and the profile fail.
  static const BuyerLocation _fallback = BuyerLocation(
    latitude: -6.1629,
    longitude: 39.2026,
    source: 'fallback',
  );

  /// Returns the buyer's best-known coordinates. Never throws; always
  /// returns *something* renderable on the map. Callers should still show
  /// the source label so the buyer knows whether the dot on screen is a
  /// live fix or a saved approximation.
  Future<BuyerLocation> getCurrentOrFallback({
    required UserModel? buyer,
  }) async {
    // 1. Live GPS — only if permission is granted and the service is on.
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 8),
          );
          return BuyerLocation(
            latitude: pos.latitude,
            longitude: pos.longitude,
            source: 'gps',
            accuracyMeters: pos.accuracy,
          );
        }
      }
    } catch (e) {
      AppLogger.warning('GPS lookup failed, falling back: $e');
    }

    // 2. Saved profile location.
    final loc = buyer?.location;
    if (loc != null && loc['latitude'] is num && loc['longitude'] is num) {
      return BuyerLocation(
        latitude: (loc['latitude'] as num).toDouble(),
        longitude: (loc['longitude'] as num).toDouble(),
        source: 'profile',
      );
    }

    // 3. Last-resort: Stone Town.
    return _fallback;
  }

  /// Prompt the user to grant the permission. Returns true on grant.
  /// Useful from a "Tap to enable location" CTA.
  Future<bool> requestPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }
}

// ── Riverpod provider ─────────────────────────────────────────────────────────

/// Stream of the current buyer's coordinates. Recomputes whenever the
/// buyer's profile changes (location field updated) or the screen
/// re-watches it. The GPS lookup is a one-shot Future — for a live feed
/// you'd want Geolocator.getPositionStream(); Phase 2 doesn't need it.
final currentBuyerLocationProvider =
    FutureProvider<BuyerLocation>((ref) async {
  final session = ref.watch(currentBuyerSessionProvider);
  final service = ref.watch(locationServiceProvider);
  return service.getCurrentOrFallback(buyer: session?.user);
});

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);
