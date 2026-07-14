// Unit tests for [CurrentLocationModel].

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:samakifresh_connect/features/map/models/current_location_model.dart';

void main() {
  group('equality', () {
    test('two instances with the same fields are equal', () {
      final ts = DateTime(2026, 7, 3, 12);
      final a = CurrentLocationModel(
        latitude: -6.16,
        longitude: 39.20,
        accuracy: 5,
        altitude: 10,
        heading: 90,
        speed: 1.2,
        timestamp: ts,
      );
      final b = CurrentLocationModel(
        latitude: -6.16,
        longitude: 39.20,
        accuracy: 5,
        altitude: 10,
        heading: 90,
        speed: 1.2,
        timestamp: ts,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different timestamps are not equal', () {
      final a = CurrentLocationModel(
        latitude: 0, longitude: 0, accuracy: 0,
        altitude: 0, heading: 0, speed: 0,
        timestamp: DateTime(2026, 7, 3, 12),
      );
      final b = CurrentLocationModel(
        latitude: 0, longitude: 0, accuracy: 0,
        altitude: 0, heading: 0, speed: 0,
        timestamp: DateTime(2026, 7, 3, 13),
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('copyWith', () {
    test('overrides only the named fields', () {
      final base = CurrentLocationModel(
        latitude: -6.16, longitude: 39.20, accuracy: 5,
        altitude: 10, heading: 90, speed: 1.2,
        timestamp: DateTime(2026, 7, 3, 12),
      );
      final updated = base.copyWith(latitude: 0.0);
      expect(updated.latitude, 0.0);
      expect(updated.longitude, base.longitude);
      expect(updated.accuracy, base.accuracy);
      expect(updated.altitude, base.altitude);
      expect(updated.heading, base.heading);
      expect(updated.speed, base.speed);
      expect(updated.timestamp, base.timestamp);
    });
  });

  group('fromPosition', () {
    test('copies every Position field', () {
      final position = _PositionStub(
        latitude: -6.1629,
        longitude: 39.2026,
        accuracy: 4.5,
        altitude: 12.0,
        heading: 180.0,
        speed: 0.5,
        timestamp: DateTime(2026, 7, 3, 10),
      );
      final model = CurrentLocationModel.fromPosition(position);
      expect(model.latitude, -6.1629);
      expect(model.longitude, 39.2026);
      expect(model.accuracy, 4.5);
      expect(model.altitude, 12.0);
      expect(model.heading, 180.0);
      expect(model.speed, 0.5);
      expect(model.timestamp, DateTime(2026, 7, 3, 10));
    });
  });
}

/// Lightweight test double for [Position]. Avoids needing a real
/// platform-channel mock — we only read the seven fields the model cares
/// about.
class _PositionStub extends Position {
  const _PositionStub({
    required super.latitude,
    required super.longitude,
    required super.accuracy,
    required super.altitude,
    required super.heading,
    required super.speed,
    required super.timestamp,
  }) : super(
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
          speedAccuracy: 0.0,
        );
}