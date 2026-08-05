import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/enums/order_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_tracking_provider.dart';
import 'seller_track_delivery_screen.dart';

class SellerActiveDeliveryTab extends ConsumerWidget {
  const SellerActiveDeliveryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserStreamProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final ordersAsync = ref.watch(sellerOrdersProvider(user.userId));
    return ordersAsync.when(
      data: (orders) {
        final activeOrders = orders.where((o) => o.status.index < OrderStatus.completed.index && o.status != OrderStatus.cancelled).toList();
        if (activeOrders.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text('No active deliveries to track', style: TextStyle(fontSize: 18, color: Colors.grey)),
            ),
          );
        }
        // Show the most recent active order
        return SellerTrackDeliveryScreen(orderId: activeOrders.first.orderId);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
