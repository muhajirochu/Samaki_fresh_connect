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
      status: json['status'] == null
          ? OrderStatus.pending
          : const OrderStatusConverter().fromJson(json['status'] as String),
      estimatedArrival:
          const OptionalTimestampConverter().fromJson(json['estimatedArrival']),
      buyerLocation: const GeoPointConverter().fromJson(json['buyerLocation']),
      streetSellerLocation:
          const GeoPointConverter().fromJson(json['streetSellerLocation']),
      isPaid: json['isPaid'] as bool? ?? false,
      paymentStatus: json['paymentStatus'] == null
          ? PaymentStatus.pending
          : const PaymentStatusConverter()
              .fromJson(json['paymentStatus'] as String),
      payoutStatus: json['payoutStatus'] == null
          ? PayoutStatus.pending
          : const PayoutStatusConverter()
              .fromJson(json['payoutStatus'] as String),
      commissionRate: (json['commissionRate'] as num?)?.toDouble() ?? 0.0,
      commissionAmount: (json['commissionAmount'] as num?)?.toDouble() ?? 0.0,
      sellerEarnings: (json['sellerEarnings'] as num?)?.toDouble() ?? 0.0,
      paidAt: const OptionalTimestampConverter().fromJson(json['paidAt']),
      releasedAt:
          const OptionalTimestampConverter().fromJson(json['releasedAt']),
      completedAt:
          const OptionalTimestampConverter().fromJson(json['completedAt']),
      paymentReference: json['paymentReference'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      buyerConfirmed: json['buyerConfirmed'] as bool? ?? false,
      buyerConfirmedAt:
          const OptionalTimestampConverter().fromJson(json['buyerConfirmedAt']),
      buyerComment: json['buyerComment'] as String? ?? '',
      buyerFeedbackImageUrl: json['buyerFeedbackImageUrl'] as String? ?? '',
      isDisputed: json['isDisputed'] as bool? ?? false,
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
      'status': const OrderStatusConverter().toJson(instance.status),
      'estimatedArrival':
          const OptionalTimestampConverter().toJson(instance.estimatedArrival),
      'buyerLocation': const GeoPointConverter().toJson(instance.buyerLocation),
      'streetSellerLocation':
          const GeoPointConverter().toJson(instance.streetSellerLocation),
      'isPaid': instance.isPaid,
      'paymentStatus':
          const PaymentStatusConverter().toJson(instance.paymentStatus),
      'payoutStatus':
          const PayoutStatusConverter().toJson(instance.payoutStatus),
      'commissionRate': instance.commissionRate,
      'commissionAmount': instance.commissionAmount,
      'sellerEarnings': instance.sellerEarnings,
      'paidAt': const OptionalTimestampConverter().toJson(instance.paidAt),
      'releasedAt':
          const OptionalTimestampConverter().toJson(instance.releasedAt),
      'completedAt':
          const OptionalTimestampConverter().toJson(instance.completedAt),
      'paymentReference': instance.paymentReference,
      'paymentMethod': instance.paymentMethod,
      'buyerConfirmed': instance.buyerConfirmed,
      'buyerConfirmedAt':
          const OptionalTimestampConverter().toJson(instance.buyerConfirmedAt),
      'buyerComment': instance.buyerComment,
      'buyerFeedbackImageUrl': instance.buyerFeedbackImageUrl,
      'isDisputed': instance.isDisputed,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
    };
