import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/controllers/file_downloader.dart';
import 'package:echo_vault/datebase/file_info_data_operate.dart';
import 'package:echo_vault/network/player_http_client.dart';
import 'package:echo_vault/network/ytm_network.dart';
import 'package:echo_vault/parse/common_parse.dart';
import 'package:echo_vault/parse/parse_util.dart';
import 'package:echo_vault/utils/toast_util.dart';

class PlayController with ChangeNotifier {
  static const String lastPlayIndexCacheKey = 'lastPlayIndexKey';
  static const String lastPlayModeCacheKey = 'lastPlayModeKey';
  static const String lastPlayingListCacheKey = 'lastPlayingListKey';

  //失败之后连续自动播放下一首的个数(超过3个将不在自动播放下一首)
  int _continuousPlayback = 0;
  bool _playStartNeedPlayNow = true;

  Player player = PlayerPlayback.instance.player;

  late VoidCallback _mediaListener;
  late VoidCallback _playModeListener;
  late VoidCallback _fileListListener;
  StreamSubscription? _playStatusSub;
  StreamSubscription? _playerRecoverSub;

  static final PlayController _instance = PlayController._();
  static PlayController get instance => _instance;
  factory PlayController() {
    return _instance;
  }
  PlayController._(){
    _mediaListener = () async {
      FileInfo? fileInfo = player.currentMediaInfo.value;
      if(fileInfo != null) {
        if(fileInfo.type != FileType.MUSIC_VIDEO_TYPE_PODCAST_EPISODE.name) {
          if (fileInfo.cacheDownloadTaskId != null ||
              DownloadTaskStatus.fromInt(fileInfo.downloadStatus) != DownloadTaskStatus.running ||
              DownloadTaskStatus.fromInt(fileInfo.downloadStatus) != DownloadTaskStatus.enqueued) {
            //缓存当前音乐
            FileDownloader.cache(fileInfo: fileInfo, httpClient: PlayerHttpClient());
          }
        }
        int currentIndex = player.playMediaList.indexOf(fileInfo);
        FileInfo? nextFileInfo;
        if (player.hasNext()) {
          nextFileInfo = player.playMediaList[currentIndex + 1];
        } else if (player.playMediaList.isNotEmpty) {
          nextFileInfo = player.playMediaList[0];
        }
        if(nextFileInfo != null){
          //1.正在缓存的不用提前缓存
          //2.正在下载的不用提前缓存
          //3.文件比较大的不提前缓存
          if(nextFileInfo.type != FileType.MUSIC_VIDEO_TYPE_PODCAST_EPISODE.name) {
            if (nextFileInfo.cacheDownloadTaskId != null ||
                DownloadTaskStatus.fromInt(nextFileInfo.downloadStatus) != DownloadTaskStatus.running ||
                DownloadTaskStatus.fromInt(nextFileInfo.downloadStatus) != DownloadTaskStatus.enqueued) {
              //缓存下一个音乐
              FileDownloader.cache(fileInfo: nextFileInfo, httpClient: PlayerHttpClient());
            }
          }
        }
        //记住上次的播放的index
        SharedPreferences sp = await SharedPreferences.getInstance();
        sp.setInt(lastPlayIndexCacheKey, currentIndex);
      }
    };
    player.currentMediaInfo.addListener(_mediaListener);

    _playModeListener = () async {
      //记住上次的播放模式
      SharedPreferences sp = await SharedPreferences.getInstance();
      sp.setInt(lastPlayModeCacheKey, PlayerPlayback.instance.playModeInfo.value.mode.index);
    };
    PlayerPlayback.instance.playModeInfo.addListener(_playModeListener);

    _playStatusSub = player.playStatusStream.listen((playState) {
      if(playState.state == PlayState.start ||
          playState.state == PlayState.playIndex ||
          playState.state == PlayState.previous ||
          playState.state == PlayState.next){
        _playStartNeedPlayNow = playState.startPlay??false;
      }
      else if (playState.state == PlayState.loadFinish) {
        _continuousPlayback = 0;
      }
      else if (playState.state == PlayState.loadFailed) {
        FileInfo? fileInfo = playState.fileInfo;
        if(player.currentMediaInfo.value==fileInfo) {
          ToastUtil.showError('Play Failed.'.translate);
          if (_continuousPlayback < 4 && _playStartNeedPlayNow==true) {
            player.playNext(startPlay: _playStartNeedPlayNow);
            _continuousPlayback++;
          }
        }
      }
    });

    _fileListListener = () async {
      //记住上次正常播放的列表
      List<FileInfo> fileList = PlayerPlayback.instance.showPlayFileList.value;
      List<Map> fileMapList = [];
      for(final fileInfo in fileList){
        fileMapList.add(fileInfo.toJson());
      }
      final jsonString = jsonEncode(fileMapList);
      SharedPreferences sp = await SharedPreferences.getInstance();
      sp.setString(lastPlayingListCacheKey, jsonString);
    };
    PlayerPlayback.instance.showPlayFileList.addListener(_fileListListener);

    _playerRecoverSub = PlayerRecoverHelper.listen();
  }

  Future<String?> queryMediaDetail(FileInfo fileInfo) async {
    Map<String, dynamic>? params = {'videoId': fileInfo.fileId};
    dynamic result = await YTMNetwork.post(
      url: YTMApis.player,
      prams: params,
      isApp: true,
    );
    String? url = ParseUtil.parse<String>(result, PlayParseKeys.fileUrl);
    url ??= ParseUtil.parse<String>(result, PlayParseKeys.liveFileUrl);
    String? channelId = ParseUtil.parse<String>(result, PlayParseKeys.channelId);
    String? author = ParseUtil.parse<String>(result, PlayParseKeys.author);
    if(url != null || channelId!=null){
      fileInfo.url = url;
      fileInfo.uid = channelId;
      fileInfo.userName = author;
      FileInfoDataOperate.insertFileInfo(fileInfo);
    }
    return url;
  }

  @override
  void dispose() {
    player.currentMediaInfo.removeListener(_mediaListener);
    PlayerPlayback.instance.playModeInfo.removeListener(_playModeListener);
    PlayerPlayback.instance.showPlayFileList.removeListener(_fileListListener);
    _playStatusSub?.cancel();
    _playerRecoverSub?.cancel();
    super.dispose();
  }
}

class PlayParseKeys {
  static List fileUrl = [
    'streamingData',
    'formats',
    {
      'index': 0,
    },
    'url',
  ];
  static List liveFileUrl = [
    'streamingData',
    'hlsManifestUrl',
  ];

  //大概率是该歌曲的歌手id
  static List channelId = [
    'videoDetails',
    'channelId',
  ];
  static List author = [
    'videoDetails',
    'author',
  ];
}