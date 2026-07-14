import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/timestamp_converter.dart';

part 'fish_listing_model.freezed.dart';
part 'fish_listing_model.g.dart';

@freezed
class FishListingModel with _$FishListingModel {
  const factory FishListingModel({
    required String listingId,
    required String sellerId,
    required String fishType,
    required double quantityKg,
    required double pricePerKg,
    required double totalPrice,
    required List<String> imageUrls,
    Map<String, dynamic>? location,
    required String status,
    String? description,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime expiresAt,
    @OptionalTimestampConverter() DateTime? soldAt,
  }) = _FishListingModel;

  factory FishListingModel.fromJson(Map<String, dynamic> json) =>
      _$FishListingModelFromJson(json);
}
