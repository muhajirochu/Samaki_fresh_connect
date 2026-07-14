// Unit tests for [MapProvider].
//
// The provider is constructed with a hand-rolled fake `MapRepository` so
// each test can declare the exact sequence of permission / location /
// geocode outcomes it needs.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:samakifresh_connect/features/map/constants/map_constants.dart';
import 'package:samakifresh_connect/features/map/models/current_location_model.dart';
import 'package:samakifresh_connect/features/map/models/result.dart';
import 'package:samakifresh_connect/features/map/providers/map_provider.dart';
import 'package:samakifresh_connect/features/map/repositories/map_repository.dart';
import 'package:samakifresh_connect/features/map/services/gps_service.dart';
import 'package:samakifresh_connect/features/map/services/permission_service.dart';

/// Minimal `MapRepository` fake — overrides every method the provider
/// actually calls. Stuffs its own canned results into [permissionResult]
/// and the [addFix] stream.
class _FakeRepository implements MapRepository {
  PermissionCheckResult permissionResult = const PermissionGranted();
  Result<CurrentLocationModel, GpsFailure>? fixResult;
  String? reverseGeocodeAnswer;

  final StreamController<Result<CurrentLocationModel, GpsFailure>>
      fixController = StreamController.broadcast();

  int permissionChecks = 0;
  int permissionRequests = 0;
  int getLocationCalls = 0;
  int reverseGeocodeCalls = 0;
  int clearCacheCalls = 0;

  /// Emits a single fix event on the live-stream controller. The provider
  /// listens to it after the initial fix is resolved.
  void emit(Result<CurrentLocationModel, GpsFailure> event) {
    fixController.add(event);
  }

  Future<void> close() async {
    await fixController.close();
  }

  @override
  PermissionService get permissions => const PermissionService();

  @override
  Future<PermissionCheckResult> checkPermission() async {
    permissionChecks++;
    return permissionResult;
  }

  @override
  Future<PermissionCheckResult> requestPermission() async {
    permissionRequests++;
    return permissionResult;
  }

  @override
  Future<Result<CurrentLocationModel, GpsFailure>> getCurrentLocation({
    GpsSettings settings = const GpsSettings(),
  }) async {
    getLocationCalls++;
    return fixResult ?? const Err(GpsFailure.unknown);
  }

  @override
  Stream<Result<CurrentLocationModel, GpsFailure>> getLocationStream({
    GpsSettings settings = const GpsSettings(),
  }) =>
      fixController.stream;

  @override
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    reverseGeocodeCalls++;
    return reverseGeocodeAnswer;
  }

  @override
  void clearGeocodeCache() {
    clearCacheCalls++;
  }
}

CurrentLocationModel _fix() => CurrentLocationModel(
      latitude: -6.1629,
      longitude: 39.2026,
      accuracy: 4.0,
      altitude: 12.0,
      heading: 90.0,
      speed: 1.2,
      timestamp: DateTime(2026, 7, 3, 12),
    );

void main() {
  group('MapProvider', () {
    late _FakeRepository repo;
    late MapProvider provider;

    setUp(() {
      repo = _FakeRepository();
      provider = MapProvider(repository: repo);
    });

    tearDown(() async {
      provider.dispose();
      await repo.close();
    });

    test('initialize populates location + address on the happy path',
        () async {
      repo.permissionResult = const PermissionGranted();
      repo.fixResult = Ok(_fix());
      repo.reverseGeocodeAnswer = 'Test Address';

      await provider.initialize();

      expect(provider.isLoading, isFalse);
      expect(provider.errorType, MapErrorType.none);
      expect(provider.permissionState, LocationPermissionState.granted);
      expect(provider.gpsEnabled, isTrue);
      expect(provider.currentLocation, isNotNull);
      expect(provider.currentAddress, 'Test Address');
      expect(provider.lastUpdatedAt, isNotNull);
    });

    test('initialize sets errorType=gpsDisabled when service is off',
        () async {
      repo.permissionResult = const ServiceDisabled();

      await provider.initialize();

      expect(provider.errorType, MapErrorType.gpsDisabled);
      expect(provider.errorMessage, MapConstants.errorGpsDisabled);
      expect(provider.currentLocation, isNull);
    });

    test('initialize sets errorType=permissionDenied when permission is denied',
        () async {
      repo.permissionResult = const PermissionDenied();

      await provider.initialize();

      expect(provider.permissionState, LocationPermissionState.denied);
      expect(provider.errorType, MapErrorType.permissionDenied);
    });

    test('retry clears state and re-runs initialize', () async {
      repo.permissionResult = const ServiceDisabled();

      await provider.initialize();
      expect(provider.errorType, MapErrorType.gpsDisabled);

      // Simulate user fixing the issue and retrying.
      repo.permissionResult = const PermissionGranted();
      repo.fixResult = Ok(_fix());
      repo.reverseGeocodeAnswer = 'Recovered';

      await provider.retry();

      expect(repo.clearCacheCalls, 1,
          reason: 'retry should bust the geocode cache');
      expect(provider.errorType, MapErrorType.none);
      expect(provider.currentAddress, 'Recovered');
      expect(provider.currentLocation, isNotNull);
    });

    test('streamed fix updates currentLocation', () async {
      repo.permissionResult = const PermissionGranted();
      repo.fixResult = Ok(_fix());
      repo.reverseGeocodeAnswer = 'Test Address';

      await provider.initialize();

      final newFix = _fix().copyWith(latitude: -6.1700, longitude: 39.2100);
      repo.emit(Ok(newFix));
      // Let the listener run.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(provider.currentLocation?.latitude, -6.1700);
      expect(provider.currentLocation?.longitude, 39.2100);
    });

    test('streamed GPS failure populates errorType', () async {
      repo.permissionResult = const PermissionGranted();
      repo.fixResult = Ok(_fix());
      repo.reverseGeocodeAnswer = 'Test Address';

      await provider.initialize();
      repo.emit(const Err(GpsFailure.serviceDisabled));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(provider.errorType, MapErrorType.gpsDisabled);
    });

    test('caller can read permissions service via the provider', () {
      // The provider exposes the permission service so the screen can
      // open settings / show dialogs without holding its own reference.
      expect(provider.permissions, isA<PermissionService>());
    });
  });
}
