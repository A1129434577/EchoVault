// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'performer_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PerformerDetails _$PerformerDetailsFromJson(Map<String, dynamic> json) =>
    PerformerDetails(
      id: json['id'] as String?,
      ytId: json['yt_id'] as String?,
      name: json['name'] as String? ?? '',
      desc: json['desc'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      createTime: (json['create_time'] as num?)?.toInt(),
      isFavorite: (json['is_favorite'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PerformerDetailsToJson(PerformerDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'yt_id': instance.ytId,
      'name': instance.name,
      'desc': instance.desc,
      'thumbnail': instance.thumbnail,
      'is_favorite': instance.isFavorite,
      'create_time': instance.createTime,
    };
