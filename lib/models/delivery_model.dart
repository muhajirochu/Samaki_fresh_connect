import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';

import '../utils/geopoint_converter.dart';

part 'delivery_model.freezed.dart';
part 'delivery_model.g.dart';

@freezed
class DeliveryModel with _$DeliveryModel {
  const factory DeliveryModel({
    required String deliveryId,
    required String orderId,
    required String sellerId,
    @Default('') String buyerId,
    @GeoPointConverter() GeoPoint? pickupLocation,
    @GeoPointConverter() GeoPoint? dropoffLocation,
    @Default('pending') String status,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    @Default(0.0) double deliveryFee,
  }) = _DeliveryModel;

  factory DeliveryModel.fromJson(Map<String, dynamic> json) =>
      _$DeliveryModelFromJson(json);
}

extension DeliveryModelGeo on DeliveryModel {
  LatLng? get pickupLatLng => pickupLocation == null
      ? null
      : LatLng(pickupLocation!.latitude, pickupLocation!.longitude);

  LatLng? get dropoffLatLng => dropoffLocation == null
      ? null
      : LatLng(dropoffLocation!.latitude, dropoffLocation!.longitude);
}
