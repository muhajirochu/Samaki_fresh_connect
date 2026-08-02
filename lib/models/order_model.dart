import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/timestamp_converter.dart';

part 'order_model.freezed.dart';
part 'order_model.g.dart';

@freezed
class OrderModel with _$OrderModel {
  const factory OrderModel({
    required String orderId,
    required String orderPath,
    required String buyerId,
    String? streetSellerId,
    required String listingId,
    required double originalPrice,
    double? negotiatedPrice,
    required double finalPrice,
    required double quantityKg,
    required String orderStatus,
    String? negotiationStatus,
    required bool pickupConfirmed,
    required bool deliveryConfirmed,
    @TimestampConverter() required DateTime createdAt,
    @OptionalTimestampConverter() DateTime? completedAt,
    @OptionalTimestampConverter() DateTime? cancelledAt,
    // ── Denormalized for "Popular Near You" demand aggregation ──────────
    // Stamped at order-create from the source listing so the buyer
    // dashboard can rank fish by completed-order volume without
    // joining back to the listing collection. All three are
    // optional so legacy orders written before this change still
    // deserialize — they just won't contribute to the demand map.
    String? fishType,
    double? sellerLat,
    double? sellerLng,
  }) = _OrderModel;

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);
}
