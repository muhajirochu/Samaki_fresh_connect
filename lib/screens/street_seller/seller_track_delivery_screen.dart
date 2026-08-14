import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../l10n/app_localizations.dart';
import '../../models/enums/order_status.dart';
import '../../models/order_model.dart';
import '../../providers/buyer_provider.dart';
import '../../providers/order_tracking_provider.dart';
import '../../providers/seller_location_provider.dart';
import '../../providers/tracking_provider.dart';
import '../../services/location_service.dart';
import '../../services/routing_service.dart';
import '../../utils/route_format.dart';
import '../../widgets/timelines/horizontal_order_timeline.dart';

class SellerTrackDeliveryScreen extends ConsumerStatefulWidget {
  final String orderId;

  const SellerTrackDeliveryScreen({super.key, required this.orderId});

  @override
  ConsumerState<SellerTrackDeliveryScreen> createState() => _SellerTrackDeliveryScreenState();
}

class _SellerTrackDeliveryScreenState extends ConsumerState<SellerTrackDeliveryScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    // Make sure the live mirror stops when the screen is left mid-delivery.
    ref.read(orderTrackingProvider).stopSharingLocation();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderStreamProvider(widget.orderId));
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    // Start/stop the live seller-position mirror based on order status.
    // The seller side mirrors its own GPS into orders/{orderId}.streetSellerLocation
    // while the delivery is in flight; the buyer's existing orderStreamProvider
    // then re-emits and our `trackingRouteProvider` redraws the polyline.
    ref.listen<AsyncValue<OrderModel?>>(
      orderStreamProvider(widget.orderId),
      (prev, next) {
        final order = next.valueOrNull;
        if (order == null) return;
        final notifier = ref.read(orderTrackingProvider);
        if (order.status == OrderStatus.accepted ||
            order.status == OrderStatus.pickupGenerated ||
            order.status == OrderStatus.arriving) {
          notifier.startSharingLocation(
            orderId: widget.orderId,
            tracker: ref.read(sellerLocationTrackerProvider),
          );
        } else if (order.status == OrderStatus.completed ||
            order.status == OrderStatus.cancelled) {
          notifier.stopSharingLocation();
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.trackDeliveryTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001E45))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF001E45)),
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return Center(child: Text(l10n.orderNotFound));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildStatusHeader(order, cs),
                const SizedBox(height: 24),
                _buildMapCard(order, cs),
                const SizedBox(height: 32),
                HorizontalOrderTimeline(currentStatus: order.status),
                const SizedBox(height: 24),
                _buildPaymentBanner(order, cs),
                const SizedBox(height: 24),
                _buildETASection(order, cs),
                const SizedBox(height: 24),
                _buildActionButtons(order, cs),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading order: $e')),
      ),
    );
  }

  Widget _buildStatusHeader(OrderModel order, ColorScheme cs) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.directions_bike, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          'Delivery ${order.status.name[0].toUpperCase()}${order.status.name.substring(1)}',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF001E45)),
        ),
        const SizedBox(height: 6),
        Text(
          'Order #${order.orderId.substring(0, 8).toUpperCase()}',
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildMapCard(OrderModel order, ColorScheme cs) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _buildMapContent(order, cs),
      ),
    );
  }

  Widget _buildMapContent(OrderModel order, ColorScheme cs) {
    // Resolve buyer location with fallback
    ll.LatLng buyerLatLng;
    if (order.buyerLocation != null) {
      buyerLatLng = ll.LatLng(order.buyerLocation!.latitude, order.buyerLocation!.longitude);
    } else {
      final buyerLoc = ref.watch(currentBuyerLocationProvider).valueOrNull;
      buyerLatLng = buyerLoc != null
          ? ll.LatLng(buyerLoc.latitude, buyerLoc.longitude)
          : const ll.LatLng(-6.1629, 39.2026);
    }

    // Resolve seller location with fallback
    ll.LatLng sellerLatLng;
    if (order.streetSellerLocation != null) {
      sellerLatLng = ll.LatLng(order.streetSellerLocation!.latitude, order.streetSellerLocation!.longitude);
    } else {
      final sellers = ref.watch(activeStreetSellersProvider).valueOrNull ?? const [];
      final match = sellers.where((s) => s.sellerId == order.streetSellerId).firstOrNull;
      if (match != null && (match.latitude != 0 || match.longitude != 0)) {
        sellerLatLng = ll.LatLng(match.latitude, match.longitude);
      } else {
        final pos = ref.read(sellerLocationTrackerProvider).lastPosition;
        sellerLatLng = pos != null
            ? ll.LatLng(pos.latitude, pos.longitude)
            : const ll.LatLng(-6.1645, 39.2040);
      }
    }

    final markers = <Marker>[
      Marker(
        point: buyerLatLng,
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF075985),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 22),
        ),
      ),
      Marker(
        point: sellerLatLng,
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(
            color: cs.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Icon(Icons.directions_bike, color: Colors.white, size: 22),
        ),
      ),
    ];

    final routeAsync = ref.watch(trackingRouteProvider(widget.orderId));
    final routeResult = routeAsync.valueOrNull;
    final isOsrm = routeResult != null &&
        routeResult.points.length > 1 &&
        routeResult.source == RouteSource.osrm;
    final polylinePoints = isOsrm
        ? routeResult.points
        : <ll.LatLng>[sellerLatLng, buyerLatLng];
    final isFallback = !isOsrm;

    final polylines = <Polyline>[
      Polyline(
        points: polylinePoints,
        strokeWidth: 5,
        color: const Color(0xFF0284C7),
        pattern: isFallback
            ? const StrokePattern.dotted()
            : const StrokePattern.solid(),
        borderColor: Colors.white,
        borderStrokeWidth: 2,
      ),
    ];

    final center = ll.LatLng(
      (buyerLatLng.latitude + sellerLatLng.latitude) / 2, 
      (buyerLatLng.longitude + sellerLatLng.longitude) / 2
    );

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14.0,
        minZoom: 3,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.samakifresh.connect',
          maxZoom: 19,
        ),
        PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildPaymentBanner(OrderModel order, ColorScheme cs) {
    if (order.isPaid) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0284C7), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF0284C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✅ AMELIPA (ORDER PAID)',
                    style: TextStyle(
                      color: Color(0xFF075985),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.paymentMethod.isNotEmpty
                        ? 'Njia: ${order.paymentMethod}'
                        : 'Mnunuzi amelipia mtandaoni kikamilifu',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  if (order.paymentReference.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Ref: ${order.paymentReference}',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFBAE6FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0284C7), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF0284C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payments_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💵 PESA TASLIMU (CASH ON DELIVERY)',
                  style: TextStyle(
                    color: Color(0xFF075985),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chukua TZS ${order.totalPrice.toStringAsFixed(0)} wakati wa kumkabidhi samaki.',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildETASection(OrderModel order, ColorScheme cs) {
    final routeAsync = ref.watch(trackingRouteProvider(widget.orderId));
    final route = routeAsync.valueOrNull;
    final isFallback = route == null || route.source == RouteSource.fallback;

    Widget row({
      required IconData icon,
      required String label,
      required String value,
    }) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: cs.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    String etaText() {
      if (order.status == OrderStatus.completed) return 'Delivered';
      if (order.status == OrderStatus.cancelled) return 'Cancelled';
      if (route != null) return formatRouteEta(route.durationMinutes);
      return 'Calculating...';
    }

    String distanceText() {
      if (route == null) return '—';
      return formatRouteDistance(route.distanceKm);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: cs.primary.withValues(alpha: 0.3), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          row(icon: Icons.access_time, label: 'ETA', value: etaText()),
          const Divider(height: 24),
          row(icon: Icons.straighten, label: 'Distance', value: distanceText()),
          if (isFallback) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFBAE6FD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Color(0xFF0369A1),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Estimate — live routing unavailable',
                    style: TextStyle(
                      color: Color(0xFF075985),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order, ColorScheme cs) {
    final notifier = ref.read(orderTrackingProvider);

    if (order.status == OrderStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => notifier.updateOrderStatus(order, OrderStatus.cancelled),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Reject', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => notifier.updateOrderStatus(order, OrderStatus.accepted),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16)
              ),
              child: const Text('Accept Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    } else if (order.status == OrderStatus.accepted) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => notifier.updateOrderStatus(order, OrderStatus.preparing),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16)
          ),
          child: const Text('Start Preparing Fish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    } else if (order.status == OrderStatus.preparing) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => notifier.generateAndSetPickupCode(order),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16)
          ),
          child: const Text('Generate Pickup Code & Ready', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    } else if (order.status == OrderStatus.pickupGenerated) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => notifier.updateOrderStatus(order, OrderStatus.arriving),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16)
          ),
          child: const Text('Start Delivery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    } else if (order.status == OrderStatus.arriving) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          border: Border.all(color: const Color(0xFF0284C7), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              'Waiting for Buyer to verify pickup code...',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0284C7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Code: ${order.pickupCode}', 
              style: const TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
            ),
          ],
        ),
      );
    } else if (order.status == OrderStatus.completed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0369A1),
          border: Border.all(color: const Color(0xFF0284C7), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Delivery Completed!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
