import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/enums/fish_type.dart';
import '../models/fish_listing_model.dart';
import '../services/fish_listing_service.dart';
import '../services/cloudinary_service.dart';
import '../services/listing_location_service.dart';
import '../services/location_service.dart';
import '../services/user_service.dart';
import '../utils/logger.dart';
import 'auth_provider.dart';

// ── Service providers ─────────────────────────────────────────────────────────
final fishListingServiceProvider = Provider<FishListingService>(
  (ref) => FishListingService(),
);

final cloudinaryServiceProvider = Provider<CloudinaryService>(
  (ref) => CloudinaryService(),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

final listingLocationServiceProvider = Provider<ListingLocationService>(
  (ref) => ListingLocationService(
    locationService: ref.watch(locationServiceProvider),
    userService: UserService(),
    fishListingService: ref.watch(fishListingServiceProvider),
  ),
);

// ── All active listings (marketplace) ────────────────────────────────────────
final activeListingsProvider = StreamProvider<List<FishListingModel>>((ref) {
  final service = ref.watch(fishListingServiceProvider);
  return service.streamActiveListings();
});

// ── Listings by seller ────────────────────────────────────────────────────────
final sellerListingsProvider =
    StreamProvider.family<List<FishListingModel>, String>((ref, sellerId) {
  final service = ref.watch(fishListingServiceProvider);
  return service.streamListingsBySeller(sellerId);
});

// ── Single listing detail ─────────────────────────────────────────────────────
final listingDetailProvider =
    FutureProvider.family<FishListingModel?, String>((ref, listingId) async {
  final service = ref.watch(fishListingServiceProvider);
  return service.getListingById(listingId);
});

// ── Management controller (street seller CRUD) ─────────────────────────────────
//
// Wraps the service primitives with reactive state and a session guard.
// The seller's listings are matched by `sellerId == currentUser.userId`,
// so all writes are implicitly scoped to the signed-in seller.

class ListingActionResult {
  final bool success;
  final String? error;
  const ListingActionResult.success()
      : success = true,
        error = null;
  const ListingActionResult.failure(String message)
      : success = false,
        error = message;
}

class ListingManagementController extends StateNotifier<AsyncValue<void>> {
  ListingManagementController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;
  FishListingService get _service => _ref.read(fishListingServiceProvider);

  /// Validates that the listing belongs to the currently signed-in
  /// seller before any write. Returns the listing, or null if the
  /// caller is not allowed to touch it.
  FishListingModel? _assertOwnership(String listingId, String currentUserId) {
    final listings = _ref.read(sellerListingsProvider(currentUserId)).valueOrNull;
    if (listings == null) return null;
    for (final l in listings) {
      if (l.listingId == listingId) return l;
    }
    return null;
  }

  Future<ListingActionResult> updateListing({
    required String listingId,
    String? fishType,
    double? quantityKg,
    double? pricePerKg,
    double? totalPrice,
    String? description,
    List<String>? imageUrls,
  }) async {
    final session = _ref.read(currentUserStreamProvider).valueOrNull;
    if (session == null) {
      return const ListingActionResult.failure('Not signed in');
    }
    final owned = _assertOwnership(listingId, session.userId);
    if (owned == null) {
      return const ListingActionResult.failure(
        'Listing not found or not owned by you',
      );
    }

    state = const AsyncValue.loading();
    try {
      final fields = <String, dynamic>{};
      if (fishType != null) fields['fishType'] = fishType;
      if (quantityKg != null) fields['quantityKg'] = quantityKg;
      if (pricePerKg != null) fields['pricePerKg'] = pricePerKg;
      if (totalPrice != null) fields['totalPrice'] = totalPrice;
      if (description != null) fields['description'] = description;
      if (imageUrls != null) fields['imageUrls'] = imageUrls;
      await _service.updateListing(listingId, fields);
      state = const AsyncValue.data(null);
      AppLogger.info('Listing $listingId updated by ${session.userId}');
      return const ListingActionResult.success();
    } catch (e, st) {
      AppLogger.error('updateListing failed: $e');
      state = AsyncValue.error(e, st);
      return ListingActionResult.failure(e.toString());
    }
  }

  Future<ListingActionResult> markAsSold(String listingId) async {
    final session = _ref.read(currentUserStreamProvider).valueOrNull;
    if (session == null) {
      return const ListingActionResult.failure('Not signed in');
    }
    if (_assertOwnership(listingId, session.userId) == null) {
      return const ListingActionResult.failure('Not your listing');
    }
    state = const AsyncValue.loading();
    try {
      await _service.markAsSold(listingId);
      state = const AsyncValue.data(null);
      return const ListingActionResult.success();
    } catch (e, st) {
      AppLogger.error('markAsSold failed: $e');
      state = AsyncValue.error(e, st);
      return ListingActionResult.failure(e.toString());
    }
  }

  Future<ListingActionResult> deleteListing(String listingId) async {
    final session = _ref.read(currentUserStreamProvider).valueOrNull;
    if (session == null) {
      return const ListingActionResult.failure('Not signed in');
    }
    if (_assertOwnership(listingId, session.userId) == null) {
      return const ListingActionResult.failure(
        'Listing not found or not owned by you',
      );
    }
    state = const AsyncValue.loading();
    try {
      await _service.deleteListing(listingId);
      state = const AsyncValue.data(null);
      AppLogger.info('Listing $listingId deleted by ${session.userId}');
      return const ListingActionResult.success();
    } catch (e, st) {
      AppLogger.error('deleteListing failed: $e');
      state = AsyncValue.error(e, st);
      return ListingActionResult.failure(e.toString());
    }
  }
}

final listingManagementControllerProvider = StateNotifierProvider<
    ListingManagementController, AsyncValue<void>>(
  (ref) => ListingManagementController(ref),
);

// Helper: convert a FishType enum to the string used in FishListingModel.
String fishTypeEnumToString(FishType t) => t.value;
