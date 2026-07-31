import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/media/media_origin.dart';
import 'package:echo_vault/core/networking/music_catalog_gateway.dart';
import 'package:echo_vault/core/parsing/shared_parser.dart';
import 'package:echo_vault/core/parsing/music_catalog_parser.dart';
import 'package:echo_vault/core/parsing/parser_helper.dart';
import 'package:echo_vault/shared/widgets/resource_state_view.dart';

class CollectionDetailState with ChangeNotifier {
  final MediaCollection mediaCollection;
  CollectionDetailState({required this.mediaCollection});
  ValueNotifier<ResourceStatus> state = ValueNotifier(ResourceStatus.idl);
  EasyRefreshController refreshController = EasyRefreshController();
  ValueNotifier<List<MediaCollection>?> resourceList = ValueNotifier(null);

  Future queryData() async {
    state.value = ResourceStatus.loading;
    //youtube的WEB_PAGE_TYPE_PLAYLIST类型（最佳搜索的顶部card）也需要用browse接口请求
    if (mediaCollection.playlistType ==
            CollectionType.MUSIC_PAGE_TYPE_ALBUM.name ||
        mediaCollection.playlistType ==
            CollectionType.MUSIC_PAGE_TYPE_PLAYLIST.name ||
        mediaCollection.playlistType ==
            CollectionType.WEB_PAGE_TYPE_PLAYLIST.name ||
        mediaCollection.playlistType ==
            CollectionType.MUSIC_PAGE_TYPE_PODCAST_SHOW_DETAIL_PAGE.name) {
      await _queryData();
    } else {
      mediaCollection.children = [];
      await _queryYTData();
    }
    if (resourceList.value?.isEmpty == true) {
      state.value = ResourceStatus.empty;
    } else if (resourceList.value?.isNotEmpty == true) {
      state.value = ResourceStatus.source;
    } else {
      state.value = ResourceStatus.error;
    }
  }

  Future _queryData() async {
    Map<String, dynamic>? params = {
      'browseId': mediaCollection.id!,
      'params': mediaCollection.params,
    };
    dynamic result = await MusicCatalogGateway.post(
      url: MusicCatalogEndpoints.playlistDetail,
      prams: params,
    );
    if (result == null) {
      return;
    }
    dynamic list = ParserHelper.parse<List>(
      result,
      SectionListParserKeys.tapMoreResourceList,
    );
    //也有可能是其他格式，所以再容错一下
    list ??=
        ParserHelper.parse<List>(
          result,
          SectionListParserKeys.initResourceList,
        ) ??
        [];
    //playlist和album的详情页面都是同一个，
    //但是专辑有点不同的是可能还有推荐作品，所以统一再次规定格式为一个FilGroup分组
    list = await SharedParser.parseContents(
      list,
      source: MediaOrigin.playlistHome,
    );
    if (list is List<MediaCollection>) {
      mediaCollection.children =
          list
              .where(
                (e) =>
                    e.type == MediaCollectionShowType.listMusic ||
                    e.type == MediaCollectionShowType.responsiveListMusic,
              )
              .firstOrNull
              ?.children ??
          [];
    }
    resourceList.value = list;
  }

  //请求更多显示根据
  Future _queryYTData({Map<String, dynamic>? moreParams}) async {
    Map<String, dynamic>? params = {'playlistId': mediaCollection.id!};
    if (moreParams != null) {
      params.addAll(moreParams);
    }
    dynamic result = await MusicCatalogGateway.post(
      url: MusicCatalogEndpoints.ytPlaylistDetail,
      prams: params,
      isMusic: false,
    );
    if (result == null) {
      return;
    }
    result =
        ParserHelper.parse<List>(
          result,
          CollectionCatalogParserKeys.resourceList,
        ) ??
        [];
    List newChildren = await MusicCatalogParser.parsePlaylistChildren(result);
    mediaCollection.children = [
      ...mediaCollection.children,
      ...newChildren.cast<FileInfo>(),
    ];
    resourceList.value = [mediaCollection];
  }

  Future loadMoreYTData() async {
    FileInfo mediaDetails = mediaCollection.children.first;
    await _queryYTData(
      moreParams: {'videoId': mediaDetails.fileId, 'playlistIndex': 1},
    );
    return IndicatorResult.noMore;
  }
}
