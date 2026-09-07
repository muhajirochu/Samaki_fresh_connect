// Bottom sheet that opens when a buyer selects a seller. Collects:
//   - Fish name (typed text or pre-filled with the most common fish at
//     that seller),
//   - Quantity (kg) — slider + numeric input,
//   - Additional notes.
//
// On submit it calls `BuyerDashboardController.createFishRequest(...)`
// from Phase 1 and the wishlist controller to remember the fish type
// (so the Phase-4 cross-trigger can fire when stock returns).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums/fish_type.dart';
import '../../models/enums/notification_type.dart';
import '../../models/enums/order_status.dart';
import '../../models/map_filter_model.dart';
import '../../models/order_model.dart';
import '../../models/fish_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../payment/test_payment_sheet.dart';

import '../../services/order_tracking_service.dart';
import '../../services/location_service.dart';
import '../../utils/formatters.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SendRequestSheet extends ConsumerStatefulWidget {
  /// Pre-fills the fish-type dropdown with whatever the seller is
  /// currently offering, if any. When null, defaults to Tuna.
  final SellerWithFish? selectedSeller;
  final FishType? prefillFishType;

  const SendRequestSheet({
    super.key,
    this.selectedSeller,
    this.prefillFishType,
  });

  /// Convenience: show this sheet from anywhere with a `ScaffoldMessenger`.
  static Future<void> show({
    required BuildContext context,
    SellerWithFish? seller,
    FishType? prefillFishType,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SendRequestSheet(
          selectedSeller: seller,
          prefillFishType: prefillFishType,
        ),
      ),
    );
  }

  @override
  ConsumerState<SendRequestSheet> createState() => _SendRequestSheetState();
}

class _SendRequestSheetState extends ConsumerState<SendRequestSheet> {
  FishItemModel? _selectedItem;
  late TextEditingController _notesCtrl;
  double _quantityKg = 2.0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final items = widget.selectedSeller?.matchingItems ?? [];
    if (items.isNotEmpty) {
      if (widget.prefillFishType != null) {
        _selectedItem = items.firstWhere(
          (i) => i.fishType == widget.prefillFishType,
          orElse: () => items.first,
        );
      } else {
        _selectedItem = items.first;
      }
    }
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final l10n = AppLocalizations.of(context);
      final messenger = ScaffoldMessenger.of(context);

      final seller = widget.selectedSeller;
      final buyer = ref.read(currentUserStreamProvider).valueOrNull;
      if (seller == null || seller.matchingItems.isEmpty || buyer == null) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Imeshindwa kutuma agizo. Tafadhali jaribu tena.'),
          backgroundColor: AppColors.primaryTealDark,
        ));
        return;
      }

      final item = _selectedItem;
      if (item == null) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Tafadhali chagua samaki kwanza.'),
          backgroundColor: AppColors.errorRed,
        ));
        return;
      }

      final totalPrice = item.totalPrice * 1.07;

      // 1. FIRST REQUIRE PAYMENT / PAYMENT CONFIRMATION STEP
      final paymentResult = await TestPaymentSheet.show(
        context: context,
        orderId: 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
        amount: totalPrice,
        fishName: item.displayName,
        onPaymentSuccess: () {},
      );

      // If user canceled or payment failed, DO NOT CREATE ORDER / DO NOT SEND REQUEST
      if (paymentResult == null || !paymentResult.isSuccess) {
        if (mounted) {
          messenger.showSnackBar(const SnackBar(
            content: Text('Ombi halikutumwa kwa sababu malipo hajayathibitishwa.'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      final orderService = ref.read(orderTrackingServiceProvider);
      final buyerLoc = await ref.read(currentBuyerLocationProvider.future);
      
      final order = OrderModel(
        orderId: '',
        buyerId: buyer.userId,
        streetSellerId: item.sellerId,
        fishId: item.listingId,
        totalPrice: totalPrice,
        quantity: item.quantityKg.toInt(),
        status: OrderStatus.pending,
        isPaid: paymentResult.isPaid,
        paymentMethod: paymentResult.paymentMethod,
        paymentReference: paymentResult.paymentReference,
        buyerLocation: GeoPoint(buyerLoc.latitude, buyerLoc.longitude),
        streetSellerLocation: (item.latitude != null && item.longitude != null) 
            ? GeoPoint(item.latitude!, item.longitude!) 
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final orderId = await orderService.createOrder(order);
      if (orderId.isEmpty) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Imeshindwa kutuma agizo. Tafadhali jaribu tena.'),
          backgroundColor: AppColors.errorRed,
        ));
        return;
      }

      // Notify the seller so the bell + dashboard badge light up.
      final notifSvc = ref.read(notificationServiceProvider);
      final firstName = buyer.fullName.split(' ').first;
      await notifSvc.writeNotification(
        userId: item.sellerId,
        title: l10n.orderPlacedSellerTitle,
        body: l10n.orderPlacedSellerBody(firstName),
        type: NotificationType.orderStatusChanged,
        relatedId: orderId,
      );
      await notifSvc.showLocal(
        title: l10n.orderPlacedSellerTitle,
        body: l10n.orderPlacedSellerBody(firstName),
        type: NotificationType.orderStatusChanged,
      );

      if (mounted) {
        Navigator.of(context).pop();
        messenger.showSnackBar(SnackBar(
          content: Text(
            'Agizo limepokelewa! ${item.displayName} · '
            '${item.quantityKg.toStringAsFixed(1)} kg',
          ),
          backgroundColor: AppColors.primaryTeal,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hitilafu: $e'),
          backgroundColor: AppColors.errorRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seller = widget.selectedSeller;
    final theme = Theme.of(context);
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Material(
      color: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXL),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingLG,
            AppSizes.paddingSM,
            AppSizes.paddingLG,
            AppSizes.paddingLG,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMD),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                      ),
                      child: Icon(Icons.send_rounded, color: cs.primary),
                    ),
                    const SizedBox(width: AppSizes.paddingMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.sendFishRequest,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (seller != null)
                            Text(
                              l10n.forSeller(seller.seller.fullName),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.70),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingLG),

                // ── Fish Selection ─────────────────────────────────────────
                Text(
                  l10n.selectFishLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.80),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXS),
                if (seller != null && seller.matchingItems.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: seller.matchingItems.length,
                      separatorBuilder: (_, __) => const SizedBox(width: AppSizes.paddingSM),
                      itemBuilder: (context, index) {
                        final item = seller.matchingItems[index];
                        final isSelected = _selectedItem?.itemId == item.itemId;
                        
                        return GestureDetector(
                          onTap: () => setState(() => _selectedItem = item),
                          child: Container(
                            width: 100,
                            decoration: BoxDecoration(
                              color: isSelected ? cs.primary.withValues(alpha: 0.1) : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                              border: Border.all(
                                color: isSelected ? cs.primary : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusMD - 2)),
                                    child: item.imageUrls.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: item.imageUrls.first,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                            errorWidget: (_, __, ___) => const Icon(Icons.set_meal, color: Colors.grey),
                                          )
                                        : const Icon(Icons.set_meal, color: Colors.grey, size: 40),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        item.displayName,
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isSelected ? cs.primary : cs.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                      Text(
                                        '${item.pricePerKg.toStringAsFixed(0)} /kg',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: cs.onSurface.withValues(alpha: 0.7),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Text(
                    l10n.noFishAvailable,
                    style: TextStyle(color: cs.error),
                  ),

                const SizedBox(height: AppSizes.paddingLG),

                // ── Quantity slider ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.quantityKgLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.80),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingSM,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.10),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusSM),
                      ),
                      child: Text(
                        '${_quantityKg.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _quantityKg,
                  min: 0.5,
                  max: 20.0,
                  divisions: 39,
                  label: '${_quantityKg.toStringAsFixed(1)} kg',
                  activeColor: cs.primary,
                  onChanged: (v) => setState(() => _quantityKg = v),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        decoration: InputDecoration(
                          hintText: l10n.enterQuantityHint,
                          filled: true,
                          fillColor: cs.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMD),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingMD,
                            vertical: AppSizes.paddingSM,
                          ),
                        ),
                        onChanged: (v) {
                          final parsed = double.tryParse(v);
                          if (parsed != null && parsed > 0) {
                            setState(() => _quantityKg =
                                parsed.clamp(0.5, 20.0).toDouble());
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingMD),
                // ── Total Price ──────────────────────────────────────────────
                if (_selectedItem != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.paddingMD),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                      border: Border.all(
                        color: AppColors.accentOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.totalAmountLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(_quantityKg * _selectedItem!.pricePerKg),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: AppSizes.paddingLG),

                // ── Notes ───────────────────────────────────────────────────
                Text(
                  l10n.additionalNotesLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.80),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXS),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: l10n.notesHint,
                    filled: true,
                    fillColor: cs.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMD),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.paddingLG),

                // ── Submit ──────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: AppSizes.buttonHeightLG,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onPrimary,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(_submitting
                        ? l10n.sending
                        : l10n.sendRequest),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLG),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}