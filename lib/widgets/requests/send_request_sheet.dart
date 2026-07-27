// Bottom sheet that opens when a buyer selects a seller. Collects:
//   - Fish name (typed text or pre-filled with the most common fish at
//     that seller),
//   - Quantity (kg) — slider + numeric input,
//   - Additional notes.
//
// On submit it calls `BuyerDashboardController.createFishRequest(...)`
// from Phase 1 and the wishlist controller to remember the fish type
// (so the Phase-4 cross-trigger can fire when stock returns).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/enums/fish_type.dart';
import '../../models/map_filter_model.dart';
import '../../providers/buyer_provider.dart';
import '../../providers/notification_provider.dart';

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
  late FishType _selectedType;
  late TextEditingController _customNameCtrl;
  late TextEditingController _notesCtrl;
  double _quantityKg = 2.0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.prefillFishType ??
        widget.selectedSeller?.matchingItems.first.fishType ??
        FishType.tuna;
    _customNameCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _customNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final controller = ref.read(buyerDashboardControllerProvider.notifier);
      final customName = _selectedType == FishType.other
          ? _customNameCtrl.text.trim()
          : '';
      final requestId = await controller.createFishRequest(
        fishType: _selectedType,
        customFishName: customName,
        quantityKg: _quantityKg,
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        needsBy: DateTime.now().add(const Duration(days: 2)),
      );

      if (requestId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imeshindwa kutuma ombi. Tafadhali jaribu tena.'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
        return;
      }

      // Also add to wishlist so the buyer gets notified when stock
      // returns for this fish type.
      await ref
          .read(wishlistControllerProvider.notifier)
          .addFish(_selectedType);

      if (mounted) {
        Navigator.of(context).pop();
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ombi limepokelewa! ${_selectedType.displayName} · '
              '${_quantityKg.toStringAsFixed(1)} kg',
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Ona',
              textColor: cs.onPrimary,
              onPressed: () {},
            ),
          ),
        );
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
                            'Tuma Ombi la Samaki',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (seller != null)
                            Text(
                              'Kwa: ${seller.seller.fullName}',
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

                // ── Fish type dropdown ─────────────────────────────────────
                Text(
                  'Aina ya samaki',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.80),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXS),
                DropdownButtonFormField<FishType>(
                  initialValue: _selectedType,
                  isExpanded: true,
                  decoration: InputDecoration(
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
                  items: FishType.values
                      .map((t) => DropdownMenuItem<FishType>(
                            value: t,
                            child: Text(t.displayName),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedType = v);
                  },
                ),
                if (_selectedType == FishType.other) ...[
                  const SizedBox(height: AppSizes.paddingSM),
                  TextField(
                    controller: _customNameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Andika jina la samaki',
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMD),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSizes.paddingLG),

                // ── Quantity slider ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kiasi (kg)',
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
                          hintText: 'Weka kiasi',
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
                        onSubmitted: (v) {
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

                const SizedBox(height: AppSizes.paddingLG),

                // ── Notes ───────────────────────────────────────────────────
                Text(
                  'Maelezo mengine',
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
                    hintText:
                        'Mfano: nataka fresh sana, nitalipia kesho asubuhi...',
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
                        ? 'Inatuma...'
                        : 'Tuma Ombi'),
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