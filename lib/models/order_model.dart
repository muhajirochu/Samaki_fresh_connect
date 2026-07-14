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
  }) = _OrderModel;

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);
}
