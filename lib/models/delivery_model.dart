import 'package:freezed_annotation/freezed_annotation.dart';

part 'delivery_model.freezed.dart';
part 'delivery_model.g.dart';

@freezed
class DeliveryModel with _$DeliveryModel {
  const factory DeliveryModel({
    required String deliveryId,
    required String orderId,
    required String sellerId,
    Map<String, dynamic>? pickupLocation,
    Map<String, dynamic>? dropoffLocation,
    required String status,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    required double deliveryFee,
  }) = _DeliveryModel;

  factory DeliveryModel.fromJson(Map<String, dynamic> json) =>
      _$DeliveryModelFromJson(json);
}
