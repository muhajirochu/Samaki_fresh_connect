import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:samakifresh_connect/models/order_model.dart';
import '../../constants/app_sizes.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/cards/order_card.dart';
import '../../widgets/common/common_widgets.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Orders',
            style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        centerTitle: true,
      ),
      body: userAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => EmptyStateWidget(
          icon: Icons.error_rounded,
          title: 'Error loading user data',
          subtitle: e.toString(),
        ),
        data: (user) {
          if (user == null) return const SizedBox.shrink();

          // Select the right provider based on role
          late final StreamProvider<List<OrderModel>> provider;
          if (user.role.name == 'buyer') {
            provider = buyerOrdersProvider(user.userId);
          } else if (user.role.name == 'streetSeller') {
            provider = streetSellerOrdersProvider(user.userId);
          } else {
            return const EmptyStateWidget(
              icon: Icons.receipt_long_rounded,
              title: 'No Orders',
              subtitle: 'Order tracking is for buyers and sellers.',
            );
          }

          final ordersAsync = ref.watch(provider);

          return ordersAsync.when(
            loading: () =>
                const LoadingIndicator(message: 'Loading your orders...'),
            error: (error, _) => EmptyStateWidget(
              icon: Icons.error_outline_rounded,
              title: 'Failed to load orders',
              subtitle: error.toString(),
              onRetry: () => ref.refresh(provider),
            ),
            data: (orders) {
              if (orders.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.receipt_long_rounded,
                  title: 'No Orders Found',
                  subtitle: 'You haven\'t made any transactions yet.',
                  onRetry: () => ref.refresh(provider),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.refresh(provider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.paddingLG),
                  itemCount: orders.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSizes.paddingMD),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return OrderCard(
                      order: order,
                      onTap: () => context.push('/orders/${order.orderId}'),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
