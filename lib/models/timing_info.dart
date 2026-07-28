import 'package:json_annotation/json_annotation.dart';
import 'package:player_playback/player_playback.dart';

part 'timing_info.g.dart';

@JsonSerializable()
class TimingInfo {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'file_id')
  final String fileId;

  @JsonKey(name: 'seconds')
  int seconds;

  @JsonKey(name: 'create_time')
  int? createTime;

  @JsonKey(includeFromJson: false, includeToJson: false)
  FileInfo? fileInfo;

  TimingInfo(
      {
        this.id,
        required this.fileId,
        required this.seconds,
        this.createTime,
      });

  factory TimingInfo.fromJson(Map<String, dynamic> srcJson) => _$TimingInfoFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TimingInfoToJson(this);
}