import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/monetization/advertising_coordinator.dart';
import 'package:echo_vault/features/discovery/controllers/discovery_state.dart';
import 'package:echo_vault/core/networking/music_catalog_gateway.dart';
import 'package:echo_vault/core/parsing/shared_parser.dart';
import 'package:echo_vault/core/parsing/music_catalog_parser.dart';
import 'package:echo_vault/core/parsing/parser_helper.dart';

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

class PlaybackScreenState with ChangeNotifier {
  final Player player = PlayerPlayback.instance.player;
  final ValueNotifier<AdInfo?> playNatoAd = ValueNotifier(
    AdHelper.adSceneCacheInfo[AdvertisingScene.playNative],
  );

  StreamSubscription? _adLoadSubscription;

  final FileInfo? mediaDetails;

  String? playlistId;
  PlaybackScreenState({this.mediaDetails}) {
    AdHelper.loadSceneAdIfNull(
      scene: AdvertisingScene.playNative,
      detailScene: AdvertisingDetailScene.play,
    );
    _adLoadSubscription = AdHelper.adLoadStatusStream.listen((adInfoInputArg) {
      if (adInfoInputArg.scene == AdvertisingScene.playNative) {
        if (adInfoInputArg.loadState == AdLoadStatus.loaded) {
          playNatoAd.value = adInfoInputArg;
        }
      }
    });
  }

  @override
  void dispose() {
    _adLoadSubscription?.cancel();
    super.dispose();
  }

  Future fetchRecommendList() async {
    if (DiscoveryState.instance.isYoutubeMusicEnable.value) {
      await _fetchRecommendList();
    } else {
      await _fetchYTRecommendList();
    }
  }

  Future _fetchRecommendList() async {
    if (mediaDetails == null) {
      return;
    }
    Map<String, dynamic>? requestParameters = {'videoId': mediaDetails?.fileId};
    if (playlistId != null) {
      requestParameters['playlistId'] = playlistId;
    }
    //请求接下来播放列表需要用到playlistId,所以如果没有playlistId的话要先通过next接口拿到playlistId
    dynamic response = await MusicCatalogGateway.post(
      resourceUrl: MusicCatalogEndpoints.playRecommend,
      pramsArg: requestParameters,
    );
    if (playlistId == null) {
      playlistId = ParserHelper.parse<String>(
        response,
        PlaybackParserKeys.nextPlayListId,
      );
      fetchRecommendList();
    } else {
      List responses =
          ParserHelper.parse<List>(
            response,
            PlaybackParserKeys.nextPlaylistResourceList,
          ) ??
          [];
      final suggestedItems = await SharedParser.decodeChildren(responses);
      PlayerPlayback.instance.insertPlayList(suggestedItems.cast<FileInfo>());
    }
  }

  Future _fetchYTRecommendList() async {
    if (mediaDetails == null) {
      return;
    }
    Map<String, dynamic>? requestParameters = {'videoId': mediaDetails?.fileId};
    dynamic response = await MusicCatalogGateway.post(
      resourceUrl: MusicCatalogEndpoints.ytPlayRecommend,
      pramsArg: requestParameters,
      isMusicArg: false,
    );
    List responses =
        ParserHelper.parse<List>(
          response,
          PlaybackSuggestionParserKeys.resourceList,
        ) ??
        [];
    final suggestedItems = await MusicCatalogParser.decodePlayRecommendChildren(
      responses,
    );
    PlayerPlayback.instance.insertPlayList(suggestedItems.cast<FileInfo>());
  }
}
