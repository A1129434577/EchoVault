import 'dart:convert';
import 'dart:io';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:player_base/utils/debounce_util.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/alerts/create_playlist_alert.dart';
import 'package:echo_vault/controllers/download_file_controller.dart';
import 'package:echo_vault/controllers/favorite_artist_controller.dart';
import 'package:echo_vault/controllers/favorite_file_controller.dart';
import 'package:echo_vault/datebase/artist_data_operate.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/datebase/file_info_data_operate.dart';
import 'package:echo_vault/enums/file_source.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/utils/string_cipher.dart';
import 'package:echo_vault/models/artist_info.dart';
import 'package:echo_vault/modules/library/controllers/library_controller.dart';
import 'package:echo_vault/modules/player/controllers/play_controller.dart';
import 'package:echo_vault/network/ytm_network.dart';
import 'package:echo_vault/parse/common_parse.dart';
import 'package:echo_vault/parse/common_yt_parse.dart';
import 'package:echo_vault/parse/parse_util.dart';
import 'package:echo_vault/utils/toast_util.dart';

class HomeController with ChangeNotifier{
  static final HomeController _instance = HomeController._();
  static HomeController get instance => _instance;
  factory HomeController() {
    return _instance;
  }
  HomeController._(){
    PlayerPlayback.instance.player.playStatusStream.listen((playState){
      FileInfo? fileInfo = playState.fileInfo;
      if(playState.isAuto==false) {
        if(playState.state == PlayState.start ||
            playState.state == PlayState.playIndex){
          if(fileInfo != null) {
            fileInfo.source1 = FileSource.history;
            FileInfoDataOperate.insertFileInfo(fileInfo);
            queryRecommend();
          }
        }
      }
    });
    DownloadFileController.downloadFinishAndRemoveStream.listen((fileInfo){
      queryRecommend();
      queryMyPlaylist();
    });
    FavoriteFileController.favoriteStream.listen((fileInfo){
      queryRecommend();
      queryMyPlaylist();
    });
    //首页展示的是非空的播放列表，在歌曲被添加自某个播放列表之后首页数据会更新，
    //不仅仅是搜藏歌单，所以直接监听LibraryController.instance.fileGroupList
    LibraryController.instance.fileGroupList.addListener((){
      queryMyPlaylist();
    });
    FavoriteArtistController.favoriteStream.listen((fileInfo){
      queryMyArtist();
    });
  }

  ValueNotifier<bool> isYoutubeMusicEnable = ValueNotifier(true);

  EasyRefreshController refreshController = EasyRefreshController();

  DebouncedValueNotifier<List<FileInfo>> recommendList = DebouncedValueNotifier([]);
  ValueNotifier<List<FileGroup>> playlistList = ValueNotifier([]);
  ValueNotifier<List<ArtistInfo>> artistList = ValueNotifier([]);
  ValueNotifier<List<FileGroup>> topChartsList = ValueNotifier([]);
  ValueNotifier<List<FileGroup>> resourceFileGroupList = ValueNotifier([]);

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
    List<FileInfo> list = await FileInfoDataOperate.queryFileInfo(where: '''
    (json_content LIKE '%${'"source1":"${FileSource.history.name}"'}%')
    OR (json_content LIKE '%${'"source":"${FileSource.homeReco.name}"'}%')
    OR (download_status = 3)
    OR (is_favorite = 1)
    ''');
    for(final fileInfo in list){
      fileInfo.source = FileSource.homeReco;
    }
    if(list.isNotEmpty){
      recommendList.value = list;
    }
    return list;
  }

  Future<List<FileGroup>> queryMyPlaylist() async {
    List<FileGroup> fileGroupList = [];
    List<FileInfo> likedList = await LibraryController.instance.queryLikedList();
    if(likedList.isNotEmpty){
      fileGroupList.add(FileGroup(
        name: 'Like songs'.translate,
        thumbnail: Assets.images.collection.listFavorite.path,
        children: likedList,
      ));
    }
    List<FileInfo> savedList = await LibraryController.instance.querySavedList();
    if(savedList.isNotEmpty){
      fileGroupList.add(FileGroup(
        name: 'Local songs'.translate,
        thumbnail: Assets.images.collection.listSaved.path,
        children: savedList,
      ));
    }
    List<FileGroup> groupList = LibraryController.instance.fileGroupList.value;
    List<FileGroup> newGroupList = [];
    for(final group in groupList){
      if(group.id?.startsWith(CreatePlaylistAlert.createPlaylistNamePrefix)==true){
        if(group.children.isNotEmpty){
          newGroupList.add(group);
        }
      }else{
        newGroupList.add(group);
      }
    }
    fileGroupList.addAll(newGroupList);
    playlistList.value = fileGroupList;
    return fileGroupList;
  }

  Future<List<ArtistInfo>> queryMyArtist() async {
    List<ArtistInfo> list = await ArtistDataOperate.queryArtistInfo();
    if(list.isEmpty){
      final encryptedJson = await rootBundle.loadString(Assets.data.artSeed);
      String artisJsonString = StringCipher.decrypt(encryptedJson);
      List artisMapList = jsonDecode(artisJsonString);
      for (final artistMap in artisMapList) {
        ArtistInfo artistInfo = ArtistInfo.fromJson(artistMap);
        await ArtistDataOperate.insertArtistInfo(artistInfo);
        list.add(artistInfo);
      }
    }
    artistList.value = list;
    return list;
  }

  Future<List<FileGroup>> queryTopCharts() async {
    List<FileGroup> fileGroupList = [];
    final encryptedJson = await rootBundle.loadString(Assets.data.topSeed);
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
    for(final map in jsonList) {
      FileGroup fileGroup = FileGroup.fromJson(map);
      fileGroup.thumbnail = Assets.images.media.albumPlaceholder.path;
      fileGroup.playlistType = PlaylistType.LOCKUP_CONTENT_TYPE_PLAYLIST.name;
      fileGroupList.add(fileGroup);
    }
    topChartsList.value = fileGroupList;
    return fileGroupList;
  }

  Future _getCacheResourceData() async {
    String cachePath = '${await FileInfo.filesCacheDirectoryPath}${Platform.pathSeparator}home_cache_data';
    File file = File(cachePath);
    if(file.existsSync()) {
      String jsonString = await file.readAsString();
      List l = [];
      try{
        l = jsonDecode(jsonString);
      }catch(_){}
      if(l.isEmpty){
        file.deleteSync();
        return;
      }
      _originalResourceList = l;
      List<FileGroup> list = await CommonParse.parseContents(_originalResourceList);
      if(list.isEmpty){
        isYoutubeMusicEnable.value = false;
        list = await CommonYtParse.parseHomeContents(_originalResourceList);
      }
      resourceFileGroupList.value.addAll(list);
      resourceFileGroupList.notifyListeners();
    }
  }

  Future _cacheResourceData() async {
    String cachePath = '${await FileInfo.filesCacheDirectoryPath}${Platform.pathSeparator}home_cache_data';
    File file = File(cachePath);
    await file.writeAsString(jsonEncode(_originalResourceList));
  }


  //恢复之前的播放
  Future _resumePlayback() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? jsonString = sp.getString(PlayController.lastPlayingListCacheKey);
    if(jsonString != null){
      final fileMapList = jsonDecode(jsonString);
      if(fileMapList.isNotEmpty){
        List<FileInfo> fileList = [];
        for(final info in fileMapList){
          FileInfo fileInfo = FileInfo.fromJson(info);
          fileList.add(fileInfo);
        }
        int index = sp.getInt(PlayController.lastPlayIndexCacheKey)??0;
        int playModeIndex = sp.getInt(PlayController.lastPlayModeCacheKey)??0;
        PlayerPlayMode playMode = PlayerPlayMode.values[playModeIndex];
        PlayerPlayback.instance.playModeInfo.value = PlayerPlayModeInfo(mode: playMode);
        PlayerPlayback.instance.insertPlayList(fileList, isAuto: true, playIndex: index, startPlay: false);
      }
    }
    else if(recommendList.value.isNotEmpty){
      PlayerPlayback.instance.insertPlayList(recommendList.value, isAuto: true, playIndex: 0, startPlay: false);
    }
  }

  Future refreshResource({String? source = 'drop_down'}) async {
    if(isRefreshing){
      return;
    }
    return await _queryResource(source: source);
  }

  //请求更多分页的参数
  String? _continuation;
  Future loadMoreResource() async {
    if(isYoutubeMusicEnable.value==false){
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
    dynamic result = await YTMNetwork.post(
      url: YTMApis.home,
      prams: params,
      query: query,
    );
    //更新全局的visitorData
    if((await YTMNetwork.visitorData) == null) {
      final visitorData = ParseUtil.parse<String>(result, CommonParseKeys.visitorData);
      if (visitorData != null) {
        YTMNetwork.visitorData = visitorData;
      }
    }

    List? itemSections = ParseUtil.parse<List>(result, SectionListParseKeys.itemSectionRenderer);

    String? newContinuation;
    if(continuation == null){
      _originalResourceList.clear();
      resourceFileGroupList.value.clear();
      //将下一页的分页请求参数保存下来
      newContinuation = ParseUtil.parse<String>(result, SectionListParseKeys.initContinuation);
      _continuation = newContinuation;
      result = ParseUtil.parse<List>(result, SectionListParseKeys.initResourceList);
      if(result == null || (itemSections is List && itemSections.isEmpty)){
        if(result!=null) {
          ToastUtil.showSuccess('Updated content.'.translate);
        }else{
          ToastUtil.showWarning('Network issue. Please try again later.'.translate);
        }      }
    }else{
      newContinuation = ParseUtil.parse<String>(result, SectionListParseKeys.moreContinuation);
      if (newContinuation != null) {
        _continuation = newContinuation;
      }
      result = ParseUtil.parse<List>(result, SectionListParseKeys.moreResourceList);
    }

    if(itemSections is List && itemSections.isNotEmpty){
      await _queryYTResource(source: source);
      return;
    }
    isRefreshing = false;
    isYoutubeMusicEnable.value = true;
    result ??= [];
    _originalResourceList.addAll(result);
    List<FileGroup> list = await CommonParse.parseContents(result, source: FileSource.homeNet);
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
    dynamic result = await YTMNetwork.post(
      url: YTMApis.ytHome,
      prams: params,
      isMusic: false,
    );
    isRefreshing = false;
    //更新全局的visitorData
    if((await YTMNetwork.visitorData)==null) {
      final visitorData = ParseUtil.parse<String>(result, CommonParseKeys.visitorData);
      if (visitorData != null) {
        YTMNetwork.visitorData = visitorData;
      }
    }
    if(result!=null) {
      ToastUtil.showSuccess('Updated content.'.translate);
    }else{
      ToastUtil.showWarning('Network issue. Please try again later.'.translate);
    }
    result = ParseUtil.parse<List>(result, HomeYTParseKeys.resourceList)??[];

    _originalResourceList = result;
    List<FileGroup> list = await CommonYtParse.parseHomeContents(result, source: FileSource.homeNet);
    resourceFileGroupList.value = list;
    resourceFileGroupList.notifyListeners();
    _cacheResourceData();
    return IndicatorResult.noMore;
  }
}
