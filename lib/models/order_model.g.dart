// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderModelImpl _$$OrderModelImplFromJson(Map<String, dynamic> json) =>
    _$OrderModelImpl(
      orderId: json['orderId'] as String? ?? '',
      buyerId: json['buyerId'] as String? ?? '',
      streetSellerId: json['streetSellerId'] as String? ?? '',
      fishId: json['fishId'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      pickupCode: json['pickupCode'] as String? ?? '',
      status: $enumDecodeNullable(_$OrderStatusEnumMap, json['status']) ??
          OrderStatus.pending,
      estimatedArrival:
          const OptionalTimestampConverter().fromJson(json['estimatedArrival']),
      buyerLocation: const GeoPointConverter().fromJson(json['buyerLocation']),
      streetSellerLocation:
          const GeoPointConverter().fromJson(json['streetSellerLocation']),
      isPaid: json['isPaid'] as bool? ?? false,
      paymentReference: json['paymentReference'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$$OrderModelImplToJson(_$OrderModelImpl instance) =>
    <String, dynamic>{
      'orderId': instance.orderId,
      'buyerId': instance.buyerId,
      'streetSellerId': instance.streetSellerId,
      'fishId': instance.fishId,
      'quantity': instance.quantity,
      'totalPrice': instance.totalPrice,
      'pickupCode': instance.pickupCode,
      'status': _$OrderStatusEnumMap[instance.status]!,
      'estimatedArrival':
          const OptionalTimestampConverter().toJson(instance.estimatedArrival),
      'buyerLocation': const GeoPointConverter().toJson(instance.buyerLocation),
      'streetSellerLocation':
          const GeoPointConverter().toJson(instance.streetSellerLocation),
      'isPaid': instance.isPaid,
      'paymentReference': instance.paymentReference,
      'paymentMethod': instance.paymentMethod,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
    };

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.accepted: 'accepted',
  OrderStatus.preparing: 'preparing',
  OrderStatus.pickupGenerated: 'pickupGenerated',
  OrderStatus.arriving: 'arriving',
  OrderStatus.completed: 'completed',
  OrderStatus.cancelled: 'cancelled',
};
