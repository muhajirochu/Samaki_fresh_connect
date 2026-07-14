import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../features/map/services/gps_service.dart' show GpsFailure;
import '../../models/fish_listing_model.dart';
import '../../models/enums/fish_type.dart';
import '../../models/enums/listing_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../services/location_service.dart';
import '../../utils/logger.dart';
import '../../widgets/common/common_widgets.dart';

class CreateListingScreen extends HookConsumerWidget {
  const CreateListingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final uploadProgress = useState<String?>(null);

    // Form fields
    final selectedFishType = useState<FishType>(FishType.tilapia);
    final quantityController = useTextEditingController();
    final priceController = useTextEditingController();
    final descriptionController = useTextEditingController();

    // Images
    final pickedImages = useState<List<File>>([]);

    // Shop location. The seller captures their position once via the
    // "Set shop location" tile; the result is written to both the
    // listing (so the buyer's geo query picks it up) and the user's doc
    // (so the dashboard / future flows can read it).
    final capturedLocation = useState<BuyerLocation?>(null);
    final capturedLocationLabel = useState<String?>(null);
    final isCapturingLocation = useState<bool>(false);

    // User context
    final user = ref.watch(currentUserStreamProvider).valueOrNull;

    final imagePicker = useMemoized(() => ImagePicker());

    Future<void> pickImages() async {
      final List<XFile> picked = await imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (picked.isNotEmpty) {
        // Limit to 5 images total
        final combined = [
          ...pickedImages.value,
          ...picked.map((x) => File(x.path))
        ];
        pickedImages.value = combined.take(5).toList();
      }
    }

    Future<void> pickFromCamera() async {
      final XFile? picked = await imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (picked != null) {
        final combined = [...pickedImages.value, File(picked.path)];
        pickedImages.value = combined.take(5).toList();
      }
    }

    void showImageSourceSheet() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: AppSizes.paddingLG, horizontal: AppSizes.paddingLG),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingLG),
                Text(
                  'Add Photo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: AppSizes.paddingXL),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SourceButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: AppColors.primaryBlue,
                      onTap: () {
                        Navigator.pop(context);
                        pickImages();
                      },
                    ),
                    _SourceButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: AppColors.secondaryTeal,
                      onTap: () {
                        Navigator.pop(context);
                        pickFromCamera();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingLG),
              ],
            ),
          ),
        ),
      );
    }

    /// Captures the device's current GPS position and reverse-geocodes
    /// it to a human-readable label. Writes the result to the user's
    /// doc so the dashboard reflects the new shop location.
    Future<void> captureShopLocation() async {
      if (isCapturingLocation.value) return;
      isCapturingLocation.value = true;
      try {
        final service = ref.read(listingLocationServiceProvider);
        final result = await service.captureCurrentLocation();

        await result.fold(
          ok: (loc) async {
            capturedLocation.value = loc;
            final label = await service.reverseGeocodeLabel(
              loc.latitude,
              loc.longitude,
            );
            capturedLocationLabel.value = label;

            // Persist to the user's doc so the dashboard / search
            // pick it up even before the listing is created.
            if (user != null) {
              try {
                await service.persistToUserDoc(user.userId, loc);
              } catch (e, st) {
                AppLogger.warning(
                  'Failed to persist user location',
                  e,
                  st,
                );
              }
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    label != null
                        ? 'Shop location set to $label'
                        : 'Shop location captured '
                            '(${loc.latitude.toStringAsFixed(4)}, '
                            '${loc.longitude.toStringAsFixed(4)})',
                  ),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            }
          },
          err: (failure) async {
            final msg = switch (failure) {
              GpsFailure.serviceDisabled =>
                'GPS is off. Please turn on location services.',
              GpsFailure.permissionDenied =>
                'Location permission was denied. Please allow it in settings.',
              GpsFailure.timeout => 'GPS timed out. Please try again.',
              _ => 'Could not capture location. Please try again.',
            };
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            }
          },
        );
      } finally {
        isCapturingLocation.value = false;
      }
    }

    Future<void> submit() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      if (user == null) return;

      isLoading.value = true;
      try {
        // Step 1: Upload images to Cloudinary
        List<String> imageUrls = [];
        if (pickedImages.value.isNotEmpty) {
          uploadProgress.value =
              'Uploading images (0/${pickedImages.value.length})…';
          final cloudinary = ref.read(cloudinaryServiceProvider);
          imageUrls = await cloudinary.uploadImages(
            pickedImages.value,
            folder: 'fish_listings',
            onProgress: (uploaded, total) {
              uploadProgress.value = 'Uploading images ($uploaded/$total)…';
            },
          );
          uploadProgress.value = null;
        }

        // Step 2: Save listing to Firestore
        uploadProgress.value = 'Saving listing…';
        final service = ref.read(fishListingServiceProvider);

        final quantity = double.parse(quantityController.text);
        final price = double.parse(priceController.text);

        final listing = FishListingModel(
          listingId: '', // Generated by service
          sellerId: user.userId,
          fishType: selectedFishType.value.name,
          quantityKg: quantity,
          pricePerKg: price,
          totalPrice: quantity * price,
          description: descriptionController.text.trim(),
          imageUrls: imageUrls,
          status: ListingStatus.active.value,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        );

        await service.createListing(
          listing,
          seller: user,
          // The seller's location travels with their user doc — we pass it
          // explicitly so the listing has lat/lng written at create-time.
          // (No live GPS needed; the service can also try a one-shot
          // fallback if the user doc has no location.)
        );
        uploadProgress.value = null;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing created successfully! 🐟'),
              backgroundColor: AppColors.successGreen,
            ),
          );
          context.pop();
        }
      } catch (e) {
        uploadProgress.value = null;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(AppStrings.postListing,
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLG),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Photos section ─────────────────────────────────────────────
              Text(
                'Photos (up to 5)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: AppSizes.paddingMD),
              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Add photo button
                    if (pickedImages.value.length < 5)
                      GestureDetector(
                        onTap: showImageSourceSheet,
                        child: Container(
                          width: 100,
                          height: 100,
                          margin:
                              const EdgeInsets.only(right: AppSizes.paddingMD),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryBlue.withValues(alpha: 0.05),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLG),
                            border: Border.all(
                              color:
                                  AppColors.primaryBlue.withValues(alpha: 0.3),
                              style: BorderStyle.solid,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_rounded,
                                  color: AppColors.primaryBlue, size: 28),
                              const SizedBox(height: 8),
                              Text(
                                'Add Photo',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Picked images
                    ...pickedImages.value.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final file = entry.value;
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(
                                right: AppSizes.paddingMD),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusLG),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              image: DecorationImage(
                                image: FileImage(file),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 20,
                            child: GestureDetector(
                              onTap: () {
                                final updated = [...pickedImages.value];
                                updated.removeAt(idx);
                                pickedImages.value = updated;
                              },
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: AppColors.errorRed,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.paddingXL),

              // ── Shop location ──────────────────────────────────────────────
              // Sellers tap once to capture their shop's GPS; the result is
              // persisted to the user doc so the buyer-facing geo query
              // picks it up.
              Text(
                'Shop Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: AppSizes.paddingSM),
              _ShopLocationTile(
                isCapturing: isCapturingLocation.value,
                location: capturedLocation.value,
                label: capturedLocationLabel.value,
                onTap: captureShopLocation,
              ),
              const SizedBox(height: AppSizes.paddingXL),

              // ── Fish Type ──────────────────────────────────────────────────
              DropdownButtonFormField<FishType>(
                initialValue: selectedFishType.value,
                decoration: InputDecoration(
                  labelText: AppStrings.fishType,
                  prefixIcon: const Icon(Icons.set_meal_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  ),
                ),
                items: FishType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) selectedFishType.value = val;
                },
              ),
              const SizedBox(height: AppSizes.paddingLG),

              // ── Quantity ───────────────────────────────────────────────────
              CustomTextField(
                label: AppStrings.quantity,
                controller: quantityController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.scale_rounded,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return AppStrings.requiredField;
                  }
                  if (double.tryParse(val) == null) {
                    return 'Enter a valid number';
                  }
                  if (double.parse(val) <= 0) {
                    return 'Quantity must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.paddingLG),

              // ── Price ──────────────────────────────────────────────────────
              CustomTextField(
                label: AppStrings.price,
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.payments_rounded,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return AppStrings.requiredField;
                  }
                  if (double.tryParse(val) == null) {
                    return 'Enter a valid number';
                  }
                  if (double.parse(val) <= 0) {
                    return 'Price must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.paddingLG),

              // ── Description ────────────────────────────────────────────────
              CustomTextField(
                label: AppStrings.description,
                controller: descriptionController,
                maxLines: 3,
                minLines: 3,
              ),
              const SizedBox(height: AppSizes.paddingXXL),

              // ── Progress indicator ─────────────────────────────────────────
              if (uploadProgress.value != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMD),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(width: AppSizes.paddingMD),
                      Expanded(
                        child: Text(
                          uploadProgress.value!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.paddingLG),
              ],

              CustomButton(
                label: AppStrings.submit,
                isLoading: isLoading.value,
                onPressed: submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                  ),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              const SizedBox(height: AppSizes.paddingLG),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tile that shows the captured shop location (or a placeholder) and
/// triggers a one-tap GPS capture when tapped.
class _ShopLocationTile extends StatelessWidget {
  final bool isCapturing;
  final BuyerLocation? location;
  final String? label;
  final VoidCallback onTap;

  const _ShopLocationTile({
    required this.isCapturing,
    required this.location,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = location != null;
    return InkWell(
      onTap: isCapturing ? null : onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        decoration: BoxDecoration(
          color: hasLocation
              ? AppColors.successGreen.withValues(alpha: 0.06)
              : AppColors.primaryBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          border: Border.all(
            color: hasLocation
                ? AppColors.successGreen.withValues(alpha: 0.4)
                : AppColors.primaryBlue.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasLocation
                    ? AppColors.successGreen.withValues(alpha: 0.15)
                    : AppColors.primaryBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusMD),
              ),
              child: isCapturing
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Icon(
                      hasLocation
                          ? Icons.check_circle_rounded
                          : Icons.my_location_rounded,
                      color: hasLocation
                          ? AppColors.successGreen
                          : AppColors.primaryBlue,
                      size: 24,
                    ),
            ),
            const SizedBox(width: AppSizes.paddingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasLocation ? 'Shop location set' : 'Set shop location',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: hasLocation
                              ? AppColors.successGreen
                              : AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCapturing
                        ? 'Reading GPS signal...'
                        : hasLocation
                            ? (label ??
                                '${location!.latitude.toStringAsFixed(4)}, '
                                    '${location!.longitude.toStringAsFixed(4)}')
                            : 'Required so buyers can find your shop on the map',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.gray500,
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
