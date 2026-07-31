import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/state/media_transfer_service.dart';
import 'package:echo_vault/core/persistence/media_repository.dart';
import 'package:echo_vault/core/networking/playback_http_transport.dart';
import 'package:echo_vault/core/networking/music_catalog_gateway.dart';
import 'package:echo_vault/core/parsing/shared_parser.dart';
import 'package:echo_vault/core/parsing/parser_helper.dart';
import 'package:echo_vault/core/utilities/message_overlay.dart';

class PlaybackCoordinator with ChangeNotifier {
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

  static final PlaybackCoordinator _instance = PlaybackCoordinator._();
  static PlaybackCoordinator get instance => _instance;
  factory PlaybackCoordinator() {
    return _instance;
  }
  PlaybackCoordinator._() {
    _mediaListener = () async {
      FileInfo? mediaDetails = player.currentMediaInfo.value;
      if (mediaDetails != null) {
        if (mediaDetails.type !=
            MediaType.MUSIC_VIDEO_TYPE_PODCAST_EPISODE.name) {
          if (mediaDetails.cacheDownloadTaskId != null ||
              DownloadTaskStatus.fromInt(mediaDetails.downloadStatus) !=
                  DownloadTaskStatus.running ||
              DownloadTaskStatus.fromInt(mediaDetails.downloadStatus) !=
                  DownloadTaskStatus.enqueued) {
            //缓存当前音乐
            MediaTransferService.cache(
              mediaDetails: mediaDetails,
              httpClient: PlaybackHttpTransport(),
            );
          }
        }
        int currentIndex = player.playMediaList.indexOf(mediaDetails);
        FileInfo? nextFileInfo;
        if (player.hasNext()) {
          nextFileInfo = player.playMediaList[currentIndex + 1];
        } else if (player.playMediaList.isNotEmpty) {
          nextFileInfo = player.playMediaList[0];
        }
        if (nextFileInfo != null) {
          //1.正在缓存的不用提前缓存
          //2.正在下载的不用提前缓存
          //3.文件比较大的不提前缓存
          if (nextFileInfo.type !=
              MediaType.MUSIC_VIDEO_TYPE_PODCAST_EPISODE.name) {
            if (nextFileInfo.cacheDownloadTaskId != null ||
                DownloadTaskStatus.fromInt(nextFileInfo.downloadStatus) !=
                    DownloadTaskStatus.running ||
                DownloadTaskStatus.fromInt(nextFileInfo.downloadStatus) !=
                    DownloadTaskStatus.enqueued) {
              //缓存下一个音乐
              MediaTransferService.cache(
                mediaDetails: nextFileInfo,
                httpClient: PlaybackHttpTransport(),
              );
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
      sp.setInt(
        lastPlayModeCacheKey,
        PlayerPlayback.instance.playModeInfo.value.mode.index,
      );
    };
    PlayerPlayback.instance.playModeInfo.addListener(_playModeListener);

    _playStatusSub = player.playStatusStream.listen((playState) {
      if (playState.state == PlayState.start ||
          playState.state == PlayState.playIndex ||
          playState.state == PlayState.previous ||
          playState.state == PlayState.next) {
        _playStartNeedPlayNow = playState.startPlay ?? false;
      } else if (playState.state == PlayState.loadFinish) {
        _continuousPlayback = 0;
      } else if (playState.state == PlayState.loadFailed) {
        FileInfo? mediaDetails = playState.fileInfo;
        if (player.currentMediaInfo.value == mediaDetails) {
          MessageOverlay.showError('Play Failed.'.translate);
          if (_continuousPlayback < 4 && _playStartNeedPlayNow == true) {
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
      for (final mediaDetails in fileList) {
        fileMapList.add(mediaDetails.toJson());
      }
      final jsonString = jsonEncode(fileMapList);
      SharedPreferences sp = await SharedPreferences.getInstance();
      sp.setString(lastPlayingListCacheKey, jsonString);
    };
    PlayerPlayback.instance.showPlayFileList.addListener(_fileListListener);

    _playerRecoverSub = PlayerRecoverHelper.listen();
  }

  Future<String?> queryMediaDetail(FileInfo mediaDetails) async {
    Map<String, dynamic>? params = {'videoId': mediaDetails.fileId};
    dynamic result = await MusicCatalogGateway.post(
      url: MusicCatalogEndpoints.player,
      prams: params,
      isApp: true,
    );
    String? url = ParserHelper.parse<String>(
      result,
      PlaybackQueueParserKeys.fileUrl,
    );
    url ??= ParserHelper.parse<String>(
      result,
      PlaybackQueueParserKeys.liveFileUrl,
    );
    String? channelId = ParserHelper.parse<String>(
      result,
      PlaybackQueueParserKeys.channelId,
    );
    String? author = ParserHelper.parse<String>(
      result,
      PlaybackQueueParserKeys.author,
    );
    if (url != null || channelId != null) {
      mediaDetails.url = url;
      mediaDetails.uid = channelId;
      mediaDetails.userName = author;
      MediaRepository.insertFileInfo(mediaDetails);
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

class PlaybackQueueParserKeys {
  static List fileUrl = [
    'streamingData',
    'formats',
    {'index': 0},
    'url',
  ];
  static List liveFileUrl = ['streamingData', 'hlsManifestUrl'];

  //大概率是该歌曲的歌手id
  static List channelId = ['videoDetails', 'channelId'];
  static List author = ['videoDetails', 'author'];
}
