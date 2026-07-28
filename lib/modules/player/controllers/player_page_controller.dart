import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/ads/ads_manager.dart';
import 'package:echo_vault/modules/home/controllers/home_controller.dart';
import 'package:echo_vault/network/ytm_network.dart';
import 'package:echo_vault/parse/common_parse.dart';
import 'package:echo_vault/parse/common_yt_parse.dart';
import 'package:echo_vault/parse/parse_util.dart';

class PlayerPageController with ChangeNotifier {
  final Player player = PlayerPlayback.instance.player;
  final ValueNotifier<AdInfo?> playNatoAd = ValueNotifier(AdHelper.adSceneCacheInfo[AdsManagerScene.playNative]);

  StreamSubscription? _adLoadSubscription;

  final FileInfo? fileInfo;
  PlayerPageController({
    this.fileInfo,
  }){
    AdHelper.loadSceneAdIfNull(scene: AdsManagerScene.playNative, detailScene: AdsManagerDetailScene.play);
    _adLoadSubscription = AdHelper.adLoadStatusStream.listen((adInfo) {
      if(adInfo.scene == AdsManagerScene.playNative){
        if (adInfo.loadState == AdLoadStatus.loaded) {
          playNatoAd.value = adInfo;
        }
      }
    });
  }

  @override
  void dispose() {
    _adLoadSubscription?.cancel();
    super.dispose();
  }

  Future queryRecommendList() async {
    if(HomeController.instance.isYoutubeMusicEnable.value){
      await _queryRecommendList();
    }else{
      await _queryYTRecommendList();
    }
  }

  String? playlistId;
  Future _queryRecommendList() async {
    if(fileInfo == null){
      return;
    }
    Map<String, dynamic>? params = {'videoId': fileInfo?.fileId};
    if (playlistId != null) {
      params['playlistId'] = playlistId;
    }
    //请求接下来播放列表需要用到playlistId,所以如果没有playlistId的话要先通过next接口拿到playlistId
    dynamic result = await YTMNetwork.post(
      url: YTMApis.playRecommend,
      prams: params,
    );
    if (playlistId == null) {
      playlistId = ParseUtil.parse<String>(result, PlayerParseKeys.nextPlayListId);
      queryRecommendList();
    }else{
      List resultList = ParseUtil.parse<List>(result, PlayerParseKeys.nextPlaylistResourceList)??[];
      final recommendList = await CommonParse.parseChildren(resultList);
      PlayerPlayback.instance.insertPlayList(recommendList.cast<FileInfo>());
    }
  }


  Future _queryYTRecommendList() async {
    if(fileInfo == null){
      return;
    }
    Map<String, dynamic>? params = {'videoId': fileInfo?.fileId};
    dynamic result = await YTMNetwork.post(
      url: YTMApis.ytPlayRecommend,
      prams: params,
      isMusic: false
    );
    List resultList = ParseUtil.parse<List>(result, PlayRecommendYTParseKeys.resourceList)??[];
    final recommendList = await CommonYtParse.parsePlayRecommendChildren(resultList);
    PlayerPlayback.instance.insertPlayList(recommendList.cast<FileInfo>());
  }
}

class PlayerParseKeys {
  ///接下来播放的playlistId
  static List nextPlayListId = [
    'contents',
    'singleColumnMusicWatchNextResultsRenderer',
    'tabbedRenderer',
    'watchNextTabbedResultsRenderer',
    'tabs',
    {
      ParseUtil.indexKey: 0,
    },
    'tabRenderer',
    'content',
    'musicQueueRenderer',
    'content',
    'playlistPanelRenderer',
    'contents',
    {
      ParseUtil.filterKey: 'automixPreviewVideoRenderer',
    },
    {
      ParseUtil.indexKey: 0,
    },
    'automixPreviewVideoRenderer',
    'content',
    'automixPlaylistVideoRenderer',
    'navigationEndpoint',
    'watchPlaylistEndpoint',
    'playlistId',
  ];

  static List nextPlaylistResourceList = [
    'contents',
    'singleColumnMusicWatchNextResultsRenderer',
    'tabbedRenderer',
    'watchNextTabbedResultsRenderer',
    'tabs',
    {
      ParseUtil.indexKey: 0,
    },
    'tabRenderer',
    'content',
    'musicQueueRenderer',
    'content',
    'playlistPanelRenderer',
    'contents',
  ];
}
