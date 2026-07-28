
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/enums/file_source.dart';
import 'package:echo_vault/models/artist_info.dart';
import 'package:echo_vault/modules/home/controllers/home_controller.dart';
import 'package:echo_vault/network/ytm_network.dart';
import 'package:echo_vault/parse/common_parse.dart';
import 'package:echo_vault/parse/common_yt_parse.dart';
import 'package:echo_vault/parse/parse_util.dart';
import 'package:echo_vault/widgets/base_status_widget.dart';

class ArtistDetailController with ChangeNotifier {
  final ArtistInfo artistInfo;
  ArtistDetailController({
    required this.artistInfo,
  });
  ValueNotifier<ResourceStatus> state = ValueNotifier(ResourceStatus.idl);
  EasyRefreshController refreshController = EasyRefreshController();
  late ValueNotifier<String> hdThumbnail = ValueNotifier(artistInfo.thumbnail);
  ValueNotifier<List<FileGroup>?> resourceList = ValueNotifier(null);


  Future queryData() async {
    state.value = ResourceStatus.loading;
    if(HomeController.instance.isYoutubeMusicEnable.value){
      await _queryData();
    }else{
      await _queryYTData();
    }
    if(resourceList.value?.isEmpty==true){
      state.value = ResourceStatus.empty;
    }
    else if(resourceList.value?.isNotEmpty==true){
      state.value = ResourceStatus.source;
    }
    else {
      state.value = ResourceStatus.error;
    }
  }

  Future _queryData() async {
    Map<String, dynamic>? params = {'browseId': artistInfo.id};
    dynamic result = await YTMNetwork.post(
      url: YTMApis.artistDetail,
      prams: params,
    );
    if(result == null){
      return;
    }
    hdThumbnail.value = ParseUtil.parse<String>(result, ArtistParseKeys.cover)??ParseUtil.parse<String>(result, ArtistParseKeys.coverBackup)??'';
    result = ParseUtil.parse<List>(result, SectionListParseKeys.initResourceList)??[];
    final newResult = await CommonParse.parseContents(result, source: FileSource.artistHome);
    resourceList.value = newResult;
  }

  Future _queryYTData() async {
    String? browseId = artistInfo.ytId??artistInfo.id;
    Map<String, dynamic>? params = {'browseId': browseId};
    dynamic result = await YTMNetwork.post(
      url: YTMApis.ytArtistDetail,
      prams: params,
      isMusic: false
    );
    if(result == null){
      return;
    }
    hdThumbnail.value = ParseUtil.parse<String>(result, ArtistYTParseKeys.cover)??'';
    if(hdThumbnail.value.isNotEmpty) {
      artistInfo.thumbnail = hdThumbnail.value;
    }
    List resultList = ParseUtil.parse<List>(result, ArtistYTParseKeys.tabs)??[];
    List<FileGroup> list = [];
    for(final tab in resultList){
      String? url = ParseUtil.parse<String>(tab, ArtistYTParseKeys.tabUrl);
      String title = ParseUtil.parse<String>(tab, ArtistYTParseKeys.tabTitle)??'';
      if(url?.contains(ArtistYTParseKeys.videos)==true){
        String? browseParams = ParseUtil.parse<String>(tab, ArtistYTParseKeys.params);
        Map params = {'browseId': browseId, 'params': browseParams};
        dynamic tabResult = await YTMNetwork.post(
            url: YTMApis.ytArtistDetail,
            prams: params,
            isMusic: false
        );
        List tabResultList = ParseUtil.parse<List>(tabResult, ArtistYTParseKeys.tabs)??[];
        for (final tab in tabResultList) {
          String? url = ParseUtil.parse<String>(tab, ArtistYTParseKeys.tabUrl);
          if(url?.contains(ArtistYTParseKeys.videos)==true){
            FileGroup fileGroup = FileGroup(name: title);
            fileGroup.type = FileGroupShowType.listMusic;
            final items = ParseUtil.parse<List>(tab, ArtistYTParseKeys.richItems)??[];
            List children = await CommonYtParse.parseArtistChildren(items);
            fileGroup.children = children;
            list.add(fileGroup);
            break;
          }
        }
      }
      else if(url?.contains(ArtistYTParseKeys.releases)==true){
        String? browseParams = ParseUtil.parse<String>(tab, ArtistYTParseKeys.params);
        Map params = {'browseId': browseId, 'params': browseParams};
        dynamic tabResult = await YTMNetwork.post(
            url: YTMApis.ytArtistDetail,
            prams: params,
            isMusic: false
        );
        List tabResultList = ParseUtil.parse<List>(tabResult, ArtistYTParseKeys.tabs)??[];
        for (final tab in tabResultList) {
          String? url = ParseUtil.parse<String>(tab, ArtistYTParseKeys.tabUrl);
          if(url?.contains(ArtistYTParseKeys.releases)==true){
            FileGroup fileGroup = FileGroup(name: title);
            fileGroup.type = FileGroupShowType.twoRowPlaylist;
            List items = ParseUtil.parse<List>(tab, ArtistYTParseKeys.richItems)??[];
            List children = await CommonYtParse.parseArtistChildren(items);
            if(children.isNotEmpty) {
              fileGroup.children = children;
              list.add(fileGroup);
            }
            break;
          }
        }
      }
      else if(url?.contains(ArtistYTParseKeys.playlists)==true){
        String? browseParams = ParseUtil.parse<String>(tab, ArtistYTParseKeys.params);
        Map params = {'browseId': browseId, 'params': browseParams};
        dynamic tabResult = await YTMNetwork.post(
            url: YTMApis.ytArtistDetail,
            prams: params,
            isMusic: false
        );
        List tabResultList = ParseUtil.parse<List>(tabResult, ArtistYTParseKeys.tabs)??[];
        for (final tab in tabResultList) {
          String? url = ParseUtil.parse<String>(tab, ArtistYTParseKeys.tabUrl);
          if(url?.contains(ArtistYTParseKeys.playlists)==true){
            FileGroup fileGroup = FileGroup(name: title);
            fileGroup.type = FileGroupShowType.twoRowPlaylist;
            List items = ParseUtil.parse<List>(tab, ArtistYTParseKeys.lockupViewModelPlaylistItems)??[];
            List children = await CommonYtParse.parseArtistChildren(items);
            if(children.isNotEmpty) {
              fileGroup.children = children;
              list.add(fileGroup);
            }
            break;
          }
        }
      }
    }
    resourceList.value = list;
  }
}

class ArtistParseKeys {
  ///歌手封面大图
  static List cover = [
    'header',
    'musicImmersiveHeaderRenderer',
    'thumbnail',
    'musicThumbnailRenderer',
    'thumbnail',
    'thumbnails',
    {
      ParseUtil.indexKey: 2,
    },
    'url',
  ];

  static List coverBackup = [
    'header',
    'musicVisualHeaderRenderer',
    'thumbnail',
    'musicThumbnailRenderer',
    'thumbnail',
    'thumbnails',
    {
      ParseUtil.indexKey: 2,
    },
    'url',
  ];
}