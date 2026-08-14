import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/order_model.dart';
import '../services/location_service.dart';
import '../services/routing_service.dart';
import 'order_tracking_provider.dart';
import 'seller_location_provider.dart';
import 'buyer_provider.dart';

/// OSRM-snapped route from the street seller to the buyer for a given
/// order. Recomputes whenever the order's `buyerLocation` or
/// `streetSellerLocation` changes — the underlying [orderStreamProvider]
/// re-emits on any field write, including the live seller position
/// updates produced by `OrderTrackingStateNotifier.startSharingLocation`.
final trackingRouteProvider =
    FutureProvider.autoDispose.family<RouteResult?, String>(
        (ref, orderId) async {
  final orderAsync = ref.watch(orderStreamProvider(orderId));
  final order = orderAsync.valueOrNull;
  if (order == null) return null;

  // Resolve buyer location
  LatLng buyerLatLng;
  if (order.buyerLocation != null) {
    buyerLatLng = LatLng(
      order.buyerLocation!.latitude,
      order.buyerLocation!.longitude,
    );
  } else {
    final buyerLoc = ref.read(currentBuyerLocationProvider).valueOrNull;
    if (buyerLoc != null) {
      buyerLatLng = LatLng(buyerLoc.latitude, buyerLoc.longitude);
    } else {
      buyerLatLng = const LatLng(-6.1629, 39.2026);
    }
  }

  // Resolve seller location
  LatLng sellerLatLng;
  if (order.streetSellerLocation != null) {
    sellerLatLng = LatLng(
      order.streetSellerLocation!.latitude,
      order.streetSellerLocation!.longitude,
    );
  } else {
    // Look up seller in activeStreetSellersProvider
    final sellers = ref.read(activeStreetSellersProvider).valueOrNull ?? const [];
    final sellerMatch = sellers.where((s) => s.sellerId == order.streetSellerId).firstOrNull;
    if (sellerMatch != null && (sellerMatch.latitude != 0 || sellerMatch.longitude != 0)) {
      sellerLatLng = LatLng(sellerMatch.latitude, sellerMatch.longitude);
    } else {
      final pos = ref.read(sellerLocationTrackerProvider).lastPosition;
      if (pos != null) {
        sellerLatLng = LatLng(pos.latitude, pos.longitude);
      } else {
        sellerLatLng = const LatLng(-6.1645, 39.2040);
      }
    }
  }

  final routing = ref.watch(routingServiceProvider);
  return routing.getRoute(
    from: sellerLatLng,
    to: buyerLatLng,
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
