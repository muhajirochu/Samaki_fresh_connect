import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/order_model.dart';
import '../services/routing_service.dart';
import 'order_tracking_provider.dart';

/// OSRM-snapped route from the street seller to the buyer for a given
/// order. Recomputes whenever the order's `buyerLocation` or
/// `streetSellerLocation` changes — the underlying [orderStreamProvider]
/// re-emits on any field write, including the live seller position
/// updates produced by `OrderTrackingStateNotifier.startSharingLocation`.
///
/// Returns `null` while loading or when either endpoint is missing.
final trackingRouteProvider =
    FutureProvider.autoDispose.family<RouteResult?, String>(
        (ref, orderId) async {
  final orderAsync = ref.watch(orderStreamProvider(orderId));
  final order = orderAsync.valueOrNull;
  if (order == null) return null;

  final buyer = order.buyerLocation;
  final seller = order.streetSellerLocation;
  if (buyer == null || seller == null) return null;

  final routing = ref.watch(routingServiceProvider);
  return routing.getRoute(
    from: LatLng(seller.latitude, seller.longitude),
    to: LatLng(buyer.latitude, buyer.longitude),
  );
});

/// Convenience helper that turns `order.buyerLocation` (GeoPoint) into
/// a `LatLng` — both tracking screens use this.
LatLng? buyerLatLngFor(OrderModel o) => o.buyerLocation == null
    ? null
    : LatLng(o.buyerLocation!.latitude, o.buyerLocation!.longitude);

/// Convenience helper that turns `order.streetSellerLocation` (GeoPoint)
/// into a `LatLng`.
LatLng? sellerLatLngFor(OrderModel o) => o.streetSellerLocation == null
    ? null
    : LatLng(o.streetSellerLocation!.latitude, o.streetSellerLocation!.longitude);
