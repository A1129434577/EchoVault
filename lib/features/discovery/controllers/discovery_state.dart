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

  //请求更多分页的参数
  String? _continuation;

  bool isRefreshing = false;
  factory DiscoveryState() {
    return _instance;
  }
  DiscoveryState._() {
    PlayerPlayback.instance.player.playStatusStream.listen((playStateInputArg) {
      FileInfo? mediaEntry = playStateInputArg.fileInfo;
      if (playStateInputArg.isAuto == false) {
        if (playStateInputArg.state == PlayState.start ||
            playStateInputArg.state == PlayState.playIndex) {
          if (mediaEntry != null) {
            mediaEntry.source1 = MediaOrigin.history;
            MediaRepository.insertFileInfo(mediaEntry);
            queryRecommend();
          }
        }
      }
    });
    TransferMediaState.downloadFinishAndRemoveStream.listen((mediaEntry) {
      queryRecommend();
      queryMyPlaylist();
    });
    BookmarkMediaState.favoriteStream.listen((mediaEntry) {
      queryRecommend();
      queryMyPlaylist();
    });
    //首页展示的是非空的播放列表，在歌曲被添加自某个播放列表之后首页数据会更新，
    //不仅仅是搜藏歌单，所以直接监听LibraryController.instance.mediaCollections
    CatalogState.instance.mediaCollections.addListener(() {
      queryMyPlaylist();
    });
    BookmarkPerformerState.favoriteStream.listen((mediaEntry) {
      queryMyArtist();
    });
  }
  static DiscoveryState get instance => _instance;
  Future loadMoreResource() async {
    if (isYoutubeMusicEnable.value == false) {
      return IndicatorResult.noMore;
    }
    return await _queryResource(continuationArg: _continuation);
  }

  Future queryAllLocalData() async {
    await queryRecommend();
    await queryMyPlaylist();
    await queryMyArtist();
    await queryTopCharts();
    await _getCacheResourceData();
    await _resumePlayback();
  }

  Future<List<PerformerDetails>> queryMyArtist() async {
    List<PerformerDetails> entries =
        await PerformerRepository.queryArtistInfo();
    if (entries.isEmpty) {
      final encryptedJsonLocal = await rootBundle.loadString(
        Assets.data.artSeed,
      );
      String artisJsonStringLocal = StringCipher.decrypt(encryptedJsonLocal);
      List artisMapListLocal = jsonDecode(artisJsonStringLocal);
      for (final artistMap in artisMapListLocal) {
        PerformerDetails performerProfile = PerformerDetails.fromJson(
          artistMap,
        );
        await PerformerRepository.insertArtistInfo(performerProfile);
        entries.add(performerProfile);
      }
    }
    performers.value = entries;
    return entries;
  }

  Future<List<MediaCollection>> queryMyPlaylist() async {
    List<MediaCollection> collections = [];
    List<FileInfo> likedListLocal = await CatalogState.instance
        .queryLikedList();
    if (likedListLocal.isNotEmpty) {
      collections.add(
        MediaCollection(
          name: 'Like songs'.translate,
          thumbnail: Assets.images.collection.listFavorite.path,
          children: likedListLocal,
        ),
      );
    }
    List<FileInfo> savedListLocal = await CatalogState.instance
        .querySavedList();
    if (savedListLocal.isNotEmpty) {
      collections.add(
        MediaCollection(
          name: 'Local songs'.translate,
          thumbnail: Assets.images.collection.listSaved.path,
          children: savedListLocal,
        ),
      );
    }
    List<MediaCollection> groupListLocal =
        CatalogState.instance.mediaCollections.value;
    List<MediaCollection> newGroupListLocal = [];
    for (final group in groupListLocal) {
      if (group.id?.startsWith(NewCollectionDialog.createPlaylistNamePrefix) ==
          true) {
        if (group.children.isNotEmpty) {
          newGroupListLocal.add(group);
        }
      } else {
        newGroupListLocal.add(group);
      }
    }
    collections.addAll(newGroupListLocal);
    playlistList.value = collections;
    return collections;
  }

  Future<List<FileInfo>> queryRecommend() async {
    List<FileInfo> entries = await MediaRepository.queryFileInfo(
      whereArg:
          '''
    (json_content LIKE '%${'"source1":"${MediaOrigin.history.name}"'}%')
    OR (json_content LIKE '%${'"source":"${MediaOrigin.homeReco.name}"'}%')
    OR (download_status = 3)
    OR (is_favorite = 1)
    ''',
    );
    for (final mediaDetails in entries) {
      mediaDetails.source = MediaOrigin.homeReco;
    }
    if (entries.isNotEmpty) {
      recommendList.value = entries;
    }
    return entries;
  }

  Future<List<MediaCollection>> queryTopCharts() async {
    List<MediaCollection> collections = [];
    final encryptedJsonLocal = await rootBundle.loadString(Assets.data.topSeed);
    String serializedJson = StringCipher.decrypt(encryptedJsonLocal);
    Map payload = jsonDecode(serializedJson);
    Locale sysLocaleLocal = WidgetsBinding.instance.platformDispatcher.locale;
    String countryCodeLocal = sysLocaleLocal.countryCode?.toLowerCase() ?? "us";
    List jsonListLocal = payload['us'];
    if (countryCodeLocal.contains('br')) {
      jsonListLocal = payload['br'];
    } else if (countryCodeLocal.contains('mx')) {
      jsonListLocal = payload['mx'];
    }
    for (final map in jsonListLocal) {
      MediaCollection mediaCollectionLocal = MediaCollection.fromJson(map);
      mediaCollectionLocal.thumbnail =
          Assets.images.media.albumPlaceholder.path;
      mediaCollectionLocal.playlistType =
          CollectionType.LOCKUP_CONTENT_TYPE_PLAYLIST.name;
      collections.add(mediaCollectionLocal);
    }
    topChartsList.value = collections;
    return collections;
  }

  Future refreshResource({String? mediaOrigin = 'drop_down'}) async {
    if (isRefreshing) {
      return;
    }
    return await _queryResource(mediaOrigin: mediaOrigin);
  }

  Future _cacheResourceData() async {
    String cachedMediaPath =
        '${await FileInfo.filesCacheDirectoryPath}${Platform.pathSeparator}home_cache_data';
    File fileLocal = File(cachedMediaPath);
    await fileLocal.writeAsString(jsonEncode(_originalResourceList));
  }

  Future _getCacheResourceData() async {
    String cachedMediaPath =
        '${await FileInfo.filesCacheDirectoryPath}${Platform.pathSeparator}home_cache_data';
    File fileLocal = File(cachedMediaPath);
    if (fileLocal.existsSync()) {
      String serializedJson = await fileLocal.readAsString();
      List lLocal = [];
      try {
        lLocal = jsonDecode(serializedJson);
      } catch (_) {}
      if (lLocal.isEmpty) {
        fileLocal.deleteSync();
        return;
      }
      _originalResourceList = lLocal;
      List<MediaCollection> entries = await SharedParser.parseContents(
        _originalResourceList,
      );
      if (entries.isEmpty) {
        isYoutubeMusicEnable.value = false;
        entries = await MusicCatalogParser.parseHomeContents(
          _originalResourceList,
        );
      }
      resourceFileGroupList.value.addAll(entries);
      resourceFileGroupList.notifyListeners();
    }
  }

  Future _queryResource({String? continuationArg, String? mediaOrigin}) async {
    isRefreshing = true;
    Map<String, dynamic>? requestParameters = {'browseId': 'FEmusic_home'};
    //source是自定义埋点字段，和接口无关
    requestParameters['_source'] = mediaOrigin;
    Map<String, dynamic>? queryLocal;
    if (continuationArg != null) {
      queryLocal = {'continuation': continuationArg};
    }
    dynamic response = await MusicCatalogGateway.post(
      resourceUrl: MusicCatalogEndpoints.home,
      pramsArg: requestParameters,
      queryArg: queryLocal,
    );
    //更新全局的visitorData
    if ((await MusicCatalogGateway.visitorData) == null) {
      final visitorDataLocal = ParserHelper.parse<String>(
        response,
        SharedParserKeys.visitorData,
      );
      if (visitorDataLocal != null) {
        MusicCatalogGateway.visitorData = visitorDataLocal;
      }
    }

    List? itemSectionsLocal = ParserHelper.parse<List>(
      response,
      SectionListParserKeys.itemSectionRenderer,
    );

    String? newContinuationLocal;
    if (continuationArg == null) {
      _originalResourceList.clear();
      resourceFileGroupList.value.clear();
      //将下一页的分页请求参数保存下来
      newContinuationLocal = ParserHelper.parse<String>(
        response,
        SectionListParserKeys.initContinuation,
      );
      _continuation = newContinuationLocal;
      response = ParserHelper.parse<List>(
        response,
        SectionListParserKeys.initResourceList,
      );
      if (response == null ||
          (itemSectionsLocal is List && itemSectionsLocal.isEmpty)) {
        if (response != null) {
          MessageOverlay.showSuccess('Updated content.'.translate);
        } else {
          MessageOverlay.showWarning(
            'Network issue. Please try again later.'.translate,
          );
        }
      }
    } else {
      newContinuationLocal = ParserHelper.parse<String>(
        response,
        SectionListParserKeys.moreContinuation,
      );
      if (newContinuationLocal != null) {
        _continuation = newContinuationLocal;
      }
      response = ParserHelper.parse<List>(
        response,
        SectionListParserKeys.moreResourceList,
      );
    }

    if (itemSectionsLocal is List && itemSectionsLocal.isNotEmpty) {
      await _queryYTResource(mediaOrigin: mediaOrigin);
      return;
    }
    isRefreshing = false;
    isYoutubeMusicEnable.value = true;
    response ??= [];
    _originalResourceList.addAll(response);
    List<MediaCollection> entries = await SharedParser.parseContents(
      response,
      mediaOrigin: MediaOrigin.homeNet,
    );
    resourceFileGroupList.value.addAll(entries);
    resourceFileGroupList.notifyListeners();
    _cacheResourceData();
    if (newContinuationLocal == null) {
      return IndicatorResult.noMore;
    }
  }

  Future _queryYTResource({String? mediaOrigin}) async {
    isYoutubeMusicEnable.value = false;

    Map<String, dynamic>? requestParameters = {
      'browseId': 'UC-9-kyTW8ZkZNDHQJ6FgpwQ',
    };
    //source是自定义埋点字段，和接口无关
    requestParameters['_source'] = mediaOrigin;
    dynamic response = await MusicCatalogGateway.post(
      resourceUrl: MusicCatalogEndpoints.ytHome,
      pramsArg: requestParameters,
      isMusicArg: false,
    );
    isRefreshing = false;
    //更新全局的visitorData
    if ((await MusicCatalogGateway.visitorData) == null) {
      final visitorDataLocal = ParserHelper.parse<String>(
        response,
        SharedParserKeys.visitorData,
      );
      if (visitorDataLocal != null) {
        MusicCatalogGateway.visitorData = visitorDataLocal;
      }
    }
    if (response != null) {
      MessageOverlay.showSuccess('Updated content.'.translate);
    } else {
      MessageOverlay.showWarning(
        'Network issue. Please try again later.'.translate,
      );
    }
    response =
        ParserHelper.parse<List>(
          response,
          DiscoveryCatalogParserKeys.resourceList,
        ) ??
        [];

    _originalResourceList = response;
    List<MediaCollection> entries = await MusicCatalogParser.parseHomeContents(
      response,
      mediaOrigin: MediaOrigin.homeNet,
    );
    resourceFileGroupList.value = entries;
    resourceFileGroupList.notifyListeners();
    _cacheResourceData();
    return IndicatorResult.noMore;
  }

  //恢复之前的播放
  Future _resumePlayback() async {
    SharedPreferences spLocal = await SharedPreferences.getInstance();
    String? serializedJson = spLocal.getString(
      PlaybackCoordinator.lastPlayingListCacheKey,
    );
    if (serializedJson != null) {
      final fileMapListLocal = jsonDecode(serializedJson);
      if (fileMapListLocal.isNotEmpty) {
        List<FileInfo> mediaQueue = [];
        for (final info in fileMapListLocal) {
          FileInfo mediaEntry = FileInfo.fromJson(info);
          mediaQueue.add(mediaEntry);
        }
        int itemIndex =
            spLocal.getInt(PlaybackCoordinator.lastPlayIndexCacheKey) ?? 0;
        int playModeIndexLocal =
            spLocal.getInt(PlaybackCoordinator.lastPlayModeCacheKey) ?? 0;
        PlayerPlayMode playModeLocal =
            PlayerPlayMode.values[playModeIndexLocal];
        PlayerPlayback.instance.playModeInfo.value = PlayerPlayModeInfo(
          mode: playModeLocal,
        );
        PlayerPlayback.instance.insertPlayList(
          mediaQueue,
          isAuto: true,
          playIndex: itemIndex,
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
}
