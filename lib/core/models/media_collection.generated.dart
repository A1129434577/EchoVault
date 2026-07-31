// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaCollection _$MediaCollectionFromJson(Map<String, dynamic> jsonArg) =>
    MediaCollection(
      id: jsonArg['id'] as String?,
      params: jsonArg['params'] as String?,
      name: jsonArg['name'] as String? ?? '',
      displayName: jsonArg['display_name'] as String? ?? '',
      detail: jsonArg['detail'] as String?,
      type: $enumDecodeNullable(_$FileGroupShowTypeEnumMap, jsonArg['type']),
      playlistType: jsonArg['playlist_type'] as String?,
      thumbnail: jsonArg['thumbnail'] as String? ?? '',
      childrenIds:
          (jsonArg['children_ids'] as List<dynamic>?)
              ?.map((entry) => entry as String)
              .toList() ??
          [],
      createTime: (jsonArg['create_time'] as num?)?.toInt(),
      isFavorite: (jsonArg['is_favorite'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MediaCollectionToJson(MediaCollection instanceArg) =>
    <String, dynamic>{
      'id': instanceArg.id,
      'params': instanceArg.params,
      'name': instanceArg.name,
      'display_name': instanceArg.displayName,
      'detail': instanceArg.detail,
      'type': _$FileGroupShowTypeEnumMap[instanceArg.type],
      'playlist_type': instanceArg.playlistType,
      'thumbnail': instanceArg.thumbnail,
      'children_ids': instanceArg.childrenIds,
      'is_favorite': instanceArg.isFavorite,
      'create_time': instanceArg.createTime,
    };

const _$FileGroupShowTypeEnumMap = {
  MediaCollectionShowType.responsiveListMusic: 'responsiveListMusic',
  MediaCollectionShowType.listMusic: 'listMusic',
  MediaCollectionShowType.grid: 'grid',
  MediaCollectionShowType.twoRowVideo: 'twoRowVideo',
  MediaCollectionShowType.twoRowPlaylist: 'twoRowPlaylist',
  MediaCollectionShowType.twoRowArtist: 'twoRowArtist',
};
