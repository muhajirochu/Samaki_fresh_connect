import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/geopoint_converter.dart';
import '../utils/timestamp_converter.dart';
import 'enums/order_status.dart';
import 'enums/payment_status.dart';
import 'enums/payout_status.dart';


part 'order_model.freezed.dart';
part 'order_model.g.dart';

@freezed
class OrderModel with _$OrderModel {
  const factory OrderModel({
    @Default('') String orderId,
    @Default('') String buyerId,
    @Default('') String streetSellerId,
    @Default('') String fishId,
    @Default(1) int quantity,
    @Default(0.0) double totalPrice,
    @Default('') String pickupCode,
    @OrderStatusConverter() @Default(OrderStatus.pending) OrderStatus status,
    @OptionalTimestampConverter() DateTime? estimatedArrival,
    @GeoPointConverter() GeoPoint? buyerLocation,
    @GeoPointConverter() GeoPoint? streetSellerLocation,
    @Default(false) bool isPaid,
    @PaymentStatusConverter() @Default(PaymentStatus.pending) PaymentStatus paymentStatus,
    @PayoutStatusConverter() @Default(PayoutStatus.pending) PayoutStatus payoutStatus,
    @Default(0.0) double commissionRate,
    @Default(0.0) double commissionAmount,
    @Default(0.0) double sellerEarnings,
    @OptionalTimestampConverter() DateTime? paidAt,
    @OptionalTimestampConverter() DateTime? releasedAt,
    @OptionalTimestampConverter() DateTime? completedAt,
    @Default('') String paymentReference,
    @Default('') String paymentMethod,
    @Default(false) bool buyerConfirmed,
    @OptionalTimestampConverter() DateTime? buyerConfirmedAt,
    @Default('') String buyerComment,
    @Default('') String buyerFeedbackImageUrl,
    @Default(false) bool isDisputed,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _OrderModel;

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);
}
