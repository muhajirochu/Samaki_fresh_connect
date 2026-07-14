// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderModelImpl _$$OrderModelImplFromJson(Map<String, dynamic> json) =>
    _$OrderModelImpl(
      orderId: json['orderId'] as String,
      orderPath: json['orderPath'] as String,
      buyerId: json['buyerId'] as String,
      streetSellerId: json['streetSellerId'] as String?,
      listingId: json['listingId'] as String,
      originalPrice: (json['originalPrice'] as num).toDouble(),
      negotiatedPrice: (json['negotiatedPrice'] as num?)?.toDouble(),
      finalPrice: (json['finalPrice'] as num).toDouble(),
      quantityKg: (json['quantityKg'] as num).toDouble(),
      orderStatus: json['orderStatus'] as String,
      negotiationStatus: json['negotiationStatus'] as String?,
      pickupConfirmed: json['pickupConfirmed'] as bool,
      deliveryConfirmed: json['deliveryConfirmed'] as bool,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      completedAt:
          const OptionalTimestampConverter().fromJson(json['completedAt']),
      cancelledAt:
          const OptionalTimestampConverter().fromJson(json['cancelledAt']),
    );

Map<String, dynamic> _$$OrderModelImplToJson(_$OrderModelImpl instance) =>
    <String, dynamic>{
      'orderId': instance.orderId,
      'orderPath': instance.orderPath,
      'buyerId': instance.buyerId,
      'streetSellerId': instance.streetSellerId,
      'listingId': instance.listingId,
      'originalPrice': instance.originalPrice,
      'negotiatedPrice': instance.negotiatedPrice,
      'finalPrice': instance.finalPrice,
      'quantityKg': instance.quantityKg,
      'orderStatus': instance.orderStatus,
      'negotiationStatus': instance.negotiationStatus,
      'pickupConfirmed': instance.pickupConfirmed,
      'deliveryConfirmed': instance.deliveryConfirmed,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'completedAt':
          const OptionalTimestampConverter().toJson(instance.completedAt),
      'cancelledAt':
          const OptionalTimestampConverter().toJson(instance.cancelledAt),
    };
