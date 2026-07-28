// Failure modes surfaced by GPS-related operations.
//
// Originally part of `features/map/services/gps_service.dart`. Extracted
// here so callers outside the abandoned map slice (notably
// `services/listing_location_service.dart` and
// `screens/street_seller/create_listing_screen.dart`) can pattern-match
// on GPS errors without pulling in the rest of the abandoned slice.

/// Failure modes surfaced by GPS-related operations.
enum GpsFailure {
  /// GPS hardware is off.
  serviceDisabled,

  /// Platform refused the request (no permission, or background-only).
  permissionDenied,

  /// The fix timed out.
  timeout,

  /// Any other platform error.
  unknown,
}