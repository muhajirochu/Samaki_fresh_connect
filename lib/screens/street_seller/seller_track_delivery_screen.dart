import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/enums/order_status.dart';
import '../../models/order_model.dart';
import '../../providers/order_tracking_provider.dart';

import '../../widgets/timelines/order_timeline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SellerTrackDeliveryScreen extends ConsumerStatefulWidget {
  final String orderId;

  const SellerTrackDeliveryScreen({super.key, required this.orderId});

  @override
  ConsumerState<SellerTrackDeliveryScreen> createState() => _SellerTrackDeliveryScreenState();
}

class _SellerTrackDeliveryScreenState extends ConsumerState<SellerTrackDeliveryScreen> {
  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderStreamProvider(widget.orderId));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Delivery'),
        centerTitle: true,
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }
          return Column(
            children: [
              Expanded(
                flex: 3,
                child: _buildMapPlaceholder(order, cs),
              ),
              Expanded(
                flex: 7,
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBuyerInfo(order, cs),
                          const Divider(height: 32),
                          OrderTimeline(currentStatus: order.status),
                          const SizedBox(height: 24),
                          _buildActionButtons(order),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading order: $e')),
      ),
    );
  }

  Widget _buildMapPlaceholder(OrderModel order, ColorScheme cs) {
    if (order.buyerLocation == null || order.streetSellerLocation == null) {
      return Container(
        color: cs.surfaceContainerHighest,
        child: const Center(child: Text('Location data not available')),
      );
    }
    
    final buyerLatLng = LatLng(order.buyerLocation!.latitude, order.buyerLocation!.longitude);
    final sellerLatLng = LatLng(order.streetSellerLocation!.latitude, order.streetSellerLocation!.longitude);
    
    final markers = {
      Marker(
        markerId: const MarkerId('seller'),
        position: sellerLatLng,
        infoWindow: const InfoWindow(title: 'You'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      Marker(
        markerId: const MarkerId('buyer'),
        position: buyerLatLng,
        infoWindow: const InfoWindow(title: 'Buyer'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };
    
    final polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [sellerLatLng, buyerLatLng],
        color: cs.primary,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };
    
    double minLat = buyerLatLng.latitude < sellerLatLng.latitude ? buyerLatLng.latitude : sellerLatLng.latitude;
    double maxLat = buyerLatLng.latitude > sellerLatLng.latitude ? buyerLatLng.latitude : sellerLatLng.latitude;
    double minLng = buyerLatLng.longitude < sellerLatLng.longitude ? buyerLatLng.longitude : sellerLatLng.longitude;
    double maxLng = buyerLatLng.longitude > sellerLatLng.longitude ? buyerLatLng.longitude : sellerLatLng.longitude;
    
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2),
        zoom: 14.0,
      ),
      markers: markers,
      polylines: polylines,
      onMapCreated: (GoogleMapController controller) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          controller.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(minLat, minLng),
                northeast: LatLng(maxLat, maxLng),
              ),
              50.0,
            ),
          );
        });
      },
      zoomControlsEnabled: false,
      myLocationEnabled: false,
    );
  }

  Widget _buildBuyerInfo(OrderModel order, ColorScheme cs) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: cs.secondaryContainer,
          child: Icon(Icons.person, color: cs.onSecondaryContainer),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Buyer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text('Location Data', style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.call),
          color: cs.primary,
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.chat),
          color: cs.primary,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    final notifier = ref.read(orderTrackingProvider);

    if (order.status == OrderStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => notifier.updateOrderStatus(order, OrderStatus.cancelled),
              child: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => notifier.updateOrderStatus(order, OrderStatus.accepted),
              child: const Text('Accept Order'),
            ),
          ),
        ],
      );
    } else if (order.status == OrderStatus.accepted) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => notifier.updateOrderStatus(order, OrderStatus.preparing),
          child: const Text('Start Preparing Fish'),
        ),
      );
    } else if (order.status == OrderStatus.preparing) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => notifier.generateAndSetPickupCode(order),
          child: const Text('Generate Pickup Code & Ready'),
        ),
      );
    } else if (order.status == OrderStatus.pickupGenerated) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => notifier.updateOrderStatus(order, OrderStatus.arriving),
          child: const Text('Start Delivery'),
        ),
      );
    } else if (order.status == OrderStatus.arriving) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text(
              'Waiting for Buyer to verify pickup code...',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('The code is: ${order.pickupCode}', style: const TextStyle(fontSize: 20, letterSpacing: 2)),
          ],
        ),
      );
    } else if (order.status == OrderStatus.completed) {
      return Center(
        child: Text(
          'Delivery Completed!',
          style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
