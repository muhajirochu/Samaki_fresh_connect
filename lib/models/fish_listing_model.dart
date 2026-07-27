import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/timestamp_converter.dart';

part 'fish_listing_model.freezed.dart';
part 'fish_listing_model.g.dart';

@freezed
class FishListingModel with _$FishListingModel {
  const factory FishListingModel({
    // listingId / sellerId / createdAt / expiresAt all fall back to
    // safe defaults so legacy Firestore documents written before
    // these fields were introduced still deserialize — otherwise a
    // single old row would crash the entire marketplace stream and
    // the seller dashboard would lock on "Failed to load".
    @Default('') String listingId,
    @Default('') String sellerId,
    @Default('') String fishType,
    @Default(0.0) double quantityKg,
    @Default(0.0) double pricePerKg,
    @Default(0.0) double totalPrice,
    @Default(<String>[]) List<String> imageUrls,
    Map<String, dynamic>? location,
    @Default('active') String status,
    String? description,
    // `createdAt` and `expiresAt` are now nullable to tolerate legacy
    // Firestore documents written before these fields existed.
    // Sort / expiry logic across the codebase falls back to
    // `DateTime.fromMillisecondsSinceEpoch(0)` so the row still
    // surfaces instead of crashing the marketplace stream.
    // Use the *optional* converter so `null` propagates instead of
    // silently being replaced with `DateTime.now()`.
    @OptionalTimestampConverter() DateTime? createdAt,
    @OptionalTimestampConverter() DateTime? expiresAt,
    @OptionalTimestampConverter() DateTime? soldAt,
  }) = _FishListingModel;

  factory FishListingModel.fromJson(Map<String, dynamic> json) =>
      _$FishListingModelFromJson(json);
}
