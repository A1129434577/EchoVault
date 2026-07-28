// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timing_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimingInfo _$TimingInfoFromJson(Map<String, dynamic> json) => TimingInfo(
  id: (json['id'] as num?)?.toInt(),
  fileId: json['file_id'] as String,
  seconds: (json['seconds'] as num).toInt(),
  createTime: (json['create_time'] as num?)?.toInt(),
);

Map<String, dynamic> _$TimingInfoToJson(TimingInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'file_id': instance.fileId,
      'seconds': instance.seconds,
      'create_time': instance.createTime,
    };
