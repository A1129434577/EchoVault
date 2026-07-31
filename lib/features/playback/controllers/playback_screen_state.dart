import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/monetization/advertising_coordinator.dart';
import 'package:echo_vault/features/discovery/controllers/discovery_state.dart';
import 'package:echo_vault/core/networking/music_catalog_gateway.dart';
import 'package:echo_vault/core/parsing/shared_parser.dart';
import 'package:echo_vault/core/parsing/music_catalog_parser.dart';
import 'package:echo_vault/core/parsing/parser_helper.dart';

class PlaybackScreenState with ChangeNotifier {
  final Player player = PlayerPlayback.instance.player;
  final ValueNotifier<AdInfo?> playNatoAd = ValueNotifier(
    AdHelper.adSceneCacheInfo[AdvertisingScene.playNative],
  );

  StreamSubscription? _adLoadSubscription;

  final FileInfo? mediaDetails;
  PlaybackScreenState({this.mediaDetails}) {
    AdHelper.loadSceneAdIfNull(
      scene: AdvertisingScene.playNative,
      detailScene: AdvertisingDetailScene.play,
    );
    _adLoadSubscription = AdHelper.adLoadStatusStream.listen((adInfo) {
      if (adInfo.scene == AdvertisingScene.playNative) {
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
    if (DiscoveryState.instance.isYoutubeMusicEnable.value) {
      await _queryRecommendList();
    } else {
      await _queryYTRecommendList();
    }
  }

  String? playlistId;
  Future _queryRecommendList() async {
    if (mediaDetails == null) {
      return;
    }
    Map<String, dynamic>? params = {'videoId': mediaDetails?.fileId};
    if (playlistId != null) {
      params['playlistId'] = playlistId;
    }
    //请求接下来播放列表需要用到playlistId,所以如果没有playlistId的话要先通过next接口拿到playlistId
    dynamic result = await MusicCatalogGateway.post(
      url: MusicCatalogEndpoints.playRecommend,
      prams: params,
    );
    if (playlistId == null) {
      playlistId = ParserHelper.parse<String>(
        result,
        PlaybackParserKeys.nextPlayListId,
      );
      queryRecommendList();
    } else {
      List results =
          ParserHelper.parse<List>(
            result,
            PlaybackParserKeys.nextPlaylistResourceList,
          ) ??
          [];
      final recommendList = await SharedParser.parseChildren(results);
      PlayerPlayback.instance.insertPlayList(recommendList.cast<FileInfo>());
    }
  }

  Future _queryYTRecommendList() async {
    if (mediaDetails == null) {
      return;
    }
    Map<String, dynamic>? params = {'videoId': mediaDetails?.fileId};
    dynamic result = await MusicCatalogGateway.post(
      url: MusicCatalogEndpoints.ytPlayRecommend,
      prams: params,
      isMusic: false,
    );
    List results =
        ParserHelper.parse<List>(
          result,
          PlaybackSuggestionParserKeys.resourceList,
        ) ??
        [];
    final recommendList = await MusicCatalogParser.parsePlayRecommendChildren(
      results,
    );
    PlayerPlayback.instance.insertPlayList(recommendList.cast<FileInfo>());
  }
}

class PlaybackParserKeys {
  ///接下来播放的playlistId
  static List nextPlayListId = [
    'contents',
    'singleColumnMusicWatchNextResultsRenderer',
    'tabbedRenderer',
    'watchNextTabbedResultsRenderer',
    'tabs',
    {ParserHelper.indexKey: 0},
    'tabRenderer',
    'content',
    'musicQueueRenderer',
    'content',
    'playlistPanelRenderer',
    'contents',
    {ParserHelper.filterKey: 'automixPreviewVideoRenderer'},
    {ParserHelper.indexKey: 0},
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
    {ParserHelper.indexKey: 0},
    'tabRenderer',
    'content',
    'musicQueueRenderer',
    'content',
    'playlistPanelRenderer',
    'contents',
  ];
}
