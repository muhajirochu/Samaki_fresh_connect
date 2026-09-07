import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../l10n/app_localizations.dart';

import '../../config/route_paths.dart';
import '../../models/enums/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_tracking_provider.dart';
import '../../widgets/cards/order_card.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserStreamProvider).valueOrNull;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isBuyer = user.role == UserRole.buyer;
    final ordersAsync = isBuyer
        ? ref.watch(buyerOrdersProvider(user.userId))
        : ref.watch(sellerOrdersProvider(user.userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).myOrders),
        centerTitle: true,
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context).noOrders, style: const TextStyle(fontSize: 18)),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderCard(
                order: order,
                onTap: () {
                  if (isBuyer) {
                    context.pushNamed(
                      AppRouteNames.buyerTrackOrder,
                      pathParameters: {'orderId': order.orderId},
                    );
                  } else {
                    context.pushNamed(
                      AppRouteNames.sellerTrackDelivery,
                      pathParameters: {'orderId': order.orderId},
                    );
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(AppLocalizations.of(context).loadingError(e.toString()))),
      ),
    );
  }
}
