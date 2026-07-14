// Unit tests for [MapRepository] — specifically the geocode-cache logic
// that protects the geocoding service from being called every 5 seconds.
//
// The repository is constructed with a recording `GeocodingService` so we
// can count calls and inject failures deterministically.

import 'package:flutter_test/flutter_test.dart';
import 'package:samakifresh_connect/features/map/constants/map_constants.dart';
import 'package:samakifresh_connect/features/map/models/result.dart';
import 'package:samakifresh_connect/features/map/repositories/map_repository.dart';
import 'package:samakifresh_connect/features/map/services/geocoding_service.dart';

/// Recording spy — counts calls and returns either an `Ok(cannedAddress)`
/// or an `Err(failOnCall)` depending on the call index.
class _RecordingGeocodingSpy implements GeocodingService {
  _RecordingGeocodingSpy({
    required this.cannedAddress,
    this.failOnCall = -1,
  });

  final String cannedAddress;
  final int failOnCall;

  int callCount = 0;

  @override
  Future<Result<String, GeocodingFailure>> getFormattedAddress(
    double latitude,
    double longitude,
  ) async {
    callCount++;
    if (callCount == failOnCall) {
      return const Err(GeocodingFailure.network);
    }
    return Ok(cannedAddress);
  }
}

void main() {
  group('MapRepository.reverseGeocode', () {
    const cached = '123 Test St, Test City';

    test('first call hits the service', () async {
      final spy = _RecordingGeocodingSpy(cannedAddress: cached);
      final repo = MapRepository(geocodingService: spy);

      final result = await repo.reverseGeocode(-6.1629, 39.2026);

      expect(result, cached);
      expect(spy.callCount, 1);
    });

    test('returns cached value when device has not moved', () async {
      final spy = _RecordingGeocodingSpy(cannedAddress: cached);
      final repo = MapRepository(geocodingService: spy);

      await repo.reverseGeocode(-6.1629, 39.2026);
      // Same coords again — should be cached.
      final result = await repo.reverseGeocode(-6.1629, 39.2026);

      expect(result, cached);
      expect(spy.callCount, 1, reason: 'Second call should hit the cache');
    });

    test('returns cached value when movement is below threshold', () async {
      final spy = _RecordingGeocodingSpy(cannedAddress: cached);
      final repo = MapRepository(geocodingService: spy);

      await repo.reverseGeocode(-6.1629, 39.2026);
      // Move ~10 m north — below the 25 m threshold.
      // 10 m ≈ +0.00009 degrees latitude.
      final result = await repo.reverseGeocode(
        -6.1629 + 0.00009,
        39.2026,
      );

      expect(result, cached);
      expect(spy.callCount, 1);
    });

    test('hits service again when movement exceeds the threshold', () async {
      final spy = _RecordingGeocodingSpy(cannedAddress: cached);
      final repo = MapRepository(geocodingService: spy);

      await repo.reverseGeocode(-6.1629, 39.2026);
      // Move ~500 m — well above the 25 m threshold.
      final result = await repo.reverseGeocode(
        -6.1629 + 0.0045,
        39.2026,
      );

      expect(result, cached);
      expect(spy.callCount, 2);
    });

    test('returns null on geocode failure', () async {
      // First call succeeds (caches), second call busts the cache and the
      // underlying service returns Err — repo returns null.
      final spy = _RecordingGeocodingSpy(
        cannedAddress: cached,
        failOnCall: 2,
      );
      final repo = MapRepository(geocodingService: spy);

      final first = await repo.reverseGeocode(-6.1629, 39.2026);
      expect(first, cached);

      final second = await repo.reverseGeocode(
        -6.1629 + 0.0045,
        39.2026,
      );
      expect(second, isNull);
      expect(spy.callCount, 2);
    });

    test('clearGeocodeCache forces a fresh call', () async {
      final spy = _RecordingGeocodingSpy(cannedAddress: cached);
      final repo = MapRepository(geocodingService: spy);

      await repo.reverseGeocode(-6.1629, 39.2026);
      repo.clearGeocodeCache();
      await repo.reverseGeocode(-6.1629, 39.2026);

      expect(spy.callCount, 2);
    });
  });

  group('MapConstants contract', () {
    test('geocodingMinDistanceMeters is 25', () {
      // The repository's threshold relies on this exact value; if you
      // change one you should change the other.
      expect(MapConstants.geocodingMinDistanceMeters, 25.0);
    });

    test('geocodingMinInterval is 30 seconds', () {
      expect(
        MapConstants.geocodingMinInterval,
        const Duration(seconds: 30),
      );
    });
  });
}
