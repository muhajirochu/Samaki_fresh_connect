// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransactionModelImpl _$$TransactionModelImplFromJson(
        Map<String, dynamic> json) =>
    _$TransactionModelImpl(
      transactionId: json['transactionId'] as String,
      orderId: json['orderId'] as String,
      finalAmount: (json['finalAmount'] as num).toDouble(),
      sellerAmount: (json['sellerAmount'] as num).toDouble(),
      platformAmount: (json['platformAmount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      transactionReference: json['transactionReference'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$TransactionModelImplToJson(
        _$TransactionModelImpl instance) =>
    <String, dynamic>{
      'transactionId': instance.transactionId,
      'orderId': instance.orderId,
      'finalAmount': instance.finalAmount,
      'sellerAmount': instance.sellerAmount,
      'platformAmount': instance.platformAmount,
      'paymentMethod': instance.paymentMethod,
      'transactionReference': instance.transactionReference,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
    };
