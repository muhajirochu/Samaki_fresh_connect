// A lightweight, in-memory copy of the demo sellers that
// `services/demo_seeder.dart` writes to Firestore.
//
// Why two copies of the same data: the `/map-foundation` screen is a
// developer/demo surface (Google Maps only — no seller markers on
// the production buyer flow). Reading from Firestore on every render
// makes the screen depend on auth + composite indexes that the
// sample project doesn't always have set up. The hand-rolled list
// below keeps the demo screen usable even when offline.
//
// The two arrays are kept in sync manually — when you add/remove a
// seller in `demo_seeder.dart`, mirror the change here.

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Plain-data representation of one demo seller position. We keep
/// just the fields the map widget actually renders.
class DemoSellerMarker {
  final String id;
  final String name;
  final String fish;
  final double latitude;
  final double longitude;

  const DemoSellerMarker({
    required this.id,
    required this.name,
    required this.fish,
    required this.latitude,
    required this.longitude,
  });

  LatLng get position => LatLng(latitude, longitude);
}

/// Five sellers at Stone Town — matches the placements in
/// `lib/services/demo_seeder.dart`.
const List<DemoSellerMarker> demoSellerMarkers = [
  DemoSellerMarker(
    id: 'fatma-tuna',
    name: 'Fatma Tuna Specialist',
    fish: 'Tuna · Mackerel',
    latitude: -6.1608,
    longitude: 39.2040,
  ),
  DemoSellerMarker(
    id: 'babu-tilapia',
    name: 'Babu Tilapia',
    fish: 'Tilapia · Tuna',
    latitude: -6.1616,
    longitude: 39.2010,
  ),
  DemoSellerMarker(
    id: 'sara-fish',
    name: 'Sara Mixed Fish',
    fish: 'Sardine · Snapper',
    latitude: -6.1642,
    longitude: 39.2055,
  ),
  DemoSellerMarker(
    id: 'kwame-market',
    name: 'Kwame Market Stall',
    fish: 'Tuna · Grouper',
    latitude: -6.1599,
    longitude: 39.1999,
  ),
  DemoSellerMarker(
    id: 'mama-zainab',
    name: 'Mama Zainab',
    fish: 'Snapper · Mackerel',
    latitude: -6.1665,
    longitude: 39.2025,
  ),
];

/// Rotating tints so adjacent demo pins are easy to tell apart.
/// [BitmapDescriptor.defaultMarkerWithHue] takes a double in
/// `[0.0, 360.0)` per the google_maps_flutter docs.
const List<double> _demoMarkerHues = [
  BitmapDescriptor.hueRed,
  BitmapDescriptor.hueOrange,
  BitmapDescriptor.hueYellow,
  BitmapDescriptor.hueGreen,
  BitmapDescriptor.hueBlue,
];

/// Returns the markers as `Marker` objects ready to pass to a
/// `GoogleMap.markers: ...` set.
Set<Marker> buildDemoSellerMarkerSet() {
  return {
    for (var i = 0; i < demoSellerMarkers.length; i++)
      Marker(
        markerId: MarkerId('demo_seller_${demoSellerMarkers[i].id}'),
        position: demoSellerMarkers[i].position,
        infoWindow: InfoWindow(
          title: demoSellerMarkers[i].name,
          snippet: demoSellerMarkers[i].fish,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _demoMarkerHues[i % _demoMarkerHues.length],
        ),
      ),
  };
}
