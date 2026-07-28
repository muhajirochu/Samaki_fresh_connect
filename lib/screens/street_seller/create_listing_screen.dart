import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../services/gps_failure.dart';
import '../../l10n/app_localizations.dart';
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
    final cs = Theme.of(context).colorScheme;
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final uploadProgress = useState<String?>(null);

    // Form fields
    final selectedFishType = useState<FishType>(FishType.tilapia);
    final quantityController = useTextEditingController();
    final priceController = useTextEditingController();
    final descriptionController = useTextEditingController();

    // Picked images. Each entry is wrapped in _PickedImage so the
    // thumbnail widget always renders with a stable, cache-busting
    // key. Without a stable key, Flutter's `FileImage` keeps showing
    // the stale cached bytes when the same path is reused (e.g.
    // re-selecting an image after deleting a previous one), which
    // is what caused "photos don't show" in the previous build.
    final pickedImages = useState<List<_PickedImage>>(<_PickedImage>[]);

    // Bumped on every state mutation so StatefulBuilder children
    // can rebuild reliably without depending on List<File>
    // identity tricks.
    final imageTick = useState<int>(0);

    // Shop location. The seller captures their position once via the
    // "Set shop location" tile; the result is written to both the
    // listing (so the buyer's geo query picks it up) and the user's doc
    // (so the dashboard / future flows can read it).
    final capturedLocation = useState<BuyerLocation?>(null);
    final capturedLocationLabel = useState<String?>(null);
    final isCapturingLocation = useState<bool>(false);

    // User context
    final user = ref.watch(currentUserStreamProvider).valueOrNull;

    final imagePicker = ImagePicker();

    Future<void> pickImages() async {
      try {
        final List<XFile> picked = await imagePicker.pickMultiImage(
          imageQuality: 80,
          maxWidth: 1200,
          maxHeight: 1200,
        );
        if (!context.mounted) return;
        if (picked.isEmpty) return;

        // Filter out zero-byte files: image_picker sometimes returns
        // an entry even when the user cancelled the picker.
        final valid = <_PickedImage>[];
        for (final x in picked) {
          final file = File(x.path);
          if (!await file.exists()) continue;
          final size = await file.length();
          if (size == 0) continue;
          valid.add(_PickedImage(file: file));
        }
        if (valid.isEmpty) return;

        // Build the merged list using the *current* snapshotted
        // state, then commit. Reading `pickedImages.value` here is
        // intentional — by snapshotting first we avoid any chance
        // of stale-closure bugs if the picker is invoked twice in
        // quick succession.
        final current = List<_PickedImage>.from(pickedImages.value);
        final combined = [...current, ...valid].take(5).toList();
        pickedImages.value = combined;
        imageTick.value = imageTick.value + 1;
      } on Object catch (e, st) {
        AppLogger.error('pickMultiImage failed', e, st);
        if (context.mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.imageUploadFailed(e.toString())),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }

    Future<void> pickFromCamera() async {
      try {
        final XFile? picked = await imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1200,
          maxHeight: 1200,
        );
        if (!context.mounted) return;
        if (picked == null) return;

        final file = File(picked.path);
        if (!await file.exists()) return;
        if (await file.length() == 0) return;

        final current = List<_PickedImage>.from(pickedImages.value);
        final combined = [...current, _PickedImage(file: file)].take(5).toList();
        pickedImages.value = combined;
        imageTick.value = imageTick.value + 1;
      } on Object catch (e, st) {
        AppLogger.error('pickImage (camera) failed', e, st);
        if (context.mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.cameraImageFailed(e.toString())),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }

    void showImageSourceSheet() {
      showModalBottomSheet(
        context: context,
        backgroundColor: cs.surface,
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
                    color: cs.onSurface.withValues(alpha: 0.20),
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
                      // Primary action colour, theme-aware.
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () {
                        Navigator.pop(context);
                        pickImages();
                      },
                    ),
                    _SourceButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      // Secondary action colour (Elegant Green /
                      // Teal), so the two source buttons share the
                      // brand gradient.
                      color: Theme.of(context).colorScheme.secondary,
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
                  backgroundColor: Theme.of(context).colorScheme.secondary,
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
                  backgroundColor: Theme.of(context).colorScheme.error,
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
        final imagesToUpload = pickedImages.value
            .map((p) => p.file)
            .whereType<File>()
            .toList();
        if (imagesToUpload.isNotEmpty) {
          uploadProgress.value =
              'Uploading images (0/${imagesToUpload.length})…';
          final cloudinary = ref.read(cloudinaryServiceProvider);
          imageUrls = await cloudinary.uploadImages(
            imagesToUpload,
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
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.listingCreatedSuccessfully),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          );
          context.pop();
        }
      } catch (e) {
        uploadProgress.value = null;
        if (context.mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorGeneric(e.toString())),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(AppStrings.postListing,
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
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
              // The whole row is wrapped in StatefulBuilder so we can
              // force-rebuild whenever `imageTick` increments (after a
              // picker returns) and the underlying `FileImage`s are
              // bound to a stable `ValueKey(file.path)` — both pieces
              // are required to make the thumbnails actually render.
              StatefulBuilder(
                builder: (ctx, setLocal) {
                  // Read imageTick only to depend on it for rebuilds.
                  imageTick.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                                  margin: const EdgeInsets.only(
                                      right: AppSizes.paddingMD),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(
                                        AppSizes.radiusLG),
                                    border: Border.all(
                                      color:
                                          cs.primary.withValues(alpha: 0.3),
                                      style: BorderStyle.solid,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_rounded,
                                          color: cs.primary, size: 28),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add Photo',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: cs.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Picked images. Each thumbnail has a
                            // ValueKey built from `path + tick` so
                            // FileImage re-decodes the bytes after a
                            // fresh pick instead of reusing its cache.
                            for (var i = 0; i < pickedImages.value.length; i++)
                              _PickedImageThumb(
                                key: ValueKey(
                                  'picked-$i-${imageTick.value}-'
                                  '${pickedImages.value[i].cacheKey}',
                                ),
                                image: pickedImages.value[i],
                                onRemove: () {
                                  final updated = List<_PickedImage>.from(
                                      pickedImages.value);
                                  updated.removeAt(i);
                                  pickedImages.value = updated;
                                  imageTick.value = imageTick.value + 1;
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
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
                    color: cs.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: cs.primary),
                      ),
                      const SizedBox(width: AppSizes.paddingMD),
                      Expanded(
                        child: Text(
                          uploadProgress.value!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: cs.primary,
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

/// Wraps an on-disk picked image so the cache key survives across
/// rebuilds. Without `_cacheKey`, Flutter's `FileImage` keeps showing
/// the previously-decoded bytes when the same path is reused.
class _PickedImage {
  final File file;

  /// Stable identifier for the picker thumb. Combines the absolute
  /// path with a per-instance microsecond stamp so identical paths
  /// from the iOS gallery still trigger a fresh decode.
  final String cacheKey;

  _PickedImage({required this.file})
      : cacheKey = '${file.path}::${DateTime.now().microsecondsSinceEpoch}';
}

/// Thumbnail tile for a single picked image. Built with `Image.file`
/// + a `ValueKey` keyed by `cacheKey`, so Flutter's image cache is
/// forced to re-decode whenever a new image enters the list. (The
/// old `Container + DecorationImage` pattern was the cause of
/// "photos don't show" — `FileImage` was reusing cached bytes.)
class _PickedImageThumb extends StatelessWidget {
  const _PickedImageThumb({
    super.key,
    required this.image,
    required this.onRemove,
  });

  final _PickedImage image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: AppSizes.paddingMD),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Image.file forces a brand-new ImageProvider per
          // element when the ValueKey changes. This is what makes
          // new picks actually appear.
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusLG),
              child: Image.file(
                image.file,
                fit: BoxFit.cover,
                cacheWidth: 240,
                cacheHeight: 240,
                gaplessPlayback: false,
                errorBuilder: (_, __, ___) => Container(
                  color: cs.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: cs.onSurface.withValues(alpha: 0.40),
                  ),
                ),
              ),
            ),
          ),
          // Soft shadow behind the thumb for a premium feel.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusLG),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Remove button.
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: cs.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.32),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 16), // on cs.error — stays white for contrast
              ),
            ),
          ),
        ],
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
    final cs = Theme.of(context).colorScheme;
    final hasLocation = location != null;
    return InkWell(
      onTap: isCapturing ? null : onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        decoration: BoxDecoration(
          // Captured-location state uses the secondary (Elegant Green)
          // so it matches the "live / set" semantic across the app.
          color: hasLocation
              ? cs.secondary.withValues(alpha: 0.06)
              : cs.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          border: Border.all(
            color: hasLocation
                ? cs.secondary.withValues(alpha: 0.4)
                : cs.primary.withValues(alpha: 0.3),
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
                    ? cs.secondary.withValues(alpha: 0.15)
                    : cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusMD),
              ),
              child: isCapturing
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: cs.primary),
                    )
                  : Icon(
                      hasLocation
                          ? Icons.check_circle_rounded
                          : Icons.my_location_rounded,
                      color: hasLocation
                          ? cs.secondary
                          : cs.primary,
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
                              ? cs.secondary
                              : cs.onSurface,
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
                          color: cs.onSurface.withValues(alpha: 0.65),
                          height: 1.3,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurface.withValues(alpha: 0.55),
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
              color: color.withValues(alpha: 0.10),
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