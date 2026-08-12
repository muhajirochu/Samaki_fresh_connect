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
      buyerId: json['buyerId'] as String? ?? '',
      pickupLocation:
          const GeoPointConverter().fromJson(json['pickupLocation']),
      dropoffLocation:
          const GeoPointConverter().fromJson(json['dropoffLocation']),
      status: json['status'] as String? ?? 'pending',
      pickedUpAt: json['pickedUpAt'] == null
          ? null
          : DateTime.parse(json['pickedUpAt'] as String),
      deliveredAt: json['deliveredAt'] == null
          ? null
          : DateTime.parse(json['deliveredAt'] as String),
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$DeliveryModelImplToJson(_$DeliveryModelImpl instance) =>
    <String, dynamic>{
      'deliveryId': instance.deliveryId,
      'orderId': instance.orderId,
      'sellerId': instance.sellerId,
      'buyerId': instance.buyerId,
      'pickupLocation':
          const GeoPointConverter().toJson(instance.pickupLocation),
      'dropoffLocation':
          const GeoPointConverter().toJson(instance.dropoffLocation),
      'status': instance.status,
      'pickedUpAt': instance.pickedUpAt?.toIso8601String(),
      'deliveredAt': instance.deliveredAt?.toIso8601String(),
      'deliveryFee': instance.deliveryFee,
    };
