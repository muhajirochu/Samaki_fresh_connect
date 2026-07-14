import 'package:geolocator/geolocator.dart';

/// Immutable snapshot of a single GPS fix from the device.
///
/// Carries every field the platform can return so the UI can show a complete
/// telemetry card. Equality is by-value so we can use instances as keys when
/// dedupe-caching reverse-geocoding results.
class CurrentLocationModel {
  const CurrentLocationModel({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.heading,
    required this.speed,
    required this.timestamp,
  });

  /// Constructs a [CurrentLocationModel] from a [geolocator.Position].
  ///
  /// Geolocator returns `0.0` for fields the platform can't determine (e.g.
  /// `heading` on a stationary device); we copy those through unchanged so
  /// the UI can show "—" via a separate helper.
  factory CurrentLocationModel.fromPosition(Position position) {
    return CurrentLocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      heading: position.heading,
      speed: position.speed,
      timestamp: position.timestamp,
    );
  }

  final double latitude;
  final double longitude;

  /// Reported horizontal accuracy in meters. Lower is better.
  final double accuracy;

  /// Meters above sea level. `0.0` when the platform cannot determine it.
  final double altitude;

  /// Compass bearing in degrees (`0.0`–`359.9`). `0.0` when stationary.
  final double heading;

  /// Ground speed in meters per second. `0.0` when stationary.
  final double speed;

  /// Wall-clock time at which the fix was produced.
  final DateTime timestamp;

  /// Returns a copy with the given fields overridden.
  CurrentLocationModel copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? heading,
    double? speed,
    DateTime? timestamp,
  }) {
    return CurrentLocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurrentLocationModel &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.accuracy == accuracy &&
        other.altitude == altitude &&
        other.heading == heading &&
        other.speed == speed &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(
        latitude,
        longitude,
        accuracy,
        altitude,
        heading,
        speed,
        timestamp,
      );

  @override
  String toString() =>
      'CurrentLocationModel(lat: $latitude, lng: $longitude, '
      'accuracy: $accuracy, speed: $speed, ts: $timestamp)';
}
