import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../l10n/app_localizations.dart';
import '../../models/enums/order_status.dart';
import '../../models/order_model.dart';
import '../../providers/order_tracking_provider.dart';
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
    _codeController.dispose();
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
                const SizedBox(height: 32),
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
    if (order.buyerLocation == null && order.streetSellerLocation == null) {
      final l10n = AppLocalizations.of(context);
      return Container(
        color: cs.surfaceContainerHighest,
        child: Center(child: Text(l10n.locationNotAvailable)),
      );
    }
    
    final markers = <Marker>[];
    final polylines = <Polyline>[];
    ll.LatLng? buyerLatLng;
    ll.LatLng? sellerLatLng;
    
    if (order.buyerLocation != null) {
      buyerLatLng = ll.LatLng(order.buyerLocation!.latitude, order.buyerLocation!.longitude);
      markers.add(
        Marker(
          point: buyerLatLng,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ),
      );
    }

    if (order.streetSellerLocation != null) {
      sellerLatLng = ll.LatLng(order.streetSellerLocation!.latitude, order.streetSellerLocation!.longitude);
      markers.add(
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
      );
    }
    
    if (buyerLatLng != null && sellerLatLng != null) {
      polylines.add(
        Polyline(
          points: [sellerLatLng, buyerLatLng],
          strokeWidth: 5,
          color: cs.primary,
        ),
      );
    }
    
    ll.LatLng center;
    if (buyerLatLng != null && sellerLatLng != null) {
      center = ll.LatLng(
        (buyerLatLng.latitude + sellerLatLng.latitude) / 2, 
        (buyerLatLng.longitude + sellerLatLng.longitude) / 2
      );
    } else if (buyerLatLng != null) {
      center = buyerLatLng;
    } else {
      center = sellerLatLng!;
    }

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
        if (polylines.isNotEmpty)
          PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildETASection(OrderModel order, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: cs.primary.withValues(alpha: 0.3), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.grey, size: 24),
              const SizedBox(width: 12),
              Text(
                'Estimated Arrival',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Text(
            order.status == OrderStatus.completed
                ? 'Delivered'
                : order.status == OrderStatus.cancelled
                    ? 'Cancelled'
                    : order.estimatedArrival != null
                        ? '${order.estimatedArrival!.hour}:${order.estimatedArrival!.minute.toString().padLeft(2, '0')} AM'
                        : 'Calculating...',
            style: TextStyle(color: cs.primary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
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
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade300, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              'Waiting for Buyer to verify pickup code...',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Code: ${order.pickupCode}', 
              style: const TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ],
        ),
      );
    } else if (order.status == OrderStatus.completed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green.shade300, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Delivery Completed!',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
