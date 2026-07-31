import 'dart:convert';
import 'dart:io';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:player_base/utils/debounce_util.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/shared/dialogs/new_collection_dialog.dart';
import 'package:echo_vault/core/state/transfer_media_state.dart';
import 'package:echo_vault/core/state/bookmark_performer_state.dart';
import 'package:echo_vault/core/state/bookmark_media_state.dart';
import 'package:echo_vault/core/persistence/performer_repository.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/persistence/media_repository.dart';
import 'package:echo_vault/core/media/media_origin.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/utils/string_cipher.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/features/catalog/controllers/catalog_state.dart';
import 'package:echo_vault/features/playback/controllers/playback_coordinator.dart';
import 'package:echo_vault/core/networking/music_catalog_gateway.dart';
import 'package:echo_vault/core/parsing/shared_parser.dart';
import 'package:echo_vault/core/parsing/music_catalog_parser.dart';
import 'package:echo_vault/core/parsing/parser_helper.dart';
import 'package:echo_vault/core/utilities/message_overlay.dart';

class DiscoveryState with ChangeNotifier {
  static final DiscoveryState _instance = DiscoveryState._();
  static DiscoveryState get instance => _instance;
  factory DiscoveryState() {
    return _instance;
  }
  DiscoveryState._() {
    PlayerPlayback.instance.player.playStatusStream.listen((playState) {
      FileInfo? mediaDetails = playState.fileInfo;
      if (playState.isAuto == false) {
        if (playState.state == PlayState.start ||
            playState.state == PlayState.playIndex) {
          if (mediaDetails != null) {
            mediaDetails.source1 = MediaOrigin.history;
            MediaRepository.insertFileInfo(mediaDetails);
            queryRecommend();
          }
        }
      }
    });
    TransferMediaState.downloadFinishAndRemoveStream.listen((mediaDetails) {
      queryRecommend();
      queryMyPlaylist();
    });
    BookmarkMediaState.favoriteStream.listen((mediaDetails) {
      queryRecommend();
      queryMyPlaylist();
    });
    //首页展示的是非空的播放列表，在歌曲被添加自某个播放列表之后首页数据会更新，
    //不仅仅是搜藏歌单，所以直接监听LibraryController.instance.mediaCollections
    CatalogState.instance.mediaCollections.addListener(() {
      queryMyPlaylist();
    });
    BookmarkPerformerState.favoriteStream.listen((mediaDetails) {
      queryMyArtist();
    });
  }

  ValueNotifier<bool> isYoutubeMusicEnable = ValueNotifier(true);

  EasyRefreshController refreshController = EasyRefreshController();

  DebouncedValueNotifier<List<FileInfo>> recommendList = DebouncedValueNotifier(
    [],
  );
  ValueNotifier<List<MediaCollection>> playlistList = ValueNotifier([]);
  ValueNotifier<List<PerformerDetails>> performers = ValueNotifier([]);
  ValueNotifier<List<MediaCollection>> topChartsList = ValueNotifier([]);
  ValueNotifier<List<MediaCollection>> resourceFileGroupList = ValueNotifier(
    [],
  );

  List _originalResourceList = [];

  Future queryAllLocalData() async {
    await queryRecommend();
    await queryMyPlaylist();
    await queryMyArtist();
    await queryTopCharts();
    await _getCacheResourceData();
    await _resumePlayback();
  }

  Future<List<FileInfo>> queryRecommend() async {
    List<FileInfo> list = await MediaRepository.queryFileInfo(
      where:
          '''
    (json_content LIKE '%${'"source1":"${MediaOrigin.history.name}"'}%')
    OR (json_content LIKE '%${'"source":"${MediaOrigin.homeReco.name}"'}%')
    OR (download_status = 3)
    OR (is_favorite = 1)
    ''',
    );
    for (final mediaDetails in list) {
      mediaDetails.source = MediaOrigin.homeReco;
    }
    if (list.isNotEmpty) {
      recommendList.value = list;
    }
    return list;
  }

  Future<List<MediaCollection>> queryMyPlaylist() async {
    List<MediaCollection> mediaCollections = [];
    List<FileInfo> likedList = await CatalogState.instance.queryLikedList();
    if (likedList.isNotEmpty) {
      mediaCollections.add(
        MediaCollection(
          name: 'Like songs'.translate,
          thumbnail: Assets.images.collection.listFavorite.path,
          children: likedList,
        ),
      );
    }
    List<FileInfo> savedList = await CatalogState.instance.querySavedList();
    if (savedList.isNotEmpty) {
      mediaCollections.add(
        MediaCollection(
          name: 'Local songs'.translate,
          thumbnail: Assets.images.collection.listSaved.path,
          children: savedList,
        ),
      );
    }
    List<MediaCollection> groupList =
        CatalogState.instance.mediaCollections.value;
    List<MediaCollection> newGroupList = [];
    for (final group in groupList) {
      if (group.id?.startsWith(NewCollectionDialog.createPlaylistNamePrefix) ==
          true) {
        if (group.children.isNotEmpty) {
          newGroupList.add(group);
        }
      } else {
        newGroupList.add(group);
      }
    }
    mediaCollections.addAll(newGroupList);
    playlistList.value = mediaCollections;
    return mediaCollections;
  }

  Future<List<PerformerDetails>> queryMyArtist() async {
    List<PerformerDetails> list = await PerformerRepository.queryArtistInfo();
    if (list.isEmpty) {
      final encryptedJson = await rootBundle.loadString(
        Assets.data.artSeed,
      );
      String artisJsonString = StringCipher.decrypt(encryptedJson);
      List artisMapList = jsonDecode(artisJsonString);
      for (final artistMap in artisMapList) {
        PerformerDetails performerDetails = PerformerDetails.fromJson(
          artistMap,
        );
        await PerformerRepository.insertArtistInfo(performerDetails);
        list.add(performerDetails);
      }
    }
    performers.value = list;
    return list;
  }

  Future<List<MediaCollection>> queryTopCharts() async {
    List<MediaCollection> mediaCollections = [];
    final encryptedJson = await rootBundle.loadString(
      Assets.data.topSeed,
    );
    String jsonString = StringCipher.decrypt(encryptedJson);
    Map data = jsonDecode(jsonString);
    Locale sysLocale = WidgetsBinding.instance.platformDispatcher.locale;
    String countryCode = sysLocale.countryCode?.toLowerCase() ?? "us";
    List jsonList = data['us'];
    if (countryCode.contains('br')) {
      jsonList = data['br'];
    } else if (countryCode.contains('mx')) {
      jsonList = data['mx'];
    }
    for (final map in jsonList) {
      MediaCollection mediaCollection = MediaCollection.fromJson(map);
      mediaCollection.thumbnail =
          Assets.images.media.albumPlaceholder.path;
      mediaCollection.playlistType =
          CollectionType.LOCKUP_CONTENT_TYPE_PLAYLIST.name;
      mediaCollections.add(mediaCollection);
    }
    topChartsList.value = mediaCollections;
    return mediaCollections;
  }

  Future _getCacheResourceData() async {
    String cachePath =
        '${await FileInfo.filesCacheDirectoryPath}${Platform.pathSeparator}home_cache_data';
    File file = File(cachePath);
    if (file.existsSync()) {
      String jsonString = await file.readAsString();
      List l = [];
      try {
        l = jsonDecode(jsonString);
      } catch (_) {}
      if (l.isEmpty) {
        file.deleteSync();
        return;
      }
      _originalResourceList = l;
      List<MediaCollection> list = await SharedParser.parseContents(
        _originalResourceList,
      );
      if (list.isEmpty) {
        isYoutubeMusicEnable.value = false;
        list = await MusicCatalogParser.parseHomeContents(
          _originalResourceList,
        );
      }
      resourceFileGroupList.value.addAll(list);
      resourceFileGroupList.notifyListeners();
    }
  }

  Future _cacheResourceData() async {
    String cachePath =
        '${await FileInfo.filesCacheDirectoryPath}${Platform.pathSeparator}home_cache_data';
    File file = File(cachePath);
    await file.writeAsString(jsonEncode(_originalResourceList));
  }

  //恢复之前的播放
  Future _resumePlayback() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? jsonString = sp.getString(
      PlaybackCoordinator.lastPlayingListCacheKey,
    );
    if (jsonString != null) {
      final fileMapList = jsonDecode(jsonString);
      if (fileMapList.isNotEmpty) {
        List<FileInfo> fileList = [];
        for (final info in fileMapList) {
          FileInfo mediaDetails = FileInfo.fromJson(info);
          fileList.add(mediaDetails);
        }
        int index = sp.getInt(PlaybackCoordinator.lastPlayIndexCacheKey) ?? 0;
        int playModeIndex =
            sp.getInt(PlaybackCoordinator.lastPlayModeCacheKey) ?? 0;
        PlayerPlayMode playMode = PlayerPlayMode.values[playModeIndex];
        PlayerPlayback.instance.playModeInfo.value = PlayerPlayModeInfo(
          mode: playMode,
        );
        PlayerPlayback.instance.insertPlayList(
          fileList,
          isAuto: true,
          playIndex: index,
          startPlay: false,
        );
      }
    } else if (recommendList.value.isNotEmpty) {
      PlayerPlayback.instance.insertPlayList(
        recommendList.value,
        isAuto: true,
        playIndex: 0,
        startPlay: false,
      );
    }
  }

  Future refreshResource({String? source = 'drop_down'}) async {
    if (isRefreshing) {
      return;
    }
    return await _queryResource(source: source);
  }

  //请求更多分页的参数
  String? _continuation;
  Future loadMoreResource() async {
    if (isYoutubeMusicEnable.value == false) {
      return IndicatorResult.noMore;
    }
    return await _queryResource(continuation: _continuation);
  }

  bool isRefreshing = false;
  Future _queryResource({String? continuation, String? source}) async {
    isRefreshing = true;
    Map<String, dynamic>? params = {'browseId': 'FEmusic_home'};
    //source是自定义埋点字段，和接口无关
    params['_source'] = source;
    Map<String, dynamic>? query;
    if (continuation != null) {
      query = {'continuation': continuation};
    }
    dynamic result = await MusicCatalogGateway.post(
      url: MusicCatalogEndpoints.home,
      prams: params,
      query: query,
    );
    //更新全局的visitorData
    if ((await MusicCatalogGateway.visitorData) == null) {
      final visitorData = ParserHelper.parse<String>(
        result,
        SharedParserKeys.visitorData,
      );
      if (visitorData != null) {
        MusicCatalogGateway.visitorData = visitorData;
      }
    }

    List? itemSections = ParserHelper.parse<List>(
      result,
      SectionListParserKeys.itemSectionRenderer,
    );

    String? newContinuation;
    if (continuation == null) {
      _originalResourceList.clear();
      resourceFileGroupList.value.clear();
      //将下一页的分页请求参数保存下来
      newContinuation = ParserHelper.parse<String>(
        result,
        SectionListParserKeys.initContinuation,
      );
      _continuation = newContinuation;
      result = ParserHelper.parse<List>(
        result,
        SectionListParserKeys.initResourceList,
      );
      if (result == null || (itemSections is List && itemSections.isEmpty)) {
        if (result != null) {
          MessageOverlay.showSuccess('Updated content.'.translate);
        } else {
          MessageOverlay.showWarning(
            'Network issue. Please try again later.'.translate,
          );
        }
      }
    } else {
      newContinuation = ParserHelper.parse<String>(
        result,
        SectionListParserKeys.moreContinuation,
      );
      if (newContinuation != null) {
        _continuation = newContinuation;
      }
      result = ParserHelper.parse<List>(
        result,
        SectionListParserKeys.moreResourceList,
      );
    }

    if (itemSections is List && itemSections.isNotEmpty) {
      await _queryYTResource(source: source);
      return;
    }
    isRefreshing = false;
    isYoutubeMusicEnable.value = true;
    result ??= [];
    _originalResourceList.addAll(result);
    List<MediaCollection> list = await SharedParser.parseContents(
      result,
      source: MediaOrigin.homeNet,
    );
    resourceFileGroupList.value.addAll(list);
    resourceFileGroupList.notifyListeners();
    _cacheResourceData();
    if (newContinuation == null) {
      return IndicatorResult.noMore;
    }
  }

  Future _queryYTResource({String? source}) async {
    isYoutubeMusicEnable.value = false;

    Map<String, dynamic>? params = {'browseId': 'UC-9-kyTW8ZkZNDHQJ6FgpwQ'};
    //source是自定义埋点字段，和接口无关
    params['_source'] = source;
    dynamic result = await MusicCatalogGateway.post(
      url: MusicCatalogEndpoints.ytHome,
      prams: params,
      isMusic: false,
    );
    isRefreshing = false;
    //更新全局的visitorData
    if ((await MusicCatalogGateway.visitorData) == null) {
      final visitorData = ParserHelper.parse<String>(
        result,
        SharedParserKeys.visitorData,
      );
      if (visitorData != null) {
        MusicCatalogGateway.visitorData = visitorData;
      }
    }
    if (result != null) {
      MessageOverlay.showSuccess('Updated content.'.translate);
    } else {
      MessageOverlay.showWarning(
        'Network issue. Please try again later.'.translate,
      );
    }
    result =
        ParserHelper.parse<List>(
          result,
          DiscoveryCatalogParserKeys.resourceList,
        ) ??
        [];

    _originalResourceList = result;
    List<MediaCollection> list = await MusicCatalogParser.parseHomeContents(
      result,
      source: MediaOrigin.homeNet,
    );
    resourceFileGroupList.value = list;
    resourceFileGroupList.notifyListeners();
    _cacheResourceData();
    return IndicatorResult.noMore;
  }
}
