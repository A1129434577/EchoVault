import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ad/ad.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/state/media_transfer_service.dart';
import 'package:echo_vault/core/persistence/media_repository.dart';
import 'package:echo_vault/core/persistence/user_preference_keys.dart';
import 'package:echo_vault/core/networking/playback_http_transport.dart';
import 'package:echo_vault/core/networking/music_catalog_gateway.dart';
import 'package:echo_vault/core/parsing/shared_parser.dart';
import 'package:echo_vault/core/parsing/parser_helper.dart';
import 'package:echo_vault/core/utilities/message_overlay.dart';

class PlaybackCoordinator with ChangeNotifier {
  //失败之后连续自动播放下一首的个数(超过3个将不在自动播放下一首)
  int _continuousPlayback = 0;
  bool _playStartNeedPlayNow = true;

  Player player = PlayerPlayback.instance.player;

  late VoidCallback _mediaListener;
  late VoidCallback _playModeListener;
  late VoidCallback _fileListListener;
  late VoidCallback _adVisibleListener;
  StreamSubscription? _playStatusSub;
  StreamSubscription? _playerRecoverSub;
  Timer? _recoverTimer;

  static final PlaybackCoordinator _sharedCoordinator = PlaybackCoordinator._();
  factory PlaybackCoordinator() {
    return _sharedCoordinator;
  }
  PlaybackCoordinator._() {
    _mediaListener = () async {
      FileInfo? mediaEntry = player.currentMediaInfo.value;
      if (mediaEntry != null) {
        if (mediaEntry.type !=
            MediaType.MUSIC_VIDEO_TYPE_PODCAST_EPISODE.name) {
          if (MediaTransferService.activeDownloads.values.where((e)=>e.fileId==mediaEntry.fileId).isEmpty &&
              MediaTransferService.activeCacheTasks.values.where((e)=>e.fileId==mediaEntry.fileId).isEmpty) {
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
            if (MediaTransferService.activeDownloads.values.where((e)=>e.fileId==mediaEntry.fileId).isEmpty &&
                MediaTransferService.activeCacheTasks.values.where((e)=>e.fileId==mediaEntry.fileId).isEmpty) {
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
        spLocal.setInt(UserPreferenceKeys.playbackIndex, currentIndexLocal);
      }
    };
    player.currentMediaInfo.addListener(_mediaListener);

    _playModeListener = () async {
      //记住上次的播放模式
      SharedPreferences spLocal = await SharedPreferences.getInstance();
      spLocal.setInt(
        UserPreferenceKeys.playbackMode,
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
          MessageOverlay.presentError('Unable to play this track.'.translate);
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
      spLocal.setString(UserPreferenceKeys.playbackQueue, serializedJson);
    };
    PlayerPlayback.instance.showPlayFileList.addListener(_fileListListener);

    _playerRecover();
  }
  static PlaybackCoordinator get instance => _sharedCoordinator;

  void _playerRecover() {
    _playerRecoverSub = PlayerRecoverHelper.listen();
    _adVisibleListener = () {
      //ios任何局部广告或全屏广告播放过程中AudioSession容易被中断，所以需要恢复一下
      if (AdHelper.isFullScreenAdShowing.value ||
          AdHelper.isNativePartAdVisible.value) {
        if (Platform.isIOS && PlayerRecoverHelper.isManualPause == false) {
          _recoverTimer ??= Timer.periodic(Duration(milliseconds: 500), (
            timer,
          ) async {
            await PlayerPlayback.instance.audioSession.configure(
              AudioSessionConfiguration.music(),
            );
            await PlayerPlayback.instance.audioSession.setActive(true);
          });
        }
      } else {
        _recoverTimer?.cancel();
        _recoverTimer = null;
      }
    };
    AdHelper.isFullScreenAdShowing.addListener(_adVisibleListener);
    AdHelper.isNativePartAdVisible.addListener(_adVisibleListener);
  }

  @override
  void dispose() {
    player.currentMediaInfo.removeListener(_mediaListener);
    PlayerPlayback.instance.playModeInfo.removeListener(_playModeListener);
    PlayerPlayback.instance.showPlayFileList.removeListener(_fileListListener);
    AdHelper.isFullScreenAdShowing.removeListener(_adVisibleListener);
    AdHelper.isNativePartAdVisible.removeListener(_adVisibleListener);
    _playStatusSub?.cancel();
    _playerRecoverSub?.cancel();
    _recoverTimer?.cancel();
    _recoverTimer = null;
    super.dispose();
  }

  Future<String?> fetchMediaDetail(FileInfo mediaEntry) async {
    Map<String, dynamic>? requestParameters = {'videoId': mediaEntry.fileId};
    dynamic response = await MusicCatalogGateway.post(
      resourceUrl: MusicCatalogEndpoints.playbackInfo,
      pramsArg: requestParameters,
      isAppArg: true,
    );
    String? resourceUrl = ParserHelper.parse<String>(
      response,
      PlaybackQueueParserKeys.audioStreamPath,
    );
    resourceUrl ??= ParserHelper.parse<String>(
      response,
      PlaybackQueueParserKeys.liveStreamPath,
    );
    String? channelIdLocal = ParserHelper.parse<String>(
      response,
      PlaybackQueueParserKeys.channelIdPath,
    );
    String? authorLocal = ParserHelper.parse<String>(
      response,
      PlaybackQueueParserKeys.authorPath,
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
  static List audioStreamPath = [
    'streamingData',
    'formats',
    {'index': 0},
    'url',
  ];
  static List liveStreamPath = ['streamingData', 'hlsManifestUrl'];

  //大概率是该歌曲的歌手id
  static List channelIdPath = ['videoDetails', 'channelId'];
  static List authorPath = ['videoDetails', 'author'];
}
