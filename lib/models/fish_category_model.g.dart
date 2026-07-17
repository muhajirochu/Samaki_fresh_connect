// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fish_category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FishCategoryModelImpl _$$FishCategoryModelImplFromJson(
        Map<String, dynamic> json) =>
    _$FishCategoryModelImpl(
      slug: json['slug'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String?,
      iconKey: json['iconKey'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$$FishCategoryModelImplToJson(
        _$FishCategoryModelImpl instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'displayName': instance.displayName,
      'description': instance.description,
      'iconKey': instance.iconKey,
      'isActive': instance.isActive,
      'createdBy': instance.createdBy,
      'updatedBy': instance.updatedBy,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
    };
