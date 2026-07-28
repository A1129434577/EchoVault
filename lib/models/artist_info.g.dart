// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtistInfo _$ArtistInfoFromJson(Map<String, dynamic> json) => ArtistInfo(
  id: json['id'] as String?,
  ytId: json['yt_id'] as String?,
  name: json['name'] as String? ?? '',
  desc: json['desc'] as String? ?? '',
  thumbnail: json['thumbnail'] as String? ?? '',
  createTime: (json['create_time'] as num?)?.toInt(),
  isFavorite: (json['is_favorite'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ArtistInfoToJson(ArtistInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'yt_id': instance.ytId,
      'name': instance.name,
      'desc': instance.desc,
      'thumbnail': instance.thumbnail,
      'is_favorite': instance.isFavorite,
      'create_time': instance.createTime,
    };
