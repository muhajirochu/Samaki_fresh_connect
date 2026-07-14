// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DeliveryModelImpl _$$DeliveryModelImplFromJson(Map<String, dynamic> json) =>
    _$DeliveryModelImpl(
      deliveryId: json['deliveryId'] as String,
      orderId: json['orderId'] as String,
      sellerId: json['sellerId'] as String,
      pickupLocation: json['pickupLocation'] as Map<String, dynamic>?,
      dropoffLocation: json['dropoffLocation'] as Map<String, dynamic>?,
      status: json['status'] as String,
      pickedUpAt: json['pickedUpAt'] == null
          ? null
          : DateTime.parse(json['pickedUpAt'] as String),
      deliveredAt: json['deliveredAt'] == null
          ? null
          : DateTime.parse(json['deliveredAt'] as String),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
    );

Map<String, dynamic> _$$DeliveryModelImplToJson(_$DeliveryModelImpl instance) =>
    <String, dynamic>{
      'deliveryId': instance.deliveryId,
      'orderId': instance.orderId,
      'sellerId': instance.sellerId,
      'pickupLocation': instance.pickupLocation,
      'dropoffLocation': instance.dropoffLocation,
      'status': instance.status,
      'pickedUpAt': instance.pickedUpAt?.toIso8601String(),
      'deliveredAt': instance.deliveredAt?.toIso8601String(),
      'deliveryFee': instance.deliveryFee,
    };
