// Edit listing screen for street sellers / dalalis. Pre-fills the form
// from the listing detail, validates ownership through the controller,
// and writes back via `ListingManagementController.updateListing`.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/enums/listing_status.dart';
import '../../models/fish_listing_model.dart';
import '../../providers/listing_provider.dart';
import '../../utils/formatters.dart';

class EditListingScreen extends ConsumerStatefulWidget {
  final String listingId;
  const EditListingScreen({super.key, required this.listingId});

  @override
  ConsumerState<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends ConsumerState<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fishTypeCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  FishListingModel? _current;

  @override
  void dispose() {
    _fishTypeCtrl.dispose();
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _seedFromListing(FishListingModel listing) {
    if (_initialized) return;
    _current = listing;
    _fishTypeCtrl.text = listing.fishType;
    _quantityCtrl.text = listing.quantityKg.toString();
    _priceCtrl.text = listing.pricePerKg.toString();
    _descCtrl.text = listing.description ?? '';
    _initialized = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final quantity = double.tryParse(_quantityCtrl.text.trim()) ?? 0;
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final total = quantity * price;
    final desc = _descCtrl.text.trim();

    final result = await ref
        .read(listingManagementControllerProvider.notifier)
        .updateListing(
          listingId: widget.listingId,
          fishType: _fishTypeCtrl.text.trim(),
          quantityKg: quantity,
          pricePerKg: price,
          totalPrice: total,
          description: desc.isEmpty ? null : desc,
        );

    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing updated'),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Update failed'),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(listingDetailProvider(widget.listingId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Edit Listing',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_current != null)
            TextButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, color: Colors.white),
              label: const Text(
                'Save',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingLG),
            child: Text('Could not load listing: $e',
                textAlign: TextAlign.center),
          ),
        ),
        data: (listing) {
          if (listing == null) {
            return const Center(child: Text('Listing not found'));
          }
          _seedFromListing(listing);
          // Block edits if the listing is sold/expired.
          final blocked = listing.status == ListingStatus.sold.value ||
              listing.status == ListingStatus.expired.value;
          return AbsorbPointer(
            absorbing: blocked,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingLG),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (blocked)
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSizes.paddingMD),
                        padding: const EdgeInsets.all(AppSizes.paddingMD),
                        decoration: BoxDecoration(
                          color: AppColors.warningAmber.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMD),
                          border: Border.all(
                              color: AppColors.warningAmber
                                  .withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded,
                                color: AppColors.warningAmber),
                            const SizedBox(width: AppSizes.paddingSM),
                            Expanded(
                              child: Text(
                                'This listing is ${listing.status} and can\'t be edited.',
                                style: const TextStyle(
                                    color: AppColors.gray800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const _Label('Fish type'),
                    TextFormField(
                      controller: _fishTypeCtrl,
                      decoration: _inputDeco('e.g. Tuna'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: AppSizes.paddingMD),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Label('Quantity (kg)'),
                              TextFormField(
                                controller: _quantityCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*')),
                                ],
                                decoration: _inputDeco('0.0'),
                                validator: (v) {
                                  final n = double.tryParse(v?.trim() ?? '');
                                  if (n == null || n <= 0) {
                                    return 'Enter a positive number';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Label('Price / kg (TZS)'),
                              TextFormField(
                                controller: _priceCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*')),
                                ],
                                decoration: _inputDeco('0'),
                                validator: (v) {
                                  final n = double.tryParse(v?.trim() ?? '');
                                  if (n == null || n <= 0) {
                                    return 'Enter a positive number';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_quantityCtrl.text.isNotEmpty &&
                        _priceCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.paddingXS),
                      _TotalPreview(
                        quantity: double.tryParse(_quantityCtrl.text) ?? 0,
                        price: double.tryParse(_priceCtrl.text) ?? 0,
                      ),
                    ],
                    const SizedBox(height: AppSizes.paddingMD),
                    const _Label('Description'),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration:
                          _inputDeco('Optional notes for buyers'),
                    ),
                    const SizedBox(height: AppSizes.paddingXL),
                    SizedBox(
                      width: double.infinity,
                      height: AppSizes.buttonHeightLG,
                      child: FilledButton.icon(
                        onPressed:
                            (_saving || blocked) ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(_saving ? 'Saving...' : 'Save changes'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLG),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusMD)),
          borderSide: BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusMD)),
          borderSide:
              BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMD,
          vertical: AppSizes.paddingSM,
        ),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingXS),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.gray700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _TotalPreview extends StatelessWidget {
  final double quantity;
  final double price;
  const _TotalPreview({required this.quantity, required this.price});

  @override
  Widget build(BuildContext context) {
    final total = quantity * price;
    return Padding(
      padding: const EdgeInsets.only(left: AppSizes.paddingXS),
      child: Text(
        'Total: ${Formatters.formatCurrency(total)}',
        style: const TextStyle(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}