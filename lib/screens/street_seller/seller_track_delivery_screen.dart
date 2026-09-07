import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../l10n/app_localizations.dart';
import '../../models/enums/order_status.dart';
import '../../models/order_model.dart';
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

  @override
  void dispose() {
    // Make sure the live mirror stops when the screen is left mid-delivery.
    ref.read(orderTrackingProvider).stopSharingLocation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderStreamProvider(widget.orderId));
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.trackOrder, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001E45))),
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
                const SizedBox(height: 16),
                _buildMapCard(order, cs),
                const SizedBox(height: 32),
                HorizontalOrderTimeline(currentStatus: order.status),
                const SizedBox(height: 32),
                _buildETASection(order, cs),
                const SizedBox(height: 24),
                _buildContactButton(cs),
                const SizedBox(height: 24),
                _buildActionButtons(order, cs),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text("${AppLocalizations.of(context).errorLoadingOrder}: ${e.toString()}")),
      ),
    );
  }

  Widget _buildStatusHeader(OrderModel order, ColorScheme cs) {
    String statusText;
    Color iconBg;
    IconData icon;

    if (order.isDisputed) {
      statusText = '⚠️ Order Disputed — Pending Admin Review';
      iconBg = const Color(0xFFD97706);
      icon = Icons.report_problem_rounded;
    } else if (order.buyerConfirmed) {
      statusText = 'Order Completed ✅';
      iconBg = Colors.green;
      icon = Icons.verified_rounded;
    } else if (order.status == OrderStatus.completed) {
      statusText = 'Delivered — Awaiting Buyer Confirmation';
      iconBg = const Color(0xFF0369A1);
      icon = Icons.schedule_rounded;
    } else if (order.status == OrderStatus.outForDelivery) {
      statusText = 'Out for Delivery 🚴';
      iconBg = cs.primary;
      icon = Icons.directions_bike;
    } else if (order.status == OrderStatus.preparing) {
      statusText = 'Preparing Fish 🐟';
      iconBg = cs.primary;
      icon = Icons.restaurant_menu;
    } else if (order.status == OrderStatus.confirmed) {
      statusText = 'Order Accepted 🔒';
      iconBg = const Color(0xFF0369A1);
      icon = Icons.check_circle_outline;
    } else if (order.status == OrderStatus.cancelled) {
      statusText = 'Order Cancelled';
      iconBg = Colors.red;
      icon = Icons.cancel_rounded;
    } else {
      statusText = 'New Order Request';
      iconBg = Colors.grey;
      icon = Icons.notifications_active_rounded;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: iconBg.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          statusText,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF001E45)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Order #${order.orderId.substring(0, order.orderId.length > 8 ? 8 : order.orderId.length).toUpperCase()}',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildMapCard(OrderModel order, ColorScheme cs) {
    return Container(
      height: 260,
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
    ll.LatLng sellerLatLng;
    final liveSellerLoc = ref.watch(sellerLocationTrackerProvider).lastPosition;
    if (liveSellerLoc != null) {
      sellerLatLng = ll.LatLng(liveSellerLoc.latitude, liveSellerLoc.longitude);
    } else if (order.streetSellerLocation != null) {
      sellerLatLng = ll.LatLng(order.streetSellerLocation!.latitude, order.streetSellerLocation!.longitude);
    } else {
      sellerLatLng = const ll.LatLng(-6.1645, 39.2040);
    }

    ll.LatLng buyerLatLng;
    if (order.buyerLocation != null) {
      buyerLatLng = ll.LatLng(order.buyerLocation!.latitude, order.buyerLocation!.longitude);
    } else {
      final buyerLoc = ref.watch(currentBuyerLocationProvider).valueOrNull;
      buyerLatLng = buyerLoc != null
          ? ll.LatLng(buyerLoc.latitude, buyerLoc.longitude)
          : const ll.LatLng(-6.1629, 39.2026);
    }

    final markers = <Marker>[
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
    ];

    final routeAsync = ref.watch(trackingRouteProvider(widget.orderId));
    final routeResult = routeAsync.valueOrNull;
    final isOsrm = routeResult != null &&
        routeResult.points.length > 1 &&
        routeResult.source == RouteSource.osrm;
    final polylinePoints = isOsrm
        ? routeResult.points
        : <ll.LatLng>[sellerLatLng, buyerLatLng];

    final polylines = <Polyline>[
      Polyline(
        points: polylinePoints,
        strokeWidth: 5,
        color: const Color(0xFF0284C7),
        pattern: isOsrm
            ? const StrokePattern.solid()
            : const StrokePattern.dotted(),
        borderColor: Colors.white,
        borderStrokeWidth: 2,
      ),
    ];

    final center = ll.LatLng(
      (buyerLatLng.latitude + sellerLatLng.latitude) / 2,
      (buyerLatLng.longitude + sellerLatLng.longitude) / 2,
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

  Widget _buildETASection(OrderModel order, ColorScheme cs) {
    final routeAsync = ref.watch(trackingRouteProvider(widget.orderId));
    final route = routeAsync.valueOrNull;
    final isFallback = route == null || route.source == RouteSource.fallback;

    Widget row({required IconData icon, required String label, required String value}) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey, size: 24),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
          Text(value, style: TextStyle(color: cs.primary, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      );
    }

    String etaText() {
      if (order.buyerConfirmed) return 'Delivered ✅';
      if (order.isDisputed) return 'Disputed ⚠️';
      if (order.status == OrderStatus.completed) return 'Arrived — Awaiting Buyer';
      if (order.status == OrderStatus.cancelled) return 'Cancelled';
      if (route != null) return formatRouteEta(route.durationMinutes);
      return 'Calculating...';
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
          row(icon: Icons.straighten, label: 'Distance', value: route != null ? formatRouteDistance(route.distanceKm) : '—'),
          if (isFallback && !order.buyerConfirmed) ...[
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
                  Icon(Icons.info_outline, size: 14, color: Color(0xFF0369A1)),
                  SizedBox(width: 6),
                  Text('Estimate — live routing unavailable',
                      style: TextStyle(color: Color(0xFF075985), fontSize: 12)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactButton(ColorScheme cs) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(Icons.phone, color: cs.primary),
        label: Text(
          'Contact Buyer',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.primary),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cs.primary, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order, ColorScheme cs) {
    final notifier = ref.read(orderTrackingProvider);
    final l10n = AppLocalizations.of(context);

    if (order.status == OrderStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => notifier.updateOrderStatus(order, OrderStatus.cancelled),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(l10n.rejectOrder, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => notifier.updateOrderStatus(order, OrderStatus.confirmed),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(l10n.acceptOrder, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    } else if (order.status == OrderStatus.confirmed) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => notifier.updateOrderStatus(order, OrderStatus.preparing),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(l10n.startPreparingFish, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    } else if (order.status == OrderStatus.preparing) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => notifier.updateOrderStatus(order, OrderStatus.outForDelivery),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('🚴 Start Delivery — Proceed to Buyer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      );
    } else if (order.status == OrderStatus.readyForPickup) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => notifier.updateOrderStatus(order, OrderStatus.outForDelivery),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('🚴 Start Delivery', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      );
    } else if (order.status == OrderStatus.outForDelivery) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF0284C7), width: 1.5),
        ),
        child: Column(
          children: [
            const Icon(Icons.directions_bike_rounded, color: Color(0xFF0369A1), size: 40),
            const SizedBox(height: 10),
            const Text(
              '🚴 On Your Way to Buyer',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0369A1)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Delivery in progress. After delivering the fish, the buyer will confirm receipt via their app.',
              style: TextStyle(fontSize: 12, color: Color(0xFF075985), height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_clock, color: Color(0xFF0369A1), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Pending Earnings: TZS ${(order.totalPrice * 0.95).toStringAsFixed(0)}',
                    style: const TextStyle(color: Color(0xFF0369A1), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (order.status == OrderStatus.completed) {
      final isReleased = order.buyerConfirmed;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isReleased
                ? [const Color(0xFF15803D), const Color(0xFF16A34A)]
                : [const Color(0xFF1D4ED8), const Color(0xFF0369A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isReleased ? const Color(0xFF15803D) : const Color(0xFF1D4ED8)).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: isReleased
            ? Column(
                children: [
                  const Icon(Icons.verified_rounded, color: Colors.white, size: 44),
                  const SizedBox(height: 10),
                  const Text(
                    '✅ Order Completed — Payout Sent!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _payoutRow('Order Total:', 'TZS ${order.totalPrice.toStringAsFixed(0)}', Colors.white),
                        const SizedBox(height: 6),
                        _payoutRow('Commission (5%):', '- TZS ${order.commissionAmount.toStringAsFixed(0)}', Colors.white70),
                        const Divider(color: Colors.white30, height: 14),
                        _payoutRow('Your Earnings (95%):', 'TZS ${order.sellerEarnings.toStringAsFixed(0)}', const Color(0xFF86EFAC)),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  const Icon(Icons.schedule_rounded, color: Colors.white, size: 44),
                  const SizedBox(height: 10),
                  const Text(
                    '🕐 Awaiting Buyer Confirmation',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Order delivered. The buyer will confirm receipt of the fish, releasing your payout.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_clock, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Your Pending Earnings: TZS ${order.totalPrice > 0 ? (order.totalPrice * 0.95).toStringAsFixed(0) : "0"}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _payoutRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
