import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/media/media_origin.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/features/discovery/controllers/discovery_state.dart';
import 'package:echo_vault/core/networking/music_catalog_gateway.dart';
import 'package:echo_vault/core/parsing/shared_parser.dart';
import 'package:echo_vault/core/parsing/music_catalog_parser.dart';
import 'package:echo_vault/core/parsing/parser_helper.dart';
import 'package:echo_vault/shared/widgets/resource_state_view.dart';

class PerformerDetailState with ChangeNotifier {
  final PerformerDetails performerDetails;
  PerformerDetailState({required this.performerDetails});
  ValueNotifier<ResourceStatus> state = ValueNotifier(ResourceStatus.idl);
  EasyRefreshController refreshController = EasyRefreshController();
  late ValueNotifier<String> hdThumbnail = ValueNotifier(
    performerDetails.thumbnail,
  );
  ValueNotifier<List<MediaCollection>?> resourceList = ValueNotifier(null);

  Future queryData() async {
    state.value = ResourceStatus.loading;
    if (DiscoveryState.instance.isYoutubeMusicEnable.value) {
      await _queryData();
    } else {
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
    Map<String, dynamic>? params = {'browseId': performerDetails.id};
    dynamic result = await MusicCatalogGateway.post(
      url: MusicCatalogEndpoints.artistDetail,
      prams: params,
    );
    if (result == null) {
      return;
    }
    hdThumbnail.value =
        ParserHelper.parse<String>(result, PerformerParserKeys.cover) ??
        ParserHelper.parse<String>(result, PerformerParserKeys.coverBackup) ??
        '';
    result =
        ParserHelper.parse<List>(
          result,
          SectionListParserKeys.initResourceList,
        ) ??
        [];
    final newResult = await SharedParser.parseContents(
      result,
      source: MediaOrigin.artistHome,
    );
    resourceList.value = newResult;
  }

  Future _queryYTData() async {
    String? browseId = performerDetails.ytId ?? performerDetails.id;
    Map<String, dynamic>? params = {'browseId': browseId};
    dynamic result = await MusicCatalogGateway.post(
      url: MusicCatalogEndpoints.ytArtistDetail,
      prams: params,
      isMusic: false,
    );
    if (result == null) {
      return;
    }
    hdThumbnail.value =
        ParserHelper.parse<String>(result, PerformerCatalogParserKeys.cover) ??
        '';
    if (hdThumbnail.value.isNotEmpty) {
      performerDetails.thumbnail = hdThumbnail.value;
    }
    List results =
        ParserHelper.parse<List>(result, PerformerCatalogParserKeys.tabs) ?? [];
    List<MediaCollection> list = [];
    for (final tab in results) {
      String? url = ParserHelper.parse<String>(
        tab,
        PerformerCatalogParserKeys.tabUrl,
      );
      String title =
          ParserHelper.parse<String>(
            tab,
            PerformerCatalogParserKeys.tabTitle,
          ) ??
          '';
      if (url?.contains(PerformerCatalogParserKeys.videos) == true) {
        String? browseParams = ParserHelper.parse<String>(
          tab,
          PerformerCatalogParserKeys.params,
        );
        Map params = {'browseId': browseId, 'params': browseParams};
        dynamic tabResult = await MusicCatalogGateway.post(
          url: MusicCatalogEndpoints.ytArtistDetail,
          prams: params,
          isMusic: false,
        );
        List tabResultList =
            ParserHelper.parse<List>(
              tabResult,
              PerformerCatalogParserKeys.tabs,
            ) ??
            [];
        for (final tab in tabResultList) {
          String? url = ParserHelper.parse<String>(
            tab,
            PerformerCatalogParserKeys.tabUrl,
          );
          if (url?.contains(PerformerCatalogParserKeys.videos) == true) {
            MediaCollection mediaCollection = MediaCollection(name: title);
            mediaCollection.type = MediaCollectionShowType.listMusic;
            final videos =
                ParserHelper.parse<List>(
                  tab,
                  PerformerCatalogParserKeys.richItems,
                ) ??
                [];
            List children = await MusicCatalogParser.parseArtistChildren(
              videos,
            );
            mediaCollection.children = children;
            list.add(mediaCollection);
            break;
          }
        }
      } else if (url?.contains(PerformerCatalogParserKeys.releases) == true) {
        String? browseParams = ParserHelper.parse<String>(
          tab,
          PerformerCatalogParserKeys.params,
        );
        Map params = {'browseId': browseId, 'params': browseParams};
        dynamic tabResult = await MusicCatalogGateway.post(
          url: MusicCatalogEndpoints.ytArtistDetail,
          prams: params,
          isMusic: false,
        );
        List tabResultList =
            ParserHelper.parse<List>(
              tabResult,
              PerformerCatalogParserKeys.tabs,
            ) ??
            [];
        for (final tab in tabResultList) {
          String? url = ParserHelper.parse<String>(
            tab,
            PerformerCatalogParserKeys.tabUrl,
          );
          if (url?.contains(PerformerCatalogParserKeys.releases) == true) {
            MediaCollection mediaCollection = MediaCollection(name: title);
            mediaCollection.type = MediaCollectionShowType.twoRowPlaylist;
            List items =
                ParserHelper.parse<List>(
                  tab,
                  PerformerCatalogParserKeys.richItems,
                ) ??
                [];
            List children = await MusicCatalogParser.parseArtistChildren(items);
            if (children.isNotEmpty) {
              mediaCollection.children = children;
              list.add(mediaCollection);
            }
            break;
          }
        }
      } else if (url?.contains(PerformerCatalogParserKeys.playlists) == true) {
        String? browseParams = ParserHelper.parse<String>(
          tab,
          PerformerCatalogParserKeys.params,
        );
        Map params = {'browseId': browseId, 'params': browseParams};
        dynamic tabResult = await MusicCatalogGateway.post(
          url: MusicCatalogEndpoints.ytArtistDetail,
          prams: params,
          isMusic: false,
        );
        List tabResultList =
            ParserHelper.parse<List>(
              tabResult,
              PerformerCatalogParserKeys.tabs,
            ) ??
            [];
        for (final tab in tabResultList) {
          String? url = ParserHelper.parse<String>(
            tab,
            PerformerCatalogParserKeys.tabUrl,
          );
          if (url?.contains(PerformerCatalogParserKeys.playlists) == true) {
            MediaCollection mediaCollection = MediaCollection(name: title);
            mediaCollection.type = MediaCollectionShowType.twoRowPlaylist;
            List items =
                ParserHelper.parse<List>(
                  tab,
                  PerformerCatalogParserKeys.lockupViewModelPlaylistItems,
                ) ??
                [];
            List children = await MusicCatalogParser.parseArtistChildren(items);
            if (children.isNotEmpty) {
              mediaCollection.children = children;
              list.add(mediaCollection);
            }
            break;
          }
        }
      }
    }
    resourceList.value = list;
  }
}

class PerformerParserKeys {
  ///歌手封面大图
  static List cover = [
    'header',
    'musicImmersiveHeaderRenderer',
    'thumbnail',
    'musicThumbnailRenderer',
    'thumbnail',
    'thumbnails',
    {ParserHelper.indexKey: 2},
    'url',
  ];

  static List coverBackup = [
    'header',
    'musicVisualHeaderRenderer',
    'thumbnail',
    'musicThumbnailRenderer',
    'thumbnail',
    'thumbnails',
    {ParserHelper.indexKey: 2},
    'url',
  ];
}
