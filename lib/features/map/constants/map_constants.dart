/// Compile-time constants for the Map & GPS Foundation feature.
///
/// Anything tunable lives here so the same value is not duplicated across
/// services, providers, or screens.
class MapConstants {
  // Prevent accidental instantiation.
  MapConstants._();

  // ── Default focus (Zanzibar archipelago) ────────────────────────────────────
  // The app is a Zanzibar-only fish marketplace, so the default camera
  // shows the whole archipelago (Unguja + Pemba) and the camera is
  // constrained to that bounding box. Numbers picked from the islands'
  // actual extent with a small buffer so the camera never strays into
  // the Indian Ocean.

  /// Geographic centre of the Zanzibar archipelago (between Unguja and
  /// Pemba). Used as the initial camera target so both islands are in
  /// view on first load.
  static const double defaultLatitude = -6.30;
  static const double defaultLongitude = 39.45;

  /// Zoom that frames both Unguja and Pemba on a phone screen.
  /// Higher = more zoomed in; 9.0 ~ whole archipelago.
  static const double defaultZoom = 9.0;

  static const double defaultBearing = 0.0;
  static const double defaultTilt = 0.0;

  /// Minimum zoom — the user can zoom out to this far before the map
  /// stops them (keeps the view anchored on the archipelago).
  static const double minZoom = 7.0;

  /// Maximum zoom — close enough to see individual streets.
  static const double maxZoom = 18.0;

  // ── Camera bounds (Zanzibar archipelago) ────────────────────────────────────
  // LatLngBoundsBuilder wraps to (south, west) → (north, east).
  // We give each island a little buffer so the user can pan the last
  // pixels of coastline into view before being stopped.

  /// South-west corner of the allowed camera region.
  static const double boundsSouth = -6.85; // south of Pemba

  /// North-east corner of the allowed camera region.
  static const double boundsNorth = -5.70; // north of Pemba

  /// West edge (Zanzibar channel side).
  static const double boundsWest = 39.05;

  /// East edge (open Indian Ocean side).
  static const double boundsEast = 39.85;

  // ── GPS stream configuration ────────────────────────────────────────────────
  /// How often the platform should produce a location fix.
  static const int locationIntervalMs = 5000;

  /// Minimum distance (m) the device must move before a new fix is emitted.
  static const int locationDistanceFilterMeters = 5;

  /// Upper bound for a one-shot `getCurrentPosition` call before we treat
  /// the platform as unresponsive.
  static const Duration gpsTimeout = Duration(seconds: 15);

  // ── Reverse-geocode debouncing ──────────────────────────────────────────────
  /// The minimum movement (in meters) required to trigger a fresh reverse
  /// geocode. Below this, the cached address is reused. Stops the previous
  /// implementation from geocoding on every 5-second GPS tick.
  static const double geocodingMinDistanceMeters = 25.0;

  /// Hard minimum time between reverse-geocode calls. Even if the user
  /// moves more than [geocodingMinDistanceMeters], we won't geocode more
  /// often than this. Protects the geocoding service from quota burn.
  static const Duration geocodingMinInterval = Duration(seconds: 30);

  // ── Relative time refresh ───────────────────────────────────────────────────
  /// The "Last updated" label in [LocationInformationCard] re-renders on this
  /// cadence so "3 seconds ago" advances without a GPS fix.
  static const Duration relativeTimeRefreshInterval = Duration(seconds: 1);

  // ── Bottom card layout ─────────────────────────────────────────────────────
  /// Minimum height of the bottom telemetry card. The FAB is anchored this
  /// many pixels above the screen bottom so it never sits underneath the
  /// card even on shorter devices.
  static const double bottomCardMinHeight = 300.0;

  // ── User-facing error messages ─────────────────────────────────────────────
  static const String errorGpsDisabled =
      'GPS and location services are disabled on this device. '
      'Please enable them in settings.';

  static const String errorPermissionDenied =
      'Location permission was denied. We need this permission to show '
      'your position on the map.';

  static const String errorPermissionPermanentlyDenied =
      'Location permission is permanently denied. Please enable it in '
      'device app settings.';

  static const String errorLocationUnavailable =
      'Unable to resolve device location. Please ensure you have GPS '
      'signal and try again.';

  static const String errorNetwork =
      'No internet connection. We could not resolve your address.';

  static const String errorUnknown =
      'An unexpected error occurred while accessing location services.';

  // ── Dialog retry button labels ─────────────────────────────────────────────
  static const String actionEnableGps = 'Enable GPS';
  static const String actionGrantPermission = 'Grant Permission';
  static const String actionOpenSettings = 'Open Settings';
  static const String actionRetry = 'Try Again';
  static const String actionCancel = 'Cancel';
}

/// Discrete failure kind surfaced by the [MapProvider] to the screen.
///
/// The screen uses this (not a string match on `errorMessage`) to decide
/// which dialog / widget to show. Adding a new case here is the only safe
/// way to add a new error UI.
enum MapErrorType {
  /// No error.
  none,

  /// Hardware GPS is off.
  gpsDisabled,

  /// User denied the in-app prompt at least once.
  permissionDenied,

  /// User checked "Don't ask again" or denied twice. Must go to Settings.
  permissionPermanentlyDenied,

  /// Permission was granted but a fix could not be obtained.
  locationUnavailable,

  /// Reverse-geocoding call failed (e.g. offline).
  network,

  /// Anything else.
  unknown,
}
