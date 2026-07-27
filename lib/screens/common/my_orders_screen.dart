import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      body: RefreshIndicator(
        onRefresh: () async {
          // Re-subscribe both buyer and seller streams so the
          // combined list re-renders from scratch.
          ref.invalidate(currentUserStreamProvider);
          final user = ref.read(currentUserStreamProvider).valueOrNull;
          if (user != null) {
            ref.invalidate(ordersForUserProvider(user.userId));
          }
          await Future<void>.delayed(const Duration(milliseconds: 400));
        },
        child: userAsync.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(
                height: 320,
                child: LoadingIndicator(),
              ),
            ],
          ),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.paddingLG),
            children: [
              SizedBox(
                height: 320,
                child: EmptyStateWidget(
                  icon: Icons.error_rounded,
                  title: l10n.failedToLoadUserData,
                  subtitle: e.toString(),
                  onRetry: () => ref.invalidate(currentUserStreamProvider),
                ),
              ),
            ],
          ),
          data: (user) {
            if (user == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 320, child: SizedBox.shrink()),
                ],
              );
            }

            // A street seller who also buys from other sellers used
            // to see "No Orders Found" because we filtered by role.
            // ordersForUserProvider merges buyer-side + seller-side
            // streams so the user sees every order they participate
            // in regardless of which side they joined on.
            final provider = ordersForUserProvider(user.userId);
            final ordersAsync = ref.watch(provider);
            return ordersAsync.when(
              loading: () => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: 320,
                    child: LoadingIndicator(message: l10n.loadingYourOrders),
                  ),
                ],
              ),
              error: (error, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSizes.paddingLG),
                children: [
                  SizedBox(
                    height: 320,
                    child: EmptyStateWidget(
                      icon: Icons.error_outline_rounded,
                      title: l10n.failedToLoadOrders,
                      subtitle: error.toString(),
                      onRetry: () => ref.invalidate(provider),
                    ),
                  ),
                ],
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSizes.paddingLG),
                    children: [
                      SizedBox(
                        height: 320,
                        child: EmptyStateWidget(
                          icon: Icons.receipt_long_rounded,
                          title: l10n.noOrdersFound,
                          subtitle: l10n.noOrdersPrompt,
                          onRetry: () => ref.invalidate(provider),
                        ),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSizes.paddingLG),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) =>
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}