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
  ValueNotifier<ResourceStatus> state = ValueNotifier(ResourceStatus.idl);
  EasyRefreshController refreshController = EasyRefreshController();
  ValueNotifier<List<MediaCollection>?> resourceList = ValueNotifier(null);
  CollectionDetailState({required this.mediaCollection});

  Future fetchMoreYTData() async {
    FileInfo mediaEntry = mediaCollection.children.first;
    await _fetchYTData(
      moreParamsInputArg: {'videoId': mediaEntry.fileId, 'playlistIndex': 1},
    );
    return IndicatorResult.noMore;
  }

  Future fetchData() async {
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
      await _fetchData();
    } else {
      mediaCollection.children = [];
      await _fetchYTData();
    }
    if (resourceList.value?.isEmpty == true) {
      state.value = ResourceStatus.empty;
    } else if (resourceList.value?.isNotEmpty == true) {
      state.value = ResourceStatus.source;
    } else {
      state.value = ResourceStatus.error;
    }
  }

  Future _fetchData() async {
    Map<String, dynamic>? requestParameters = {
      'browseId': mediaCollection.id!,
      'params': mediaCollection.params,
    };
    dynamic response = await MusicCatalogGateway.post(
      resourceUrl: MusicCatalogEndpoints.playlistDetail,
      pramsArg: requestParameters,
    );
    if (response == null) {
      return;
    }
    dynamic entries = ParserHelper.parse<List>(
      response,
      SectionListParserKeys.tapMoreResourceList,
    );
    //也有可能是其他格式，所以再容错一下
    entries ??=
        ParserHelper.parse<List>(
          response,
          SectionListParserKeys.initResourceList,
        ) ??
        [];
    //playlist和album的详情页面都是同一个，
    //但是专辑有点不同的是可能还有推荐作品，所以统一再次规定格式为一个FilGroup分组
    entries = await SharedParser.decodeContents(
      entries,
      mediaOrigin: MediaOrigin.playlistHome,
    );
    if (entries is List<MediaCollection>) {
      mediaCollection.children =
          entries
              .where(
                (entry) =>
                    entry.type == MediaCollectionShowType.listMusic ||
                    entry.type == MediaCollectionShowType.responsiveListMusic,
              )
              .firstOrNull
              ?.children ??
          [];
    }
    resourceList.value = entries;
  }

  //请求更多显示根据
  Future _fetchYTData({Map<String, dynamic>? moreParamsInputArg}) async {
    Map<String, dynamic>? requestParameters = {
      'playlistId': mediaCollection.id!,
    };
    if (moreParamsInputArg != null) {
      requestParameters.addAll(moreParamsInputArg);
    }
    dynamic response = await MusicCatalogGateway.post(
      resourceUrl: MusicCatalogEndpoints.ytPlaylistDetail,
      pramsArg: requestParameters,
      isMusicArg: false,
    );
    if (response == null) {
      return;
    }
    response =
        ParserHelper.parse<List>(
          response,
          CollectionCatalogParserKeys.resourceList,
        ) ??
        [];
    List newChildrenLocal = await MusicCatalogParser.decodePlaylistChildren(
      response,
    );
    mediaCollection.children = [
      ...mediaCollection.children,
      ...newChildrenLocal.cast<FileInfo>(),
    ];
    resourceList.value = [mediaCollection];
  }
}
