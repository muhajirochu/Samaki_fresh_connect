// Unit tests for [ListingLocationService] — the bridge between the
// create-listing screen's "Set shop location" tap and persistence to
// the user's doc.
//
// We can't mock the geocoding / geolocator channels from this layer
// easily, so we inject a fake [LocationService] and assert against
// the result it returns.

import 'package:flutter_test/flutter_test.dart';
import 'package:samakifresh_connect/features/map/services/gps_service.dart' show GpsFailure;
import 'package:samakifresh_connect/models/user_model.dart';
import 'package:samakifresh_connect/services/fish_listing_service.dart';
import 'package:samakifresh_connect/services/listing_location_service.dart';
import 'package:samakifresh_connect/services/location_service.dart';
import 'package:samakifresh_connect/services/user_service.dart';

class _FakeLocationService extends LocationService {
  BuyerLocation? next;
  Object? throwError;

  @override
  Future<BuyerLocation> getCurrentOrFallback({UserModel? buyer}) async {
    if (throwError != null) throw throwError!;
    return next ?? const BuyerLocation(
          latitude: -6.1629,
          longitude: 39.2026,
          source: 'fallback',
        );
  }
}

class _CountingUserService extends UserService {
  int calls = 0;
  double? lastLat;
  double? lastLng;

  @override
  Future<void> updateUserLocation(
    String userId, {
    required double latitude,
    required double longitude,
    String? geohash,
  }) async {
    calls++;
    lastLat = latitude;
    lastLng = longitude;
  }
}

class _CountingListingService extends FishListingService {
  int calls = 0;
  double? lastLat;
  double? lastLng;

  @override
  Future<void> updateListingLocation(
    String listingId, {
    required double latitude,
    required double longitude,
  }) async {
    calls++;
    lastLat = latitude;
    lastLng = longitude;
  }
}

void main() {
  group('ListingLocationService.captureCurrentLocation', () {
    test('returns Ok when the location service yields a fix', () async {
      final fake = _FakeLocationService()
        ..next = const BuyerLocation(
          latitude: -6.21,
          longitude: 39.25,
          source: 'gps',
        );
      final service = ListingLocationService(locationService: fake);
      final result = await service.captureCurrentLocation();
      expect(result.isOk, isTrue);
      result.fold(
        ok: (loc) {
          expect(loc.latitude, -6.21);
          expect(loc.longitude, 39.25);
        },
        err: (_) => fail('Expected Ok'),
      );
    });

    test('returns Ok with the fallback default when GPS is unavailable',
        () async {
      // The LocationService already returns a fallback `BuyerLocation`
      // rather than throwing — so the Result should also be Ok with the
      // fallback coords. Callers can read `source == 'fallback'` if
      // they want to warn the seller.
      final fake = _FakeLocationService()
        ..next = const BuyerLocation(
          latitude: -6.1629,
          longitude: 39.2026,
          source: 'fallback',
        );
      final service = ListingLocationService(locationService: fake);
      final result = await service.captureCurrentLocation();
      expect(result.isOk, isTrue);
    });

    test('returns Err(unknown) when the location service throws',
        () async {
      final fake = _FakeLocationService()..throwError = StateError('boom');
      final service = ListingLocationService(locationService: fake);
      final result = await service.captureCurrentLocation();
      expect(result.isErr, isTrue);
      result.fold(
        ok: (_) => fail('Expected Err'),
        err: (f) => expect(f, GpsFailure.unknown),
      );
    });
  });

  group('ListingLocationService.persistToUserDoc', () {
    test('forwards lat/lng to the user service', () async {
      final users = _CountingUserService();
      final service = ListingLocationService(
        locationService: _FakeLocationService(),
        userService: users,
        fishListingService: _CountingListingService(),
      );

      await service.persistToUserDoc(
        'user-1',
        const BuyerLocation(
          latitude: -6.30,
          longitude: 39.45,
          source: 'gps',
        ),
      );

      expect(users.calls, 1);
      expect(users.lastLat, -6.30);
      expect(users.lastLng, 39.45);
    });
  });

  group('ListingLocationService.persistToListing', () {
    test('forwards lat/lng to the listing service', () async {
      final listings = _CountingListingService();
      final service = ListingLocationService(
        locationService: _FakeLocationService(),
        userService: _CountingUserService(),
        fishListingService: listings,
      );

      await service.persistToListing(
        'listing-1',
        const BuyerLocation(
          latitude: -6.10,
          longitude: 39.10,
          source: 'profile',
        ),
      );

      expect(listings.calls, 1);
      expect(listings.lastLat, -6.10);
      expect(listings.lastLng, 39.10);
    });
  });
}