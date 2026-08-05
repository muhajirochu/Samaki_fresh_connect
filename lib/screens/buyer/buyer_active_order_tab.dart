import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/enums/order_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_tracking_provider.dart';
import 'buyer_track_order_screen.dart';

class BuyerActiveOrderTab extends ConsumerWidget {
  const BuyerActiveOrderTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserStreamProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final ordersAsync = ref.watch(buyerOrdersProvider(user.userId));
    return ordersAsync.when(
      data: (orders) {
        final activeOrders = orders.where((o) => o.status.index < OrderStatus.completed.index && o.status != OrderStatus.cancelled).toList();
        if (activeOrders.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text('No active orders to track', style: TextStyle(fontSize: 18, color: Colors.grey)),
            ),
          );
        }
        // Show the most recent active order
        return BuyerTrackOrderScreen(orderId: activeOrders.first.orderId);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
