import 'dart:math' as math;

/// Pure-function helpers for the Map & GPS feature.
///
/// All methods are static and side-effect free so they're trivially testable.
class GpsHelper {
  // No instances.
  GpsHelper._();

  /// Earth radius in meters (mean).
  static const double _earthRadiusMeters = 6371000.0;

  /// Converts meters per second to kilometers per hour.
  ///
  /// Negative values (which the platform can return during a cold-start
  /// glitch) are clamped to `0.0`.
  static double mpsToKmph(double mps) {
    if (mps.isNaN || mps < 0) return 0.0;
    return mps * 3.6;
  }

  /// Formats a speed value as a user-friendly string, e.g. `"12.4 km/h"`.
  static String formatSpeed(double mps) {
    final kmh = mpsToKmph(mps);
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  /// Formats an accuracy value in meters, e.g. `"8.3 m"`.
  static String formatAccuracy(double meters) {
    if (meters.isNaN || meters < 0) return '—';
    return '${meters.toStringAsFixed(1)} m';
  }

  /// Formats an altitude value in meters, e.g. `"23.0 m"`. Returns `—` for
  /// values the platform cannot determine (typically `0.0` on iOS in some
  /// indoor scenarios).
  static String formatAltitude(double meters) {
    if (meters.isNaN) return '—';
    return '${meters.toStringAsFixed(1)} m';
  }

  /// Formats a compass bearing as a degree string, e.g. `"123.4°"`. Returns
  /// `—` for the platform's "unknown heading" sentinel of `0.0` when
  /// stationary is implied by `isMoving == false`.
  static String formatHeading(double degrees) {
    if (degrees.isNaN) return '—';
    return '${degrees.toStringAsFixed(1)}°';
  }

  /// Formats lat/lng for display, e.g. `"-6.16290, 39.20260"`.
  static String formatCoordinates(double lat, double lng) {
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  /// Formats a wall-clock timestamp as `HH:MM:SS` (24-hour). Used as a
  /// secondary label below the relative-time string.
  static String formatTimestamp(DateTime dateTime) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dateTime.hour)}:${two(dateTime.minute)}:${two(dateTime.second)}';
  }

  /// Formats [then] as a relative-time string, e.g. `"Just now"`,
  /// `"3 seconds ago"`, `"2 minutes ago"`, `"1 hour ago"`.
  ///
  /// [now] is injectable for testing.
  static String formatRelativeTime(DateTime then, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(then);

    // Future timestamps (clock skew) — show as "Just now".
    if (diff.isNegative) return 'Just now';

    final seconds = diff.inSeconds;
    if (seconds < 5) return 'Just now';
    if (seconds < 60) return '$seconds seconds ago';

    final minutes = diff.inMinutes;
    if (minutes < 60) return minutes == 1 ? '1 minute ago' : '$minutes minutes ago';

    final hours = diff.inHours;
    if (hours < 24) return hours == 1 ? '1 hour ago' : '$hours hours ago';

    final days = diff.inDays;
    if (days < 7) return days == 1 ? '1 day ago' : '$days days ago';

    // Fall back to a date string for older timestamps.
    return '${then.year}-${then.month.toString().padLeft(2, '0')}-'
        '${then.day.toString().padLeft(2, '0')}';
  }

  /// Great-circle distance in meters between two lat/lng points using the
  /// Haversine formula. Used by the geocoding cache to skip reverse-geocodes
  /// when the device has barely moved.
  static double haversineMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;
}
