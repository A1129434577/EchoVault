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

  Future fetchData() async {
    state.value = ResourceStatus.loading;
    if (DiscoveryState.instance.isYoutubeMusicEnable.value) {
      await _fetchData();
    } else {
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
    Map<String, dynamic>? requestParameters = {'browseId': performerDetails.id};
    dynamic response = await MusicCatalogGateway.post(
      resourceUrl: MusicCatalogEndpoints.performerProfile,
      pramsArg: requestParameters,
    );
    if (response == null) {
      return;
    }
    hdThumbnail.value =
        ParserHelper.parse<String>(
          response,
          PerformerParserKeys.primaryCoverPath,
        ) ??
        ParserHelper.parse<String>(
          response,
          PerformerParserKeys.fallbackCoverPath,
        ) ??
        '';
    response =
        ParserHelper.parse<List>(
          response,
          SectionListParserKeys.initResourceListPath,
        ) ??
        [];
    final newResultLocal = await SharedParser.decodeContents(
      response,
      mediaOrigin: MediaOrigin.performerHome,
    );
    resourceList.value = newResultLocal;
  }

  Future _fetchYTData() async {
    String? browseIdLocal = performerDetails.ytId ?? performerDetails.id;
    Map<String, dynamic>? requestParameters = {'browseId': browseIdLocal};
    dynamic response = await MusicCatalogGateway.post(
      resourceUrl: MusicCatalogEndpoints.videoPerformerProfile,
      pramsArg: requestParameters,
      isMusicArg: false,
    );
    if (response == null) {
      return;
    }
    hdThumbnail.value =
        ParserHelper.parse<String>(
          response,
          PerformerCatalogParserKeys.coverPath,
        ) ??
        '';
    if (hdThumbnail.value.isNotEmpty) {
      performerDetails.thumbnail = hdThumbnail.value;
    }
    List responses =
        ParserHelper.parse<List>(
          response,
          PerformerCatalogParserKeys.tabsPath,
        ) ??
        [];
    List<MediaCollection> entries = [];
    for (final tab in responses) {
      String? resourceUrl = ParserHelper.parse<String>(
        tab,
        PerformerCatalogParserKeys.tabUrlPath,
      );
      String displayTitle =
          ParserHelper.parse<String>(
            tab,
            PerformerCatalogParserKeys.tabTitlePath,
          ) ??
          '';
      if (resourceUrl?.contains(PerformerCatalogParserKeys.videosNode) ==
          true) {
        String? browseParamsLocal = ParserHelper.parse<String>(
          tab,
          PerformerCatalogParserKeys.paramsPath,
        );
        Map requestParameters = {
          'browseId': browseIdLocal,
          'params': browseParamsLocal,
        };
        dynamic tabResultLocal = await MusicCatalogGateway.post(
          resourceUrl: MusicCatalogEndpoints.videoPerformerProfile,
          pramsArg: requestParameters,
          isMusicArg: false,
        );
        List tabResultListLocal =
            ParserHelper.parse<List>(
              tabResultLocal,
              PerformerCatalogParserKeys.tabsPath,
            ) ??
            [];
        for (final tab in tabResultListLocal) {
          String? resourceUrl = ParserHelper.parse<String>(
            tab,
            PerformerCatalogParserKeys.tabUrlPath,
          );
          if (resourceUrl?.contains(PerformerCatalogParserKeys.videosNode) ==
              true) {
            MediaCollection mediaCollectionLocal = MediaCollection(
              name: displayTitle,
            );
            mediaCollectionLocal.type = MediaCollectionShowType.listMusic;
            final videosLocal =
                ParserHelper.parse<List>(
                  tab,
                  PerformerCatalogParserKeys.richItemsPath,
                ) ??
                [];
            List childEntries = await MusicCatalogParser.decodeArtistChildren(
              videosLocal,
            );
            mediaCollectionLocal.children = childEntries;
            entries.add(mediaCollectionLocal);
            break;
          }
        }
      } else if (resourceUrl?.contains(
            PerformerCatalogParserKeys.releasesNode,
          ) ==
          true) {
        String? browseParamsLocal = ParserHelper.parse<String>(
          tab,
          PerformerCatalogParserKeys.paramsPath,
        );
        Map requestParameters = {
          'browseId': browseIdLocal,
          'params': browseParamsLocal,
        };
        dynamic tabResultLocal = await MusicCatalogGateway.post(
          resourceUrl: MusicCatalogEndpoints.videoPerformerProfile,
          pramsArg: requestParameters,
          isMusicArg: false,
        );
        List tabResultListLocal =
            ParserHelper.parse<List>(
              tabResultLocal,
              PerformerCatalogParserKeys.tabsPath,
            ) ??
            [];
        for (final tab in tabResultListLocal) {
          String? resourceUrl = ParserHelper.parse<String>(
            tab,
            PerformerCatalogParserKeys.tabUrlPath,
          );
          if (resourceUrl?.contains(PerformerCatalogParserKeys.releasesNode) ==
              true) {
            MediaCollection mediaCollectionLocal = MediaCollection(
              name: displayTitle,
            );
            mediaCollectionLocal.type = MediaCollectionShowType.twoRowPlaylist;
            List entries =
                ParserHelper.parse<List>(
                  tab,
                  PerformerCatalogParserKeys.richItemsPath,
                ) ??
                [];
            List childEntries = await MusicCatalogParser.decodeArtistChildren(
              entries,
            );
            if (childEntries.isNotEmpty) {
              mediaCollectionLocal.children = childEntries;
              entries.add(mediaCollectionLocal);
            }
            break;
          }
        }
      } else if (resourceUrl?.contains(
            PerformerCatalogParserKeys.playlistsNode,
          ) ==
          true) {
        String? browseParamsLocal = ParserHelper.parse<String>(
          tab,
          PerformerCatalogParserKeys.paramsPath,
        );
        Map requestParameters = {
          'browseId': browseIdLocal,
          'params': browseParamsLocal,
        };
        dynamic tabResultLocal = await MusicCatalogGateway.post(
          resourceUrl: MusicCatalogEndpoints.videoPerformerProfile,
          pramsArg: requestParameters,
          isMusicArg: false,
        );
        List tabResultListLocal =
            ParserHelper.parse<List>(
              tabResultLocal,
              PerformerCatalogParserKeys.tabsPath,
            ) ??
            [];
        for (final tab in tabResultListLocal) {
          String? resourceUrl = ParserHelper.parse<String>(
            tab,
            PerformerCatalogParserKeys.tabUrlPath,
          );
          if (resourceUrl?.contains(PerformerCatalogParserKeys.playlistsNode) ==
              true) {
            MediaCollection mediaCollectionLocal = MediaCollection(
              name: displayTitle,
            );
            mediaCollectionLocal.type = MediaCollectionShowType.twoRowPlaylist;
            List entries =
                ParserHelper.parse<List>(
                  tab,
                  PerformerCatalogParserKeys.lockupViewModelPlaylistItemsPath,
                ) ??
                [];
            List childEntries = await MusicCatalogParser.decodeArtistChildren(
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
  static List primaryCoverPath = [
    'header',
    'musicImmersiveHeaderRenderer',
    'thumbnail',
    'musicThumbnailRenderer',
    'thumbnail',
    'thumbnails',
    {ParserHelper.positionField: 2},
    'url',
  ];

  static List fallbackCoverPath = [
    'header',
    'musicVisualHeaderRenderer',
    'thumbnail',
    'musicThumbnailRenderer',
    'thumbnail',
    'thumbnails',
    {ParserHelper.positionField: 2},
    'url',
  ];
}
