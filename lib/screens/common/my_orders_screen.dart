import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:samakifresh_connect/models/order_model.dart';
import '../../config/route_paths.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/cards/order_card.dart';
import '../../widgets/common/common_widgets.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final userAsync = ref.watch(currentUserStreamProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.myOrders,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        centerTitle: true,
      ),
      body: userAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => EmptyStateWidget(
          icon: Icons.error_rounded,
          title: l10n.failedToLoadUserData,
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
            return EmptyStateWidget(
              icon: Icons.receipt_long_rounded,
              title: l10n.noOrdersYet,
              subtitle: l10n.orderTrackingExplanation,
            );
          }

          final ordersAsync = ref.watch(provider);

          return ordersAsync.when(
            loading: () =>
                LoadingIndicator(message: l10n.loadingYourOrders),
            error: (error, _) => EmptyStateWidget(
              icon: Icons.error_outline_rounded,
              title: l10n.failedToLoadOrders,
              subtitle: error.toString(),
              onRetry: () => ref.refresh(provider),
            ),
            data: (orders) {
              if (orders.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.receipt_long_rounded,
                  title: l10n.noOrdersFound,
                  subtitle: l10n.noOrdersPrompt,
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
                      onTap: () => context.pushNamed(
                        AppRouteNames.orderDetail,
                        pathParameters: {'id': order.orderId},
                      ),
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
