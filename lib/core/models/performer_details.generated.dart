// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'performer_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PerformerDetails _$PerformerDetailsFromJson(Map<String, dynamic> jsonArg) =>
    PerformerDetails(
      id: jsonArg['id'] as String?,
      ytId: jsonArg['yt_id'] as String?,
      name: jsonArg['name'] as String? ?? '',
      desc: jsonArg['desc'] as String? ?? '',
      thumbnail: jsonArg['thumbnail'] as String? ?? '',
      createTime: (jsonArg['create_time'] as num?)?.toInt(),
      isFavorite: (jsonArg['is_favorite'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PerformerDetailsToJson(PerformerDetails instanceArg) =>
    <String, dynamic>{
      'id': instanceArg.id,
      'yt_id': instanceArg.ytId,
      'name': instanceArg.name,
      'desc': instanceArg.desc,
      'thumbnail': instanceArg.thumbnail,
      'is_favorite': instanceArg.isFavorite,
      'create_time': instanceArg.createTime,
    };
