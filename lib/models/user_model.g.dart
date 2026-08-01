// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      role: json['role'] == null
          ? UserRole.buyer
          : const UserRoleConverter().fromJson(json['role']),
      profilePictureUrl: json['profilePictureUrl'] as String?,
      location: _locationFromJson(json['location']),
      isActive: json['isActive'] as bool? ?? true,
      registeredBy: json['registeredBy'] as String?,
      isApproved: json['isApproved'] as bool? ?? false,
      approvedBy: json['approvedBy'] as String?,
      approvedAt:
          const OptionalTimestampConverter().fromJson(json['approvedAt']),
      fishMarketName: json['fishMarketName'] as String?,
      zanzibarIdNumber: json['zanzibarIdNumber'] as String?,
      businessPermitNumber: json['businessPermitNumber'] as String?,
      totalListings: (json['totalListings'] as num?)?.toInt() ?? 0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'email': instance.email,
      'fullName': instance.fullName,
      'phoneNumber': instance.phoneNumber,
      'role': const UserRoleConverter().toJson(instance.role),
      'profilePictureUrl': instance.profilePictureUrl,
      'location': instance.location,
      'isActive': instance.isActive,
      'registeredBy': instance.registeredBy,
      'isApproved': instance.isApproved,
      'approvedBy': instance.approvedBy,
      'approvedAt':
          const OptionalTimestampConverter().toJson(instance.approvedAt),
      'fishMarketName': instance.fishMarketName,
      'zanzibarIdNumber': instance.zanzibarIdNumber,
      'businessPermitNumber': instance.businessPermitNumber,
      'totalListings': instance.totalListings,
      'totalOrders': instance.totalOrders,
      'totalSales': instance.totalSales,
      'averageRating': instance.averageRating,
      'totalEarnings': instance.totalEarnings,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
    };
