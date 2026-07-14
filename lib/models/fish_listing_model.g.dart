// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fish_listing_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FishListingModelImpl _$$FishListingModelImplFromJson(
        Map<String, dynamic> json) =>
    _$FishListingModelImpl(
      listingId: json['listingId'] as String,
      sellerId: json['sellerId'] as String,
      fishType: json['fishType'] as String,
      quantityKg: (json['quantityKg'] as num).toDouble(),
      pricePerKg: (json['pricePerKg'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      imageUrls:
          (json['imageUrls'] as List<dynamic>).map((e) => e as String).toList(),
      location: json['location'] as Map<String, dynamic>?,
      status: json['status'] as String,
      description: json['description'] as String?,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      expiresAt: const TimestampConverter().fromJson(json['expiresAt']),
      soldAt: const OptionalTimestampConverter().fromJson(json['soldAt']),
    );

Map<String, dynamic> _$$FishListingModelImplToJson(
        _$FishListingModelImpl instance) =>
    <String, dynamic>{
      'listingId': instance.listingId,
      'sellerId': instance.sellerId,
      'fishType': instance.fishType,
      'quantityKg': instance.quantityKg,
      'pricePerKg': instance.pricePerKg,
      'totalPrice': instance.totalPrice,
      'imageUrls': instance.imageUrls,
      'location': instance.location,
      'status': instance.status,
      'description': instance.description,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'expiresAt': const TimestampConverter().toJson(instance.expiresAt),
      'soldAt': const OptionalTimestampConverter().toJson(instance.soldAt),
    };
