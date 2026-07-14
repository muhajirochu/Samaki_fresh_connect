// Routing via the public OSRM demo server. OSRM is open-source
// (https://project-osrm.org) and returns GeoJSON polylines for OSM data
// with no API key required — ideal for a marketplace that can't justify
// Google's per-request billing.
//
// We always pair the network call with a Haversine straight-line
// fallback so the buyer can still see "Seller X is 4.2km away" even when
// the network is down or the device is offline. The polyline just
// becomes a single straight segment in that case.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../utils/logger.dart';

class RouteResult {
  /// Ordered list of waypoints to draw on the map.
  final List<LatLng> points;

  /// Total route distance, in km. From OSRM when available, else Haversine.
  final double distanceKm;

  /// Estimated travel time, in minutes. From OSRM when available, else a
  /// road-speed heuristic (25 km/h average for Zanzibar mixed traffic).
  final double durationMinutes;

  /// Which source produced this result. Surfaced in the UI as a small badge
  /// so the buyer knows if the ETA is "live" or an estimate.
  final RouteSource source;

  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    required this.source,
  });
}

enum RouteSource { osrm, fallback }

class RoutingService {
  static const String _osrmBase = 'https://router.project-osrm.org';
  // Average Zanzibar mixed-traffic speed used for the fallback ETA.
  static const double _fallbackAvgSpeedKmh = 25.0;

  /// Fetches a route from [from] to [to]. Never throws — if OSRM is
  /// unreachable, returns a straight-line fallback with Haversine
  /// distance and a road-speed-based ETA.
  Future<RouteResult> getRoute({
    required LatLng from,
    required LatLng to,
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    try {
      final url = Uri.parse(
        '$_osrmBase/route/v1/driving/'
        '${from.longitude},${from.latitude};'
        '${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await c
          .get(url, headers: {'User-Agent': 'SamakiFreshConnect/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0.0;
          final durationSeconds = (route['duration'] as num?)?.toDouble() ?? 0.0;
          final geom = route['geometry'] as Map<String, dynamic>?;
          final coords = geom?['coordinates'] as List<dynamic>?;
          if (coords != null && coords.isNotEmpty) {
            final points = coords.map<LatLng>((raw) {
              final pair = raw as List<dynamic>;
              return LatLng(
                (pair[1] as num).toDouble(), // GeoJSON is [lng, lat]
                (pair[0] as num).toDouble(),
              );
            }).toList();
            return RouteResult(
              points: points,
              distanceKm: distanceMeters / 1000.0,
              durationMinutes: durationSeconds / 60.0,
              source: RouteSource.osrm,
            );
          }
        }
        AppLogger.warning('OSRM returned 200 but no route — falling back');
      } else {
        AppLogger.warning(
            'OSRM HTTP ${response.statusCode} — falling back to straight line');
      }
    } on TimeoutException {
      AppLogger.warning('OSRM timed out — falling back to straight line');
    } catch (e) {
      AppLogger.error('OSRM request failed: $e — falling back');
    } finally {
      c.close();
    }

    return _straightLineFallback(from, to);
  }

  /// Straight-line fallback. Useful when the device is offline; we still
  /// show a usable "distance / ETA" so the buyer can make a decision.
  RouteResult _straightLineFallback(LatLng from, LatLng to) {
    final distanceKm = _haversineKm(from, to);
    final durationMinutes = (distanceKm / _fallbackAvgSpeedKmh) * 60.0;
    return RouteResult(
      points: [from, to],
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      source: RouteSource.fallback,
    );
  }

  static double _haversineKm(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLng = _deg2rad(b.longitude - a.longitude);
    final s = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_deg2rad(a.latitude)) *
            math.cos(_deg2rad(b.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2));
    final c = 2 * math.atan2(math.sqrt(s), math.sqrt(1 - s));
    return earthRadiusKm * c;
  }

  static double _deg2rad(double d) => d * (math.pi / 180.0);
}

final routingServiceProvider = Provider<RoutingService>(
  (ref) => RoutingService(),
);
