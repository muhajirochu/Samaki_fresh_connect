import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/geopoint_converter.dart';
import '../utils/timestamp_converter.dart';
import 'enums/order_status.dart';

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
    @Default(OrderStatus.pending) OrderStatus status,
    @OptionalTimestampConverter() DateTime? estimatedArrival,
    @GeoPointConverter() GeoPoint? buyerLocation,
    @GeoPointConverter() GeoPoint? streetSellerLocation,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _OrderModel;

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);
}
