import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../../utils/logger.dart';
import '../constants/map_constants.dart';
import '../models/current_location_model.dart';
import '../models/result.dart';

/// Tunable knobs for a GPS one-shot or stream request.
///
/// Defaults to high accuracy with the project's standard interval / distance
/// filter. Callers can override any field.
class GpsSettings {
  const GpsSettings({
    this.accuracy = LocationAccuracy.high,
    this.intervalMs = MapConstants.locationIntervalMs,
    this.distanceFilterMeters = MapConstants.locationDistanceFilterMeters,
    this.timeout = MapConstants.gpsTimeout,
  });

  final LocationAccuracy accuracy;
  final int intervalMs;
  final int distanceFilterMeters;
  final Duration timeout;
}

/// Failure modes surfaced by [GpsService].
///
/// The provider maps these to [MapErrorType] for the UI.
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

/// Wraps `geolocator` so the rest of the feature can deal in
/// [CurrentLocationModel] + [Result] instead of platform exceptions.
class GpsService {
  const GpsService();

  /// Returns a single GPS fix. Never throws — returns [Err] on failure.
  Future<Result<CurrentLocationModel, GpsFailure>> getCurrentLocation({
    GpsSettings settings = const GpsSettings(),
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('GpsService: location service is disabled');
        return const Err(GpsFailure.serviceDisabled);
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: settings.accuracy,
        timeLimit: settings.timeout,
      );
      return Ok(CurrentLocationModel.fromPosition(position));
    } on TimeoutException catch (e) {
      AppLogger.warning('GpsService: getCurrentPosition timed out', e);
      return const Err(GpsFailure.timeout);
    } on LocationServiceDisabledException catch (e) {
      AppLogger.warning('GpsService: service disabled mid-call', e);
      return const Err(GpsFailure.serviceDisabled);
    } catch (e, st) {
      AppLogger.error('GpsService: unexpected error', e, st);
      return const Err(GpsFailure.unknown);
    }
  }

  /// A live stream of GPS fixes. The stream emits [Err] values on failure
  /// via a `StreamController` wrapper so consumers can listen without
  /// try/catch.
  Stream<Result<CurrentLocationModel, GpsFailure>> getLocationStream({
    GpsSettings settings = const GpsSettings(),
  }) {
    final controller =
        StreamController<Result<CurrentLocationModel, GpsFailure>>();

    // Geolocator's raw stream is `Stream<Position>` with onError callbacks.
    final locationSettings = LocationSettings(
      accuracy: settings.accuracy,
      distanceFilter: settings.distanceFilterMeters,
    );

    final sub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) {
        controller.add(Ok(CurrentLocationModel.fromPosition(position)));
      },
      onError: (Object e, StackTrace st) {
        AppLogger.error('GpsService stream error', e, st);
        if (e is LocationServiceDisabledException) {
          controller.add(const Err(GpsFailure.serviceDisabled));
        } else {
          controller.add(const Err(GpsFailure.unknown));
        }
      },
      cancelOnError: false,
    );

    controller.onCancel = () async {
      await sub.cancel();
    };

    return controller.stream;
  }
}
