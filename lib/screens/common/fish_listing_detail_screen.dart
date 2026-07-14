import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/user_model.dart';
import '../../models/enums/user_role.dart';
import '../../models/fish_listing_model.dart';
import '../../models/order_model.dart';
import '../../models/enums/order_status.dart';
import '../../models/enums/order_path.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../utils/formatters.dart';

class FishListingDetailScreen extends HookConsumerWidget {
  final String listingId;

  const FishListingDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingDetailProvider(listingId));
    final currentUser = ref.watch(currentUserStreamProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Listing Details',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: listingAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => EmptyStateWidget(
          icon: Icons.error_rounded,
          title: 'Error loading listing',
          subtitle: e.toString(),
        ),
        data: (listing) {
          if (listing == null) {
            return const EmptyStateWidget(
              icon: Icons.search_off_rounded,
              title: 'Listing not found',
              subtitle: 'This listing may have been removed.',
            );
          }

          final isOwner = currentUser?.userId == listing.sellerId;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Image Header ──────────────────────────────────────────────
                Stack(
                  children: [
                    Container(
                      height: 320,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      ),
                      child: listing.imageUrls.isNotEmpty
                          ? Image.network(listing.imageUrls.first,
                              fit: BoxFit.cover)
                          : const Center(
                              child: Icon(Icons.set_meal_rounded,
                                  size: 80, color: AppColors.gray400),
                            ),
                    ),
                    // Gradient overlay for better text visibility
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 120,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              listing.fishType,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: listing.status == 'active'
                                  ? AppColors.successGreen
                                  : AppColors.gray600,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              listing.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Content ───────────────────────────────────────────────────
                Transform.translate(
                  offset: const Offset(0, -10),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F7FA),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.all(AppSizes.paddingLG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pricing Grid
                        Container(
                          padding: const EdgeInsets.all(AppSizes.paddingLG),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLG),
                            border: Border.all(color: AppColors.gray200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatColumn(
                                icon: Icons.scale_rounded,
                                label: 'Quantity',
                                value: Formatters.formatQuantity(
                                    listing.quantityKg),
                              ),
                              Container(
                                  width: 1,
                                  height: 40,
                                  color: AppColors.gray200),
                              _StatColumn(
                                icon: Icons.sell_rounded,
                                label: 'Price/kg',
                                value: Formatters.formatCurrency(
                                    listing.pricePerKg),
                              ),
                              Container(
                                  width: 1,
                                  height: 40,
                                  color: AppColors.gray200),
                              _StatColumn(
                                icon: Icons.payments_rounded,
                                label: 'Total',
                                value: Formatters.formatCurrency(
                                    listing.totalPrice),
                                valueColor: AppColors.primaryBlue,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingXL),

                        // Description
                        Text(
                          'Description',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          listing.description?.isEmpty ?? true
                              ? 'No description provided for this listing.'
                              : listing.description!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.gray600,
                                    height: 1.5,
                                  ),
                        ),
                        const SizedBox(height: AppSizes.paddingXXL),

                        // Action Button
                        if (!isOwner && listing.status == 'active')
                          _BuyButton(
                              listing: listing, currentUser: currentUser),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatColumn({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.gray500),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.gray500,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: valueColor ?? AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}

class _BuyButton extends HookConsumerWidget {
  final FishListingModel listing;
  final UserModel? currentUser;

  const _BuyButton({required this.listing, required this.currentUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);

    Future<void> placeOrder() async {
      if (currentUser == null) return;
      isLoading.value = true;

      try {
        final orderService = ref.read(orderServiceProvider);

        final order = OrderModel(
          orderId: '', // Service sets this
          orderPath: OrderPath.directFromDalali.name,
          buyerId: currentUser!.userId, // Can be buyer or street seller
          streetSellerId: currentUser!.role == UserRole.streetSeller
              ? currentUser!.userId
              : null,
          listingId: listing.listingId,
          originalPrice: listing.totalPrice,
          finalPrice: listing.totalPrice * 1.07,
          quantityKg: listing.quantityKg,
          orderStatus: OrderStatus.placed.name,
          pickupConfirmed: false,
          deliveryConfirmed: false,
          createdAt: DateTime.now(),
        );

        final orderId = await orderService.createOrder(order);

        // Deduct quantity instead of marking as sold — the fish stays
        // visible to other buyers until stock reaches 0.
        final listingService = ref.read(fishListingServiceProvider);
        final remainingQty = listing.quantityKg - listing.quantityKg; // full purchase
        if (remainingQty <= 0) {
          await listingService.markAsSold(listing.listingId);
        } else {
          await listingService.updateListing(listing.listingId, {
            'quantityKg': remainingQty,
          });
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order placed successfully!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
          context.pushReplacement('/orders/$orderId');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: $e'),
                backgroundColor: AppColors.errorRed),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CustomButton(
        label:
            'Purchase Now - ${Formatters.formatCurrency(listing.totalPrice * 1.07)}',
        isLoading: isLoading.value,
        onPressed: placeOrder,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
