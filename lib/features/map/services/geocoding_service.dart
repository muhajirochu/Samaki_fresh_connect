import 'package:geocoding/geocoding.dart';

import '../../../utils/logger.dart';
import '../models/result.dart';

/// Failure modes for reverse-geocoding.
enum GeocodingFailure {
  /// Network or platform error from `geocoding`.
  network,

  /// The call succeeded but the platform returned no placemark.
  noResult,

  /// Anything else.
  unknown,
}

/// Converts a `(latitude, longitude)` into a structured address string
/// suitable for the bottom telemetry card.
///
/// **Caching is done by the [MapRepository], not here** — this service
/// stays a thin wrapper around `package:geocoding`.
class GeocodingService {
  const GeocodingService();

  /// Reverse-geocodes `(lat, lng)` and returns a formatted address like
  /// `"Market St, Stone Town, Zanzibar, Tanzania"`.
  ///
  /// Returns [Err] on any failure rather than throwing, so the provider can
  /// branch on the kind.
  Future<Result<String, GeocodingFailure>> getFormattedAddress(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) {
        AppLogger.warning(
          'GeocodingService: empty placemarks for $latitude, $longitude',
        );
        return const Err(GeocodingFailure.noResult);
      }

      final place = placemarks.first;
      final formatted = _formatPlacemark(place);
      if (formatted.isEmpty) {
        return const Err(GeocodingFailure.noResult);
      }
      return Ok(formatted);
    } catch (e, st) {
      // The `geocoding` package surfaces network errors as plain exceptions
      // with no typed subclass. String-match the message; if we ever need
      // more granularity we can introduce a typed mapper here.
      final msg = e.toString().toLowerCase();
      if (msg.contains('network') ||
          msg.contains('socket') ||
          msg.contains('timeout')) {
        AppLogger.warning('GeocodingService: network failure', e);
        return const Err(GeocodingFailure.network);
      }
      AppLogger.error('GeocodingService: unknown failure', e, st);
      return const Err(GeocodingFailure.unknown);
    }
  }

  /// Joins available placemark fields into a single human-readable string.
  /// Empty fields are skipped so we never produce `", , "`.
  String _formatPlacemark(Placemark place) {
    final parts = <String>[
      if ((place.street ?? '').isNotEmpty) place.street!,
      if ((place.name ?? '').isNotEmpty &&
          (place.street ?? '') != place.name)
        place.name!,
      if ((place.subLocality ?? '').isNotEmpty) place.subLocality!,
      if ((place.locality ?? '').isNotEmpty) place.locality!,
      if ((place.administrativeArea ?? '').isNotEmpty &&
          (place.administrativeArea ?? '') != (place.locality ?? ''))
        place.administrativeArea!,
      if ((place.country ?? '').isNotEmpty) place.country!,
    ];
    return parts.join(', ');
  }
}
