// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fish_listing_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FishListingModelImpl _$$FishListingModelImplFromJson(
        Map<String, dynamic> json) =>
    _$FishListingModelImpl(
      listingId: json['listingId'] as String? ?? '',
      sellerId: json['sellerId'] as String? ?? '',
      fishType: json['fishType'] as String? ?? '',
      quantityKg: (json['quantityKg'] as num?)?.toDouble() ?? 0.0,
      pricePerKg: (json['pricePerKg'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      location: json['location'] as Map<String, dynamic>?,
      status: json['status'] as String? ?? 'active',
      description: json['description'] as String?,
      createdAt: const OptionalTimestampConverter().fromJson(json['createdAt']),
      expiresAt: const OptionalTimestampConverter().fromJson(json['expiresAt']),
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
      'createdAt':
          const OptionalTimestampConverter().toJson(instance.createdAt),
      'expiresAt':
          const OptionalTimestampConverter().toJson(instance.expiresAt),
      'soldAt': const OptionalTimestampConverter().toJson(instance.soldAt),
    };
