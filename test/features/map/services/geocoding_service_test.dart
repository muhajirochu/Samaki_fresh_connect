// Unit tests for [GeocodingService].
//
// `package:geocoding` resolves its implementation via
// `GeocodingPlatform.instance`. We swap that for an in-memory fake instead
// of mocking the platform channel — much faster and more robust.

import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:samakifresh_connect/features/map/services/geocoding_service.dart';

class _FakePlacemark extends Placemark {
  const _FakePlacemark({
    super.name,
    super.street,
    super.country,
    super.administrativeArea,
    super.locality,
    super.subLocality,
  });
}

class _FakeGeocodingPlatform extends GeocodingPlatform
    with MockPlatformInterfaceMixin {
  List<Placemark>? placemarksToReturn;
  Object? errorToThrow;

  @override
  Future<List<Placemark>> placemarkFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    if (errorToThrow != null) throw errorToThrow!;
    return placemarksToReturn ?? const [];
  }

  @override
  Future<List<Location>> locationFromAddress(String address,
          {String? localeIdentifier}) async =>
      const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeocodingService', () {
    late GeocodingService service;
    late _FakeGeocodingPlatform fake;

    setUp(() {
      service = const GeocodingService();
      fake = _FakeGeocodingPlatform();
      GeocodingPlatform.instance = fake;
    });

    tearDown(() {
      // The platform-interface setter asserts non-null; leave a sentinel
      // fake in place rather than nulling it.
      GeocodingPlatform.instance = _FakeGeocodingPlatform();
    });

    test('returns Ok with a formatted address on success', () async {
      fake.placemarksToReturn = [
        const _FakePlacemark(
          name: 'Stone Town Market',
          street: 'Kenyatta Road',
          country: 'Tanzania',
          administrativeArea: 'Mjini Magharibi',
          locality: 'Zanzibar City',
          subLocality: 'Stone Town',
        ),
      ];

      final result = await service.getFormattedAddress(-6.1629, 39.2026);

      expect(result.isOk, isTrue);
      result.fold(
        ok: (address) {
          expect(address, contains('Kenyatta Road'));
          expect(address, contains('Stone Town'));
          expect(address, contains('Zanzibar'));
          expect(address, contains('Tanzania'));
        },
        err: (_) => fail('Expected Ok, got Err'),
      );
    });

    test('returns Err.noResult when placemarks list is empty', () async {
      fake.placemarksToReturn = const [];

      final result = await service.getFormattedAddress(-6.1629, 39.2026);
      expect(result.isErr, isTrue);
      result.fold(
        ok: (_) => fail('Expected Err, got Ok'),
        err: (failure) => expect(failure, GeocodingFailure.noResult),
      );
    });

    test('returns Err.network on platform network error', () async {
      fake.errorToThrow = Exception('network error: host lookup failed');

      final result = await service.getFormattedAddress(-6.1629, 39.2026);
      expect(result.isErr, isTrue);
      result.fold(
        ok: (_) => fail('Expected Err, got Ok'),
        err: (failure) => expect(failure, GeocodingFailure.network),
      );
    });

    test('returns Err.unknown for unrecognized failures', () async {
      fake.errorToThrow = Exception('something else broke');

      final result = await service.getFormattedAddress(-6.1629, 39.2026);
      expect(result.isErr, isTrue);
      result.fold(
        ok: (_) => fail('Expected Err, got Ok'),
        err: (failure) => expect(failure, GeocodingFailure.unknown),
      );
    });
  });
}