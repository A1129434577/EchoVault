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
  factory PlaybackCoordinator() {
    return _instance;
  }
  PlaybackCoordinator._() {
    _mediaListener = () async {
      FileInfo? mediaEntry = player.currentMediaInfo.value;
      if (mediaEntry != null) {
        if (mediaEntry.type !=
            MediaType.MUSIC_VIDEO_TYPE_PODCAST_EPISODE.name) {
          if (mediaEntry.cacheDownloadTaskId != null ||
              DownloadTaskStatus.fromInt(mediaEntry.downloadStatus) !=
                  DownloadTaskStatus.running ||
              DownloadTaskStatus.fromInt(mediaEntry.downloadStatus) !=
                  DownloadTaskStatus.enqueued) {
            //缓存当前音乐
            MediaTransferService.cache(
              mediaEntry: mediaEntry,
              httpClientArg: PlaybackHttpTransport(),
            );
          }
        }
        int currentIndexLocal = player.playMediaList.indexOf(mediaEntry);
        FileInfo? nextFileInfoLocal;
        if (player.hasNext()) {
          nextFileInfoLocal = player.playMediaList[currentIndexLocal + 1];
        } else if (player.playMediaList.isNotEmpty) {
          nextFileInfoLocal = player.playMediaList[0];
        }
        if (nextFileInfoLocal != null) {
          //1.正在缓存的不用提前缓存
          //2.正在下载的不用提前缓存
          //3.文件比较大的不提前缓存
          if (nextFileInfoLocal.type !=
              MediaType.MUSIC_VIDEO_TYPE_PODCAST_EPISODE.name) {
            if (nextFileInfoLocal.cacheDownloadTaskId != null ||
                DownloadTaskStatus.fromInt(nextFileInfoLocal.downloadStatus) !=
                    DownloadTaskStatus.running ||
                DownloadTaskStatus.fromInt(nextFileInfoLocal.downloadStatus) !=
                    DownloadTaskStatus.enqueued) {
              //缓存下一个音乐
              MediaTransferService.cache(
                mediaEntry: nextFileInfoLocal,
                httpClientArg: PlaybackHttpTransport(),
              );
            }
          }
        }
        //记住上次的播放的index
        SharedPreferences spLocal = await SharedPreferences.getInstance();
        spLocal.setInt(lastPlayIndexCacheKey, currentIndexLocal);
      }
    };
    player.currentMediaInfo.addListener(_mediaListener);

    _playModeListener = () async {
      //记住上次的播放模式
      SharedPreferences spLocal = await SharedPreferences.getInstance();
      spLocal.setInt(
        lastPlayModeCacheKey,
        PlayerPlayback.instance.playModeInfo.value.mode.index,
      );
    };
    PlayerPlayback.instance.playModeInfo.addListener(_playModeListener);

    _playStatusSub = player.playStatusStream.listen((playStateInputArg) {
      if (playStateInputArg.state == PlayState.start ||
          playStateInputArg.state == PlayState.playIndex ||
          playStateInputArg.state == PlayState.previous ||
          playStateInputArg.state == PlayState.next) {
        _playStartNeedPlayNow = playStateInputArg.startPlay ?? false;
      } else if (playStateInputArg.state == PlayState.loadFinish) {
        _continuousPlayback = 0;
      } else if (playStateInputArg.state == PlayState.loadFailed) {
        FileInfo? mediaEntry = playStateInputArg.fileInfo;
        if (player.currentMediaInfo.value == mediaEntry) {
          MessageOverlay.presentError('Play Failed.'.translate);
          if (_continuousPlayback < 4 && _playStartNeedPlayNow == true) {
            player.playNext(startPlay: _playStartNeedPlayNow);
            _continuousPlayback++;
          }
        }
      }
    });

    _fileListListener = () async {
      //记住上次正常播放的列表
      List<FileInfo> mediaQueue =
          PlayerPlayback.instance.showPlayFileList.value;
      List<Map> fileMapListLocal = [];
      for (final mediaDetails in mediaQueue) {
        fileMapListLocal.add(mediaDetails.toJson());
      }
      final serializedJson = jsonEncode(fileMapListLocal);
      SharedPreferences spLocal = await SharedPreferences.getInstance();
      spLocal.setString(lastPlayingListCacheKey, serializedJson);
    };
    PlayerPlayback.instance.showPlayFileList.addListener(_fileListListener);

    _playerRecoverSub = PlayerRecoverHelper.listen();
  }
  static PlaybackCoordinator get instance => _instance;

  @override
  void dispose() {
    player.currentMediaInfo.removeListener(_mediaListener);
    PlayerPlayback.instance.playModeInfo.removeListener(_playModeListener);
    PlayerPlayback.instance.showPlayFileList.removeListener(_fileListListener);
    _playStatusSub?.cancel();
    _playerRecoverSub?.cancel();
    super.dispose();
  }

  Future<String?> fetchMediaDetail(FileInfo mediaEntry) async {
    Map<String, dynamic>? requestParameters = {'videoId': mediaEntry.fileId};
    dynamic response = await MusicCatalogGateway.post(
      resourceUrl: MusicCatalogEndpoints.player,
      pramsArg: requestParameters,
      isAppArg: true,
    );
    String? resourceUrl = ParserHelper.parse<String>(
      response,
      PlaybackQueueParserKeys.fileUrl,
    );
    resourceUrl ??= ParserHelper.parse<String>(
      response,
      PlaybackQueueParserKeys.liveFileUrl,
    );
    String? channelIdLocal = ParserHelper.parse<String>(
      response,
      PlaybackQueueParserKeys.channelId,
    );
    String? authorLocal = ParserHelper.parse<String>(
      response,
      PlaybackQueueParserKeys.author,
    );
    if (resourceUrl != null || channelIdLocal != null) {
      mediaEntry.url = resourceUrl;
      mediaEntry.uid = channelIdLocal;
      mediaEntry.userName = authorLocal;
      MediaRepository.addFileInfo(mediaEntry);
    }
    return resourceUrl;
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
