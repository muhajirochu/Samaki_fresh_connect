// Route provider — fetches an OSRM polyline from the buyer's current
// location to the selected seller. Recomputes when the selection or the
// buyer's location changes.

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/map_filter_model.dart';
import '../services/location_service.dart';
import '../services/routing_service.dart';

/// Active route from buyer to currently-selected seller.
/// Returns `null` while loading or when no seller is selected.
final activeRouteProvider = FutureProvider<RouteResult?>((ref) async {
  final selection = ref.watch(selectedSellerControllerProvider).selected;
  if (selection == null) return null;

  final buyerAsync = ref.watch(currentBuyerLocationProvider);
  final buyer = buyerAsync.valueOrNull;
  if (buyer == null) return null;

  final routing = ref.watch(routingServiceProvider);
  return routing.getRoute(
    from: LatLng(buyer.latitude, buyer.longitude),
    to: selection.position,
  );
});
