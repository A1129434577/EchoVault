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
  ValueNotifier<ResourceStatus> state = ValueNotifier(ResourceStatus.idl);
  EasyRefreshController refreshController = EasyRefreshController();
  late ValueNotifier<String> hdThumbnail = ValueNotifier(
    performerDetails.thumbnail,
  );
  ValueNotifier<List<MediaCollection>?> resourceList = ValueNotifier(null);
  PerformerDetailState({required this.performerDetails});

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
    Map<String, dynamic>? requestParameters = {'browseId': performerDetails.id};
    dynamic response = await MusicCatalogGateway.post(
      resourceUrl: MusicCatalogEndpoints.artistDetail,
      pramsArg: requestParameters,
    );
    if (response == null) {
      return;
    }
    hdThumbnail.value =
        ParserHelper.parse<String>(response, PerformerParserKeys.cover) ??
        ParserHelper.parse<String>(response, PerformerParserKeys.coverBackup) ??
        '';
    response =
        ParserHelper.parse<List>(
          response,
          SectionListParserKeys.initResourceList,
        ) ??
        [];
    final newResultLocal = await SharedParser.parseContents(
      response,
      mediaOrigin: MediaOrigin.artistHome,
    );
    resourceList.value = newResultLocal;
  }

  Future _queryYTData() async {
    String? browseIdLocal = performerDetails.ytId ?? performerDetails.id;
    Map<String, dynamic>? requestParameters = {'browseId': browseIdLocal};
    dynamic response = await MusicCatalogGateway.post(
      resourceUrl: MusicCatalogEndpoints.ytArtistDetail,
      pramsArg: requestParameters,
      isMusicArg: false,
    );
    if (response == null) {
      return;
    }
    hdThumbnail.value =
        ParserHelper.parse<String>(
          response,
          PerformerCatalogParserKeys.cover,
        ) ??
        '';
    if (hdThumbnail.value.isNotEmpty) {
      performerDetails.thumbnail = hdThumbnail.value;
    }
    List responses =
        ParserHelper.parse<List>(response, PerformerCatalogParserKeys.tabs) ??
        [];
    List<MediaCollection> entries = [];
    for (final tab in responses) {
      String? resourceUrl = ParserHelper.parse<String>(
        tab,
        PerformerCatalogParserKeys.tabUrl,
      );
      String displayTitle =
          ParserHelper.parse<String>(
            tab,
            PerformerCatalogParserKeys.tabTitle,
          ) ??
          '';
      if (resourceUrl?.contains(PerformerCatalogParserKeys.videos) == true) {
        String? browseParamsLocal = ParserHelper.parse<String>(
          tab,
          PerformerCatalogParserKeys.params,
        );
        Map requestParameters = {
          'browseId': browseIdLocal,
          'params': browseParamsLocal,
        };
        dynamic tabResultLocal = await MusicCatalogGateway.post(
          resourceUrl: MusicCatalogEndpoints.ytArtistDetail,
          pramsArg: requestParameters,
          isMusicArg: false,
        );
        List tabResultListLocal =
            ParserHelper.parse<List>(
              tabResultLocal,
              PerformerCatalogParserKeys.tabs,
            ) ??
            [];
        for (final tab in tabResultListLocal) {
          String? resourceUrl = ParserHelper.parse<String>(
            tab,
            PerformerCatalogParserKeys.tabUrl,
          );
          if (resourceUrl?.contains(PerformerCatalogParserKeys.videos) ==
              true) {
            MediaCollection mediaCollectionLocal = MediaCollection(
              name: displayTitle,
            );
            mediaCollectionLocal.type = MediaCollectionShowType.listMusic;
            final videosLocal =
                ParserHelper.parse<List>(
                  tab,
                  PerformerCatalogParserKeys.richItems,
                ) ??
                [];
            List childEntries = await MusicCatalogParser.parseArtistChildren(
              videosLocal,
            );
            mediaCollectionLocal.children = childEntries;
            entries.add(mediaCollectionLocal);
            break;
          }
        }
      } else if (resourceUrl?.contains(PerformerCatalogParserKeys.releases) ==
          true) {
        String? browseParamsLocal = ParserHelper.parse<String>(
          tab,
          PerformerCatalogParserKeys.params,
        );
        Map requestParameters = {
          'browseId': browseIdLocal,
          'params': browseParamsLocal,
        };
        dynamic tabResultLocal = await MusicCatalogGateway.post(
          resourceUrl: MusicCatalogEndpoints.ytArtistDetail,
          pramsArg: requestParameters,
          isMusicArg: false,
        );
        List tabResultListLocal =
            ParserHelper.parse<List>(
              tabResultLocal,
              PerformerCatalogParserKeys.tabs,
            ) ??
            [];
        for (final tab in tabResultListLocal) {
          String? resourceUrl = ParserHelper.parse<String>(
            tab,
            PerformerCatalogParserKeys.tabUrl,
          );
          if (resourceUrl?.contains(PerformerCatalogParserKeys.releases) ==
              true) {
            MediaCollection mediaCollectionLocal = MediaCollection(
              name: displayTitle,
            );
            mediaCollectionLocal.type = MediaCollectionShowType.twoRowPlaylist;
            List entries =
                ParserHelper.parse<List>(
                  tab,
                  PerformerCatalogParserKeys.richItems,
                ) ??
                [];
            List childEntries = await MusicCatalogParser.parseArtistChildren(
              entries,
            );
            if (childEntries.isNotEmpty) {
              mediaCollectionLocal.children = childEntries;
              entries.add(mediaCollectionLocal);
            }
            break;
          }
        }
      } else if (resourceUrl?.contains(PerformerCatalogParserKeys.playlists) ==
          true) {
        String? browseParamsLocal = ParserHelper.parse<String>(
          tab,
          PerformerCatalogParserKeys.params,
        );
        Map requestParameters = {
          'browseId': browseIdLocal,
          'params': browseParamsLocal,
        };
        dynamic tabResultLocal = await MusicCatalogGateway.post(
          resourceUrl: MusicCatalogEndpoints.ytArtistDetail,
          pramsArg: requestParameters,
          isMusicArg: false,
        );
        List tabResultListLocal =
            ParserHelper.parse<List>(
              tabResultLocal,
              PerformerCatalogParserKeys.tabs,
            ) ??
            [];
        for (final tab in tabResultListLocal) {
          String? resourceUrl = ParserHelper.parse<String>(
            tab,
            PerformerCatalogParserKeys.tabUrl,
          );
          if (resourceUrl?.contains(PerformerCatalogParserKeys.playlists) ==
              true) {
            MediaCollection mediaCollectionLocal = MediaCollection(
              name: displayTitle,
            );
            mediaCollectionLocal.type = MediaCollectionShowType.twoRowPlaylist;
            List entries =
                ParserHelper.parse<List>(
                  tab,
                  PerformerCatalogParserKeys.lockupViewModelPlaylistItems,
                ) ??
                [];
            List childEntries = await MusicCatalogParser.parseArtistChildren(
              entries,
            );
            if (childEntries.isNotEmpty) {
              mediaCollectionLocal.children = childEntries;
              entries.add(mediaCollectionLocal);
            }
            break;
          }
        }
      }
    }
    resourceList.value = entries;
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
