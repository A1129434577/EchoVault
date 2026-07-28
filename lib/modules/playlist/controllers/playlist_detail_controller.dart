import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/enums/file_source.dart';
import 'package:echo_vault/network/ytm_network.dart';
import 'package:echo_vault/parse/common_parse.dart';
import 'package:echo_vault/parse/common_yt_parse.dart';
import 'package:echo_vault/parse/parse_util.dart';
import 'package:echo_vault/widgets/base_status_widget.dart';

class PlaylistDetailController with ChangeNotifier {
  final FileGroup fileGroup;
  PlaylistDetailController({
    required this.fileGroup,
  });
  ValueNotifier<ResourceStatus> state = ValueNotifier(ResourceStatus.idl);
  EasyRefreshController refreshController = EasyRefreshController();
  ValueNotifier<List<FileGroup>?> resourceList = ValueNotifier(null);

  Future queryData() async {
    state.value = ResourceStatus.loading;
    //youtube的WEB_PAGE_TYPE_PLAYLIST类型（最佳搜索的顶部card）也需要用browse接口请求
    if(fileGroup.playlistType == PlaylistType.MUSIC_PAGE_TYPE_ALBUM.name ||
        fileGroup.playlistType == PlaylistType.MUSIC_PAGE_TYPE_PLAYLIST.name ||
        fileGroup.playlistType == PlaylistType.WEB_PAGE_TYPE_PLAYLIST.name ||
        fileGroup.playlistType == PlaylistType.MUSIC_PAGE_TYPE_PODCAST_SHOW_DETAIL_PAGE.name) {
      await _queryData();
    }else{
      fileGroup.children = [];
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
    Map<String, dynamic>? params = {'browseId': fileGroup.id!, 'params':fileGroup.params};
    dynamic result = await YTMNetwork.post(
      url: YTMApis.playlistDetail,
      prams: params,
    );
    if(result == null){
      return;
    }
    dynamic list = ParseUtil.parse<List>(result, SectionListParseKeys.tapMoreResourceList);
    //也有可能是其他格式，所以再容错一下
    list ??= ParseUtil.parse<List>(result, SectionListParseKeys.initResourceList)??[];
    //playlist和album的详情页面都是同一个，
    //但是专辑有点不同的是可能还有推荐作品，所以统一再次规定格式为一个FilGroup分组
    list = await CommonParse.parseContents(list, source: FileSource.playlistHome);
    if(list is List<FileGroup>){
      fileGroup.children = list.where((e)=>e.type==FileGroupShowType.listMusic || e.type==FileGroupShowType.responsiveListMusic).firstOrNull?.children??[];
    }
    resourceList.value = list;
  }

  //请求更多显示根据
  Future _queryYTData({Map<String, dynamic>? moreParams}) async {
    Map<String, dynamic>? params = {'playlistId': fileGroup.id!};
    if(moreParams!=null){
      params.addAll(moreParams);
    }
    dynamic result = await YTMNetwork.post(
      url: YTMApis.ytPlaylistDetail,
      prams: params,
      isMusic: false,
    );
    if(result == null){
      return;
    }
    result = ParseUtil.parse<List>(result, PlaylistYTParseKeys.resourceList)??[];
    List newChildren = await CommonYtParse.parsePlaylistChildren(result);
    fileGroup.children = [...fileGroup.children, ...newChildren.cast<FileInfo>()];
    resourceList.value = [fileGroup];
  }

  Future loadMoreYTData() async {
    FileInfo fileInfo = fileGroup.children.first;
    await _queryYTData(moreParams:{'videoId':fileInfo.fileId, 'playlistIndex':1});
    return IndicatorResult.noMore;
  }

}
