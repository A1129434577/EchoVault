import 'package:json_annotation/json_annotation.dart';
part 'media_collection.generated.dart';

enum MediaCollectionShowType {
  //虽然responsiveList样式在官网有各种类型（音乐、歌手等），
  //app里面目前只有音乐一种样式，其他样式通通以twoRow方式显示
  responsiveListMusic,
  listMusic,
  grid,
  twoRowVideo,
  twoRowPlaylist,
  twoRowArtist,
}

enum CollectionType {
  //youtube music start------
  MUSIC_PAGE_TYPE_ALBUM,
  MUSIC_PAGE_TYPE_PLAYLIST,
  MUSIC_PAGE_TYPE_PODCAST_SHOW_DETAIL_PAGE,
  //youtube music end------

  //youtube start------
  YT_PAGE_TYPE_TOP_CHARTS,
  WEB_PAGE_TYPE_PLAYLIST /*用支持music的ip调用youtube的接口搜索到的最佳搜索的顶部card*/,
  LOCKUP_CONTENT_TYPE_ALBUM,
  LOCKUP_CONTENT_TYPE_PLAYLIST,
  //youtube end------
}

@JsonSerializable()
class MediaCollection {
  ///自建歌单的id以via_timer开头，非自建歌单为youtube上的browseId
  @JsonKey(name: 'id')
  String? id;

  ///youtube上的请求更多可能需要的参数
  @JsonKey(name: 'params')
  String? params;

  //原始name
  @JsonKey(name: 'name', defaultValue: '')
  String name;

  //显示的name，比如有可能是name(1)
  @JsonKey(name: 'display_name', defaultValue: '')
  String displayName;

  @JsonKey(name: 'detail')
  String? detail;

  @JsonKey(name: 'type')
  MediaCollectionShowType? type;

  //CollectionType
  @JsonKey(name: 'playlist_type')
  String? playlistType;

  @JsonKey(name: 'thumbnail', defaultValue: '')
  String thumbnail;

  @JsonKey(name: 'children_ids', defaultValue: [])
  List<String> childrenIds;

  ///FileInfo等
  @JsonKey(includeFromJson: false, includeToJson: false)
  List children;

  @JsonKey(name: 'is_favorite', defaultValue: 0)
  int isFavorite;

  @JsonKey(name: 'create_time')
  int? createTime;

  MediaCollection({
    this.id,
    this.params,
    this.name = '',
    this.displayName = '',
    this.detail,
    this.type,
    this.playlistType,
    this.thumbnail = '',
    this.childrenIds = const [],
    this.children = const [],
    this.createTime,
    this.isFavorite = 0,
  }) {
    if (displayName.isEmpty) {
      displayName = name;
    }
  }

  factory MediaCollection.fromJson(Map<String, dynamic> jsonArg) =>
      _$MediaCollectionFromJson(jsonArg);

  Map<String, dynamic> toJson() => _$MediaCollectionToJson(this);
}
