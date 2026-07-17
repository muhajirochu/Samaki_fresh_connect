// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ActivityLogModelImpl _$$ActivityLogModelImplFromJson(
        Map<String, dynamic> json) =>
    _$ActivityLogModelImpl(
      logId: json['logId'] as String,
      type: json['type'] as String,
      actorUid: json['actorUid'] as String?,
      actorRole: json['actorRole'] as String?,
      targetType: json['targetType'] as String?,
      targetId: json['targetId'] as String?,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$$ActivityLogModelImplToJson(
        _$ActivityLogModelImpl instance) =>
    <String, dynamic>{
      'logId': instance.logId,
      'type': instance.type,
      'actorUid': instance.actorUid,
      'actorRole': instance.actorRole,
      'targetType': instance.targetType,
      'targetId': instance.targetId,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'metadata': instance.metadata,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };
