// Final integration test: SellerMap widget builds Marker objects for
// every demo seller with the correct LatLng position.
//
// This is the test that proves "5+ sellers show up on the buyer
// map with their locations". We:
//   1. Pump SellerMap with real fallback data.
//   2. Find the MarkerLayer widget that it builds.
//   3. Read the layer.markers list.
//   4. Verify count + each marker's LatLng.
//
// If this test passes, every seller will render on the map.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:samakifresh_connect/models/fish_item_model.dart';
import 'package:samakifresh_connect/models/map_filter_model.dart';
import 'package:samakifresh_connect/services/demo_sellers_data.dart';
import 'package:samakifresh_connect/services/location_service.dart';
import 'package:samakifresh_connect/widgets/map/seller_map.dart';

List<SellerWithFish> _pairs() {
  return fallbackSellers()
      .map((s) =>
          SellerWithFish(seller: s, matchingItems: const <FishItemModel>[]))
      .toList();
}

void main() {
  testWidgets(
    'SellerMap builds one Marker per demo seller with correct LatLng',
    (tester) async {
      final pairs = _pairs();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 800,
              child: SellerMap(
                sellers: pairs,
                buyerLocation: const BuyerLocation(
                  latitude: -6.1629,
                  longitude: 39.2026,
                  source: 'gps',
                ),
                activeRoute: null,
                selectedSeller: null,
                onSellerTap: (_) {},
              ),
            ),
          ),
        ),
      );

      // Pump frames so flutter_map builds its MarkerLayer.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Find the MarkerLayer. flutter_map may render it through
      // several wrapper widgets, so walk up the tree.
      final markerLayerFinder = find.byType(MarkerLayer);
      expect(markerLayerFinder, findsAtLeastNWidgets(1),
          reason: 'SellerMap must render a MarkerLayer');

      final markerLayers =
          tester.widgetList<MarkerLayer>(markerLayerFinder).toList();

      // Find the MarkerLayer with the most markers — that's the
      // seller-marker layer (flutter_map may render nested layers
      // for overlays, attribution, etc.).
      MarkerLayer? richest;
      for (final layer in markerLayers) {
        if (richest == null || layer.markers.length > richest.markers.length) {
          richest = layer;
        }
      }
      expect(richest, isNotNull, reason: 'a MarkerLayer must hold the markers');
      final markers = richest!.markers;

      // The first marker is the buyer ("you are here"). The
      // remaining markers are the sellers.
      expect(markers.length, pairs.length + 1,
          reason: 'expected 1 buyer + ${pairs.length} sellers, '
              'got ${markers.length}');

      // Buyer marker at Stone Town.
      final buyerMarker = markers.first;
      expect(buyerMarker.point.latitude, closeTo(-6.1629, 0.0001));
      expect(buyerMarker.point.longitude, closeTo(39.2026, 0.0001));

      // The remaining markers should match each seller's location.
      final sellerMarkers = markers.skip(1).toList();
      for (var i = 0; i < pairs.length; i++) {
        final s = pairs[i].seller;
        final m = sellerMarkers[i];
        expect(m.point.latitude, s.latitude,
            reason: '${s.fullName} lat must be ${s.latitude}, '
                'got ${m.point.latitude}');
        expect(m.point.longitude, s.longitude,
            reason: '${s.fullName} lng must be ${s.longitude}, '
                'got ${m.point.longitude}');
      }

      // Sanity check: every seller marker has a non-zero, finite point.
      for (var i = 0; i < sellerMarkers.length; i++) {
        final m = sellerMarkers[i];
        final s = pairs[i].seller;
        expect(m.point.latitude.isFinite, isTrue,
            reason: '${s.fullName} latitude is not finite');
        expect(m.point.longitude.isFinite, isTrue,
            reason: '${s.fullName} longitude is not finite');
        expect(m.point.latitude.abs(), greaterThan(0.5),
            reason: '${s.fullName} latitude too close to 0');
      }
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets(
    'Stone Town sellers render within 2 km of the buyer location',
    (tester) async {
      final pairs = _pairs();
      const buyerLat = -6.1629;
      const buyerLng = 39.2026;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 800,
              child: SellerMap(
                sellers: pairs,
                buyerLocation: const BuyerLocation(
                  latitude: buyerLat,
                  longitude: buyerLng,
                  source: 'gps',
                ),
                activeRoute: null,
                selectedSeller: null,
                onSellerTap: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final markerLayerFinder = find.byType(MarkerLayer);
      expect(markerLayerFinder, findsAtLeastNWidgets(1));
      final markerLayers =
          tester.widgetList<MarkerLayer>(markerLayerFinder).toList();

      MarkerLayer? richest;
      for (final layer in markerLayers) {
        if (richest == null || layer.markers.length > richest.markers.length) {
          richest = layer;
        }
      }
      final markers = richest!.markers.skip(1).toList(); // skip buyer

      // The first 5 sellers are Stone Town cluster — must be within
      // 2 km of buyer.
      for (var i = 0; i < 5; i++) {
        final m = markers[i];
        final s = pairs[i].seller;
        final dist = _haversineKm(
          buyerLat,
          buyerLng,
          m.point.latitude,
          m.point.longitude,
        );
        expect(dist, lessThan(2.0),
            reason: '${s.fullName} should be <2 km from buyer, '
                'is ${dist.toStringAsFixed(2)} km');
      }
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  const deg2rad = 0.017453292519943295;
  final dLat = (lat2 - lat1) * deg2rad;
  final dLng = (lng2 - lng1) * deg2rad;
  final lat1R = lat1 * deg2rad;
  final lat2R = lat2 * deg2rad;
  final h = _sin(dLat / 2) * _sin(dLat / 2) +
      _cos(lat1R) * _cos(lat2R) * _sin(dLng / 2) * _sin(dLng / 2);
  return 2 * r * _asin(_sqrt(h));
}

double _sin(double x) {
  var sum = 0.0;
  var term = x;
  for (var n = 1; n < 12; n++) {
    sum += term;
    term *= -x * x / ((2 * n) * (2 * n + 1));
  }
  return sum;
}

double _cos(double x) {
  var sum = 1.0;
  var term = 1.0;
  for (var n = 1; n < 12; n++) {
    term *= -x * x / ((2 * n - 1) * (2 * n));
    sum += term;
  }
  return sum;
}

double _sqrt(double x) {
  if (x <= 0) return 0;
  var z = x;
  for (var i = 0; i < 30; i++) {
    z = (z + x / z) / 2;
  }
  return z;
}

double _asin(double x) {
  return x + (x * x * x) / 6 + (3 * x * x * x * x * x) / 40;
}