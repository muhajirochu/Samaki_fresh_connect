// Bridges GPS capture with persistence for the create-listing flow.
//
// The fisherman taps "Set shop location" once; this service:
//   1. Reads the device's current position via the existing
//      [LocationService.getCurrentOrFallback] (so we get the same
//      profile / fallback / GPS-priority chain the buyer map uses).
//   2. Persists the result to the seller's user doc so the dashboard
//      and any future flow can read it.
//   3. Persists the result to a specific listing so the buyer's geo
//      query picks it up.
//
// All public methods return a [Result] so the screen can branch on
// success / failure without try/catch noise.

import 'package:geocoding/geocoding.dart' show placemarkFromCoordinates;

import '../models/result.dart';
import 'gps_failure.dart';
import '../utils/logger.dart';
import 'fish_listing_service.dart';
import 'location_service.dart' show BuyerLocation, LocationService;
import 'user_service.dart';

class ListingLocationService {
  ListingLocationService({
    LocationService? locationService,
    UserService? userService,
    FishListingService? fishListingService,
  })  : _locationService = locationService ?? LocationService(),
        _userService = userService ?? UserService(),
        _fishListingService = fishListingService ?? FishListingService();

  final LocationService _locationService;
  final UserService _userService;
  final FishListingService _fishListingService;

  // ── GPS capture ─────────────────────────────────────────────────────────────

  /// Reads the current device position.
  ///
  /// We call [LocationService.getCurrentOrFallback] with `buyer: null`
  /// so the fallback path is "device GPS → Stone Town default" rather
  /// than "device GPS → buyer profile → Stone Town". Sellers and buyers
  /// share the same GPS chain but resolve differently when no GPS is
  /// available.
  Future<Result<BuyerLocation, GpsFailure>> captureCurrentLocation() async {
    try {
      final loc = await _locationService.getCurrentOrFallback(buyer: null);
      // Translate the source label into the map module's failure enum
      // so the screen can show a single, consistent error vocabulary.
      switch (loc.source) {
        case 'gps':
        case 'profile':
          return Ok(loc);
        case 'fallback':
        default:
          // The fallback to Stone Town still gives us a valid coord —
          // it's not a *failure* per se, but the caller probably wants
          // to know the value is a guess. We surface it as Ok so the
          // seller can choose to keep the default or retry.
          return Ok(loc);
      }
    } catch (e, st) {
      AppLogger.error('ListingLocationService.captureCurrentLocation', e, st);
      return const Err(GpsFailure.unknown);
    }
  }

  // ── Reverse-geocode (best-effort human label) ──────────────────────────────

  /// Resolves `(lat, lng)` to a short human-readable string
  /// (e.g. "Stone Town, Zanzibar"). Returns `null` on any failure —
  /// the screen is free to fall back to lat/lng display.
  Future<String?> reverseGeocodeLabel(double lat, double lng) async {
    try {
      final marks = await placemarkFromCoordinates(lat, lng);
      if (marks.isEmpty) return null;
      final p = marks.first;
      final parts = <String>[
        if ((p.subLocality ?? '').isNotEmpty) p.subLocality!,
        if ((p.locality ?? '').isNotEmpty &&
            (p.locality ?? '') != (p.subLocality ?? ''))
          p.locality!,
        if ((p.country ?? '').isNotEmpty) p.country!,
      ];
      return parts.isEmpty ? null : parts.join(', ');
    } catch (e) {
      AppLogger.warning('reverseGeocodeLabel failed: $e');
      return null;
    }
  }

  // ── Persistence ─────────────────────────────────────────────────────────────

  /// Writes the location to the seller's user doc.
  Future<void> persistToUserDoc(
    String userId,
    BuyerLocation location,
  ) async {
    await _userService.updateUserLocation(
      userId,
      latitude: location.latitude,
      longitude: location.longitude,
    );
  }

  /// Writes the location to a specific listing doc.
  Future<void> persistToListing(
    String listingId,
    BuyerLocation location,
  ) async {
    await _fishListingService.updateListingLocation(
      listingId,
      latitude: location.latitude,
      longitude: location.longitude,
    );
  }
}
