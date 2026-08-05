import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/enums/order_status.dart';
import '../../models/order_model.dart';
import '../../providers/order_tracking_provider.dart';
import '../../widgets/timelines/order_timeline.dart';

class BuyerTrackOrderScreen extends ConsumerStatefulWidget {
  final String orderId;

  const BuyerTrackOrderScreen({super.key, required this.orderId});

  @override
  ConsumerState<BuyerTrackOrderScreen> createState() => _BuyerTrackOrderScreenState();
}

class _BuyerTrackOrderScreenState extends ConsumerState<BuyerTrackOrderScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderStreamProvider(widget.orderId));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
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
                flex: 4,
                child: _buildMapPlaceholder(order, cs),
              ),
              Expanded(
                flex: 6,
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
                          _buildETASection(order, cs),
                          const Divider(height: 32),
                          _buildStreetSellerInfo(order, cs),
                          const Divider(height: 32),
                          OrderTimeline(currentStatus: order.status),
                          const SizedBox(height: 24),
                          _buildPickupVerification(order, cs),
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
        markerId: const MarkerId('buyer'),
        position: buyerLatLng,
        infoWindow: const InfoWindow(title: 'You'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: const MarkerId('seller'),
        position: sellerLatLng,
        infoWindow: const InfoWindow(title: 'Seller'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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

  Widget _buildETASection(OrderModel order, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimated Arrival',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              order.estimatedArrival != null
                  ? '${order.estimatedArrival!.hour}:${order.estimatedArrival!.minute.toString().padLeft(2, '0')}'
                  : 'Pending',
              style: TextStyle(color: cs.onSurface, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            order.status.name.toUpperCase(),
            style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildStreetSellerInfo(OrderModel order, ColorScheme cs) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: cs.primaryContainer,
          child: Icon(Icons.person, color: cs.onPrimaryContainer),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Street Seller', // Would normally fetch street seller profile
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('4.9', style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
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

  Widget _buildPickupVerification(OrderModel order, ColorScheme cs) {
    if (order.status == OrderStatus.completed) {
      return Center(
        child: Text(
          'Order Completed!',
          style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      );
    }
    if (order.status == OrderStatus.arriving || order.status == OrderStatus.pickupGenerated) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pickup Code Verification',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (order.pickupCode.isNotEmpty)
             Text('Your Code: ${order.pickupCode}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 4)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Code',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () async {
                  final success = await ref.read(orderTrackingProvider).verifyPickupCode(
                        order,
                        _codeController.text.trim(),
                      );
                  if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incorrect code. Please try again.')),
                    );
                  }
                },
                child: const Text('Verify'),
              ),
            ],
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
