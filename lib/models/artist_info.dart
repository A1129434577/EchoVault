import 'package:json_annotation/json_annotation.dart';
part 'artist_info.g.dart';

@JsonSerializable()
class ArtistInfo {
  static const String ytmTypeName = 'MUSIC_PAGE_TYPE_ARTIST';
  static const String ytTypeName = 'YT_PAGE_TYPE_ARTIST';
  static const String ytSearchTypeName = 'WEB_PAGE_TYPE_CHANNEL';

  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'yt_id')
  String? ytId;

  @JsonKey(name: 'name', defaultValue: '')
  String name;

  @JsonKey(name: 'desc', defaultValue: '')
  String desc;

  @JsonKey(name: 'thumbnail', defaultValue: '')
  String thumbnail;

  @JsonKey(name: 'is_favorite', defaultValue: 0)
  int isFavorite;

  @JsonKey(name: 'create_time')
  int? createTime;

  ArtistInfo({
    this.id,
    this.ytId,
    this.name = '',
    this.desc = '',
    this.thumbnail = '',
    this.createTime,
    this.isFavorite = 0,
  });

  factory ArtistInfo.fromJson(Map<String, dynamic> srcJson) => _$ArtistInfoFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ArtistInfoToJson(this);
}