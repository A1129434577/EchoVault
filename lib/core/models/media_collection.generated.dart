// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaCollection _$MediaCollectionFromJson(Map<String, dynamic> json) =>
    MediaCollection(
      id: json['id'] as String?,
      params: json['params'] as String?,
      name: json['name'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      detail: json['detail'] as String?,
      type: $enumDecodeNullable(_$FileGroupShowTypeEnumMap, json['type']),
      playlistType: json['playlist_type'] as String?,
      thumbnail: json['thumbnail'] as String? ?? '',
      childrenIds:
          (json['children_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createTime: (json['create_time'] as num?)?.toInt(),
      isFavorite: (json['is_favorite'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MediaCollectionToJson(MediaCollection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'params': instance.params,
      'name': instance.name,
      'display_name': instance.displayName,
      'detail': instance.detail,
      'type': _$FileGroupShowTypeEnumMap[instance.type],
      'playlist_type': instance.playlistType,
      'thumbnail': instance.thumbnail,
      'children_ids': instance.childrenIds,
      'is_favorite': instance.isFavorite,
      'create_time': instance.createTime,
    };

const _$FileGroupShowTypeEnumMap = {
  MediaCollectionShowType.responsiveListMusic: 'responsiveListMusic',
  MediaCollectionShowType.listMusic: 'listMusic',
  MediaCollectionShowType.grid: 'grid',
  MediaCollectionShowType.twoRowVideo: 'twoRowVideo',
  MediaCollectionShowType.twoRowPlaylist: 'twoRowPlaylist',
  MediaCollectionShowType.twoRowArtist: 'twoRowArtist',
};
