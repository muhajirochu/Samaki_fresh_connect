import 'dart:async';

import '../../../utils/logger.dart';
import '../constants/map_constants.dart';
import '../models/current_location_model.dart';
import '../models/result.dart';
import '../services/geocoding_service.dart';
import '../services/gps_service.dart';
import '../services/permission_service.dart';
import '../utils/gps_helper.dart';

/// Façade the [MapProvider] talks to instead of three services directly.
///
/// Responsibilities:
///   * Read + request permissions (delegates to [PermissionService]).
///   * Read GPS fixes, one-shot and live (delegates to [GpsService]).
///   * Reverse-geocode **with debouncing + dedupe** so we don't burn the
///     geocoding service's quota on every 5-second GPS tick.
class MapRepository {
  MapRepository({
    PermissionService? permissionService,
    GpsService? gpsService,
    GeocodingService? geocodingService,
  })  : _permissionService = permissionService ?? const PermissionService(),
        _gpsService = gpsService ?? const GpsService(),
        _geocodingService = geocodingService ?? const GeocodingService();

  final PermissionService _permissionService;
  final GpsService _gpsService;
  final GeocodingService _geocodingService;

  // ── Geocode cache state ─────────────────────────────────────────────────────
  // We cache the last successful reverse-geocode keyed on its (lat, lng)
  // and the time it was resolved. The cache is bypassed if either:
  //   * the device moved more than `geocodingMinDistanceMeters`, OR
  //   * the cache is older than `geocodingMinInterval`.
  String? _cachedAddress;
  double? _cachedLat;
  double? _cachedLng;
  DateTime? _cachedAt;

  // Exposed for tests; cleared by [dispose] / not strictly needed because
  // the repository is cheap to construct.
  /// Drops the reverse-geocode cache. Useful in tests and on `retry`.
  void clearGeocodeCache() {
    _cachedAddress = null;
    _cachedLat = null;
    _cachedLng = null;
    _cachedAt = null;
  }

  /// Re-exposes the permission service so the screen can show dialogs.
  /// Kept read-only — the repository owns the wiring.
  PermissionService get permissions => _permissionService;

  // ── Permission flow ────────────────────────────────────────────────────────

  /// Reads the current permission + service state without prompting.
  Future<PermissionCheckResult> checkPermission() =>
      _permissionService.checkCurrentState();

  /// If the user hasn't yet been asked (or denied once), prompts them.
  /// Already-permanently-denied users are returned without a prompt.
  Future<PermissionCheckResult> requestPermission() =>
      _permissionService.requestLocationPermission();

  // ── GPS one-shot + stream ──────────────────────────────────────────────────

  /// One-shot fix.
  Future<Result<CurrentLocationModel, GpsFailure>> getCurrentLocation({
    GpsSettings settings = const GpsSettings(),
  }) =>
      _gpsService.getCurrentLocation(settings: settings);

  /// Live stream of fixes.
  Stream<Result<CurrentLocationModel, GpsFailure>> getLocationStream({
    GpsSettings settings = const GpsSettings(),
  }) =>
      _gpsService.getLocationStream(settings: settings);

  // ── Reverse geocode (with debounce + dedupe) ───────────────────────────────

  /// Returns the cached address when the device hasn't moved enough to
  /// warrant a fresh geocode call, otherwise calls the [GeocodingService].
  ///
  /// Returns `null` (not a [Result.err]) on failure so the provider can
  /// keep the previous address visible instead of flashing an error.
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    final now = DateTime.now();
    if (_canReuseCache(latitude, longitude, now)) {
      return _cachedAddress;
    }

    final result = await _geocodingService.getFormattedAddress(
      latitude,
      longitude,
    );

    return result.fold(
      ok: (address) {
        _cachedAddress = address;
        _cachedLat = latitude;
        _cachedLng = longitude;
        _cachedAt = now;
        return address;
      },
      err: (failure) {
        AppLogger.warning('MapRepository.reverseGeocode failed: $failure');
        // Keep the previous address on the screen; signal "no fresh
        // address" by returning null. The provider doesn't update its
        // state on null.
        return null;
      },
    );
  }

  bool _canReuseCache(double lat, double lng, DateTime now) {
    if (_cachedAddress == null || _cachedLat == null || _cachedLng == null) {
      return false;
    }
    if (_cachedAt == null) return false;

    final age = now.difference(_cachedAt!);
    if (age >= MapConstants.geocodingMinInterval) return false;

    final distance = GpsHelper.haversineMeters(
      _cachedLat!,
      _cachedLng!,
      lat,
      lng,
    );
    return distance < MapConstants.geocodingMinDistanceMeters;
  }
}
