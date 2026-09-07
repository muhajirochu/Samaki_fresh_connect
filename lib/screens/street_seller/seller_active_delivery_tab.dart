import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/route_paths.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums/order_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_tracking_provider.dart';
import '../../widgets/cards/order_card.dart';

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
        final activeOrders = orders
            .where((o) =>
                o.status.index < OrderStatus.completed.index &&
                o.status != OrderStatus.cancelled)
            .toList();
        if (activeOrders.isEmpty) {
          return Scaffold(
            body: Center(
              child: Text(
                AppLocalizations.of(context).sellerNoActiveDeliveries,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          );
        }
        return ListView.builder(
          itemCount: activeOrders.length,
          itemBuilder: (context, index) {
            final o = activeOrders[index];
            return OrderCard(
              order: o,
              onTap: () => context.pushNamed(
                AppRouteNames.sellerTrackDelivery,
                pathParameters: {'orderId': o.orderId},
              ),
            );
          },
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(AppLocalizations.of(context).errorGeneric(e.toString())))),
    );
  }
}
