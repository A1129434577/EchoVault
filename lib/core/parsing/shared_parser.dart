import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/core/parsing/record_sync_helper.dart';
import 'package:echo_vault/core/parsing/parser_helper.dart';

enum MediaType {
  //如果列表里面一个ATV都没有，用全视频样式渲染
  MUSIC_VIDEO_TYPE_ATV,
  MUSIC_VIDEO_TYPE_OMV,
  MUSIC_VIDEO_TYPE_UGC,
  //播客
  MUSIC_VIDEO_TYPE_PODCAST_EPISODE,
  //YouTube上的视频类型
  LOCKUP_CONTENT_TYPE_VIDEO,
}

//卡片解析（如搜索最佳结果）
class CardShelfParserKeys {
  static String cardShelfNode = 'musicCardShelfRenderer';

  static List pageTypePath = [
    'title',
    'runs',
    {ParserHelper.positionField: 0},
    'navigationEndpoint',
    'browseEndpoint',
    'browseEndpointContextSupportedConfigs',
    'browseEndpointContextMusicConfig',
    'pageType',
  ];

  static List browseIdPath = [
    'title',
    'runs',
    {ParserHelper.positionField: 0},
    'navigationEndpoint',
    'browseEndpoint',
    'browseId',
  ];

  static List musicVideoTypePath = [
    'title',
    'runs',
    {ParserHelper.positionField: 0},
    'navigationEndpoint',
    'watchEndpoint',
    'watchEndpointMusicSupportedConfigs',
    'watchEndpointMusicConfig',
    'musicVideoType',
  ];

  static List videoIdPath = [
    'title',
    'runs',
    {ParserHelper.positionField: 0},
    'navigationEndpoint',
    'watchEndpoint',
    'videoId',
  ];

  static List coverPath = [
    'thumbnail',
    'musicThumbnailRenderer',
    'thumbnail',
    'thumbnails',
    {ParserHelper.positionField: 0},
    'url',
  ];

  static List titlePath = [
    'title',
    'runs',
    {ParserHelper.positionField: 0},
    'text',
  ];

  static List subtitleRunsPath = ['subtitle', 'runs'];
}

//书架样式页面解析（如主页，歌手主页）
class CarouselShelfParserKeys {
  static String carouselShelfNode = 'musicCarouselShelfRenderer';

  static List groupIdPath = [
    'header',
    'musicCarouselShelfBasicHeaderRenderer',
    'moreContentButton',
    'buttonRenderer',
    'navigationEndpoint',
    'browseEndpoint',
    'browseId',
  ];

  static List groupNamePath = [
    'header',
    'musicCarouselShelfBasicHeaderRenderer',
    'title',
    'runs',
    {ParserHelper.positionField: 0},
    'text',
  ];

  static List groupParamsPath = [
    'header',
    'musicCarouselShelfBasicHeaderRenderer',
    'moreContentButton',
    'buttonRenderer',
    'navigationEndpoint',
    'browseEndpoint',
    'params',
  ];
}

//网格页面解析（如主页playlist项点击more后）
class GridRendererParserKeys {
  static String girdNode = 'gridRenderer';
  static List listPath = ['items'];
}

//类似播客解析
class MultiRowListParserKeys {
  static String multiRowNode = 'musicMultiRowListItemRenderer';

  static List musicVideoTypePath = [
    'overlay',
    'musicItemThumbnailOverlayRenderer',
    'content',
    'musicPlayButtonRenderer',
    'playNavigationEndpoint',
    'watchEndpoint',
    'watchEndpointMusicSupportedConfigs',
    'watchEndpointMusicConfig',
    'musicVideoType',
  ];

  static List videoIdPath = [
    'overlay',
    'musicItemThumbnailOverlayRenderer',
    'content',
    'musicPlayButtonRenderer',
    'playNavigationEndpoint',
    'watchEndpoint',
    'videoId',
  ];

  static List coverPath = [
    'thumbnail',
    'musicThumbnailRenderer',
    'thumbnail',
    'thumbnails',
    {ParserHelper.positionField: 1},
    'url',
  ];

  static List titlePath = [
    'title',
    'runs',
    {ParserHelper.positionField: 0},
    'text',
  ];

  static List subtitleRunsPath = ['subtitle', 'runs'];
}

//比如首页为你推荐的精选播放列表
class NavigationButtonParserKeys {
  static List sectionTitlePath = [
    'header',
    'gridHeaderRenderer',
    'title',
    'runs',
    {ParserHelper.positionField: 0},
    'text',
  ];

  static String navigationNode = 'musicNavigationButtonRenderer';

  //局部单列表的分组id（比如歌手列表的热门歌曲）
  static List browseIdPath = ['clickCommand', 'browseEndpoint', 'browseId'];

  //局部单列表的分组name（比如歌手列表的热门歌曲）
  static List titlePath = [
    'buttonText',
    'runs',
    {ParserHelper.positionField: 0},
    'text',
  ];

  static List paramsPath = ['clickCommand', 'browseEndpoint', 'params'];
}

//接下来播放解析
class PanelVideoParserKeys {
  static String panelNode = 'playlistPanelVideoRenderer';

  static List musicVideoTypePath = [
    'navigationEndpoint',
    'watchEndpoint',
    'watchEndpointMusicSupportedConfigs',
    'watchEndpointMusicConfig',
    'musicVideoType',
  ];

  static List videoIdPath = ['videoId'];

  static List coverPath = [
    'thumbnail',
    'thumbnails',
    {ParserHelper.positionField: 1},
    'url',
  ];

  static List titlePath = [
    'title',
    'runs',
    {ParserHelper.positionField: 0},
    'text',
  ];

  static List subtitleRunsPath = ['longBylineText', 'runs'];
}

class ResponsiveListParserKeys {
  static String responsiveListNode = 'musicResponsiveListItemRenderer';

  static List musicVideoTypePath = [
    'overlay',
    'musicItemThumbnailOverlayRenderer',
    'content',
    'musicPlayButtonRenderer',
    'playNavigationEndpoint',
    'watchEndpoint',
    'watchEndpointMusicSupportedConfigs',
    'watchEndpointMusicConfig',
    'musicVideoType',
  ];

  static List videoIdPath = ['playlistItemData', 'videoId'];

  static List coverPath = [
    'thumbnail',
    'musicThumbnailRenderer',
    'thumbnail',
    'thumbnails',
    {ParserHelper.positionField: 1},
    'url',
  ];

  static List titlePath = [
    'flexColumns',
    {ParserHelper.positionField: 0},
    'musicResponsiveListItemFlexColumnRenderer',
    'text',
    'runs',
    {ParserHelper.positionField: 0},
    'text',
  ];
  static List subtitleRunsPath = [
    'flexColumns',
    {ParserHelper.positionField: 1},
    'musicResponsiveListItemFlexColumnRenderer',
    'text',
    'runs',
  ];
}

class ResponsiveListTowRowSharedParserKeys {
  static List pageTypePath = [
    'navigationEndpoint',
    'browseEndpoint',
    'browseEndpointContextSupportedConfigs',
    'browseEndpointContextMusicConfig',
    'pageType',
  ];
  static List browseIdPath = [
    'navigationEndpoint',
    'browseEndpoint',
    'browseId',
  ];
}

///类似主页样式分组列表解析参数
class SectionListParserKeys {
  //翻页参数
  static List initContinuationPath = [
    'contents',
    'singleColumnBrowseResultsRenderer',
    'tabs',
    {ParserHelper.positionField: 0},
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'continuations',
    {ParserHelper.positionField: 0},
    'nextContinuationData',
    'continuation',
  ];

  //翻页参数
  static List moreContinuationPath = [
    'continuationContents',
    'sectionListContinuation',
    'continuations',
    {ParserHelper.positionField: 0},
    'nextContinuationData',
    'continuation',
  ];

  //如果这个不为空说明不可用
  static List itemSectionRendererPath = [
    'contents',
    'singleColumnBrowseResultsRenderer',
    'tabs',
    {ParserHelper.positionField: 0},
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'contents',
    {ParserHelper.matchField: 'itemSectionRenderer'},
  ];

  //翻页第一页数据列表
  static List initResourceListPath = [
    'contents',
    'singleColumnBrowseResultsRenderer',
    'tabs',
    {ParserHelper.positionField: 0},
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'contents',
  ];

  //翻页更多页数据列表
  static List moreResourceListPath = [
    'continuationContents',
    'sectionListContinuation',
    'contents',
  ];

  //点击右侧更多之后的数据列表
  static List tapMoreResourceListPath = [
    'contents',
    'twoColumnBrowseResultsRenderer',
    'secondaryContents',
    'sectionListRenderer',
    'contents',
  ];
}

class SharedParser {
  static Future<PerformerDetails> decodeCardArtist(
    Map performerRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    PerformerDetails artistLocal = PerformerDetails();
    artistLocal.id = ParserHelper.parse<String>(
      performerRecord,
      CardShelfParserKeys.browseIdPath,
    );
    artistLocal.thumbnail =
        ParserHelper.parse<String>(
          performerRecord,
          CardShelfParserKeys.coverPath,
        ) ??
        '';
    artistLocal.name =
        ParserHelper.parse<String>(
          performerRecord,
          CardShelfParserKeys.titlePath,
        ) ??
        '';
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              performerRecord,
              CardShelfParserKeys.subtitleRunsPath,
            ) ??
            []) {
      secondaryText += textRun['text'];
    }
    artistLocal.desc = secondaryText;
    await RecordSyncHelper.reconcileArtist(artistLocal);
    return artistLocal;
  }

  static Future<FileInfo> decodeCardMusicVideo(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(
          mediaRecord,
          CardShelfParserKeys.videoIdPath,
        ) ??
        '';
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(
          mediaRecord,
          CardShelfParserKeys.coverPath,
        ) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          CardShelfParserKeys.titlePath,
        ) ??
        '';
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              mediaRecord,
              CardShelfParserKeys.subtitleRunsPath,
            ) ??
            []) {
      secondaryText += textRun['text'];
    }
    mediaEntry.artist = secondaryText;
    await RecordSyncHelper.reconcileFileInfo(mediaEntry);
    return mediaEntry;
  }

  static Future<MediaCollection> decodeCardPlaylist(
    Map collectionRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    MediaCollection mediaCollectionLocal = MediaCollection();
    mediaCollectionLocal.id = ParserHelper.parse<String>(
      collectionRecord,
      CardShelfParserKeys.browseIdPath,
    );
    mediaCollectionLocal.thumbnail =
        ParserHelper.parse<String>(
          collectionRecord,
          CardShelfParserKeys.coverPath,
        ) ??
        '';
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          collectionRecord,
          CardShelfParserKeys.titlePath,
        ) ??
        "";
    mediaCollectionLocal.displayName = mediaCollectionLocal.name;
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              collectionRecord,
              CardShelfParserKeys.subtitleRunsPath,
            ) ??
            []) {
      secondaryText += textRun['text'];
    }
    mediaCollectionLocal.detail = secondaryText;
    await RecordSyncHelper.reconcileFileGroup(mediaCollectionLocal);
    return mediaCollectionLocal;
  }

  ///解析书架样式的group(比如主页数据)
  static Future<MediaCollection> decodeCarouselShelfFileGroup(
    Map fileGroupMapArg, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    MediaCollection mediaCollectionLocal = MediaCollection();
    mediaCollectionLocal.id = ParserHelper.parse<String>(
      fileGroupMapArg,
      CarouselShelfParserKeys.groupIdPath,
    );
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          fileGroupMapArg,
          CarouselShelfParserKeys.groupNamePath,
        ) ??
        '';
    mediaCollectionLocal.params = ParserHelper.parse<String>(
      fileGroupMapArg,
      CarouselShelfParserKeys.groupParamsPath,
    );
    List childRecords = fileGroupMapArg[SharedParserKeys.childrenNode] ?? [];
    List childEntries = await decodeChildren(
      childRecords,
      mediaCollectionArg: mediaCollectionLocal,
      mediaOrigin: mediaOrigin,
    );

    if (mediaCollectionLocal.type == null) {
      //剔除itemList中的的另类(比如大多是是视频里出现了一个playlist)
      List<FileInfo> mediaQueue = childEntries.whereType<FileInfo>().toList();
      List<MediaCollection> playlistListLocal = childEntries
          .whereType<MediaCollection>()
          .toList();
      List<PerformerDetails> performersLocal = childEntries
          .whereType<PerformerDetails>()
          .toList();
      if (mediaQueue.length >= playlistListLocal.length &&
          mediaQueue.length >= performersLocal.length) {
        mediaCollectionLocal.type = MediaCollectionShowType.twoRowVideo;
        childEntries = mediaQueue;
      } else if (playlistListLocal.length >= mediaQueue.length &&
          playlistListLocal.length >= performersLocal.length) {
        mediaCollectionLocal.type = MediaCollectionShowType.twoRowPlaylist;
        childEntries = playlistListLocal;
      } else {
        mediaCollectionLocal.type = MediaCollectionShowType.twoRowArtist;
        childEntries = performersLocal;
      }
    }
    mediaCollectionLocal.children = childEntries;
    return mediaCollectionLocal;
  }

  static Future<List> decodeChildren(
    List childRecords, {
    MediaCollection? mediaCollectionArg,
    MediaSourceInterface? mediaOrigin,
  }) async {
    List childEntries = [];
    for (final childrenMap in childRecords) {
      if (childrenMap.containsKey(
        ResponsiveListParserKeys.responsiveListNode,
      )) {
        Map nestedRecord =
            childrenMap[ResponsiveListParserKeys.responsiveListNode];
        String? playlistTypeLocal = ParserHelper.parse<String>(
          nestedRecord,
          ResponsiveListTowRowSharedParserKeys.pageTypePath,
        );
        String? mediaId = ParserHelper.parse<String>(
          nestedRecord,
          ResponsiveListParserKeys.videoIdPath,
        );
        if (playlistTypeLocal != null) {
          if (playlistTypeLocal == PerformerDetails.musicArtistPageType) {
            mediaCollectionArg?.type = MediaCollectionShowType.twoRowArtist;
            PerformerDetails artistLocal = await decodeResponsiveListArtist(
              nestedRecord,
              mediaOrigin: mediaOrigin,
            );
            childEntries.add(artistLocal);
          } else {
            mediaCollectionArg?.type = MediaCollectionShowType.twoRowPlaylist;
            MediaCollection playlistLocal = await decodeResponsiveListPlaylist(
              nestedRecord,
              mediaOrigin: mediaOrigin,
            );
            playlistLocal.playlistType = playlistTypeLocal;
            childEntries.add(playlistLocal);
          }
        } else if (mediaId != null) {
          //这里注意一下：如果已经作为Shelf单列表样式展示了就不再使用其他样式
          mediaCollectionArg?.type ??=
              MediaCollectionShowType.responsiveListMusic;
          FileInfo mediaEntry = await decodeResponsiveListMusic(
            nestedRecord,
            mediaOrigin: mediaOrigin,
          );
          //B面parentId只用于埋点，无其他实际逻辑
          mediaEntry.parentId = mediaCollectionArg?.name;
          childEntries.add(mediaEntry);
        }
      } else if (childrenMap.containsKey(TwoRowParserKeys.twoRowNode)) {
        Map nestedRecord = childrenMap[TwoRowParserKeys.twoRowNode];
        String? playlistTypeLocal = ParserHelper.parse<String>(
          nestedRecord,
          ResponsiveListTowRowSharedParserKeys.pageTypePath,
        );
        String? videoTypeLocal = ParserHelper.parse<String>(
          nestedRecord,
          TwoRowParserKeys.musicVideoTypePath,
        );
        if (playlistTypeLocal != null) {
          if (playlistTypeLocal == PerformerDetails.musicArtistPageType) {
            PerformerDetails artistLocal = await decodeTwoRowArtist(
              nestedRecord,
              mediaOrigin: mediaOrigin,
            );
            childEntries.add(artistLocal);
          } else {
            MediaCollection playlistLocal = await decodeTwoRowPlaylist(
              nestedRecord,
              mediaOrigin: mediaOrigin,
            );
            playlistLocal.playlistType = playlistTypeLocal;
            childEntries.add(playlistLocal);
          }
        } else if (videoTypeLocal != null) {
          FileInfo mediaEntry = await decodeTwoRowMusicVideo(
            nestedRecord,
            mediaOrigin: mediaOrigin,
          );
          mediaEntry.type = videoTypeLocal;
          //B面parentId只用于埋点，无其他实际逻辑
          mediaEntry.parentId = mediaCollectionArg?.name;
          childEntries.add(mediaEntry);
        }
      } else if (childrenMap.containsKey(CardShelfParserKeys.cardShelfNode)) {
        Map nestedRecord = childrenMap[CardShelfParserKeys.cardShelfNode];
        String? playlistTypeLocal = ParserHelper.parse<String>(
          nestedRecord,
          CardShelfParserKeys.pageTypePath,
        );
        String? videoTypeLocal = ParserHelper.parse<String>(
          nestedRecord,
          CardShelfParserKeys.musicVideoTypePath,
        );
        if (playlistTypeLocal != null) {
          if (playlistTypeLocal == PerformerDetails.musicArtistPageType) {
            PerformerDetails artistLocal = await decodeCardArtist(
              nestedRecord,
              mediaOrigin: mediaOrigin,
            );
            childEntries.add(artistLocal);
          } else {
            MediaCollection playlistLocal = await decodeCardPlaylist(
              nestedRecord,
              mediaOrigin: mediaOrigin,
            );
            playlistLocal.playlistType = playlistTypeLocal;
            childEntries.add(playlistLocal);
          }
        } else if (videoTypeLocal != null) {
          FileInfo mediaEntry = await decodeCardMusicVideo(
            nestedRecord,
            mediaOrigin: mediaOrigin,
          );
          mediaEntry.type = videoTypeLocal;
          //B面parentId只用于埋点，无其他实际逻辑
          mediaEntry.parentId = mediaCollectionArg?.name;
          childEntries.add(mediaEntry);
        }
      } else if (childrenMap.containsKey(MultiRowListParserKeys.multiRowNode)) {
        Map nestedRecord = childrenMap[MultiRowListParserKeys.multiRowNode];
        String? videoTypeLocal = ParserHelper.parse<String>(
          nestedRecord,
          MultiRowListParserKeys.musicVideoTypePath,
        );
        if (videoTypeLocal != null) {
          FileInfo mediaEntry = await decodeMultiRowMusicVideo(
            nestedRecord,
            mediaOrigin: mediaOrigin,
          );
          mediaEntry.type = videoTypeLocal;
          //B面parentId只用于埋点，无其他实际逻辑
          mediaEntry.parentId = mediaCollectionArg?.name;
          childEntries.add(mediaEntry);
        }
      } else if (childrenMap.containsKey(PanelVideoParserKeys.panelNode)) {
        Map nestedRecord = childrenMap[PanelVideoParserKeys.panelNode];
        String? videoTypeLocal = ParserHelper.parse<String>(
          nestedRecord,
          PanelVideoParserKeys.musicVideoTypePath,
        );
        if (videoTypeLocal != null) {
          FileInfo mediaEntry = await decodePanelVideo(
            nestedRecord,
            mediaOrigin: mediaOrigin,
          );
          mediaEntry.type = videoTypeLocal;
          //B面parentId只用于埋点，无其他实际逻辑
          mediaEntry.parentId = mediaCollectionArg?.name;
          childEntries.add(mediaEntry);
        }
      } else if (childrenMap.containsKey(
        NavigationButtonParserKeys.navigationNode,
      )) {
        Map nestedRecord =
            childrenMap[NavigationButtonParserKeys.navigationNode];
        MediaCollection playlistLocal = await decodeNavigationPlaylist(
          nestedRecord,
          mediaOrigin: mediaOrigin,
        );
        childEntries.add(playlistLocal);
      }
    }
    return childEntries;
  }

  static Future<List<MediaCollection>> decodeContents(
    List groupMapListArg, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    List<MediaCollection> entries = [];
    for (Map groupMap in groupMapListArg) {
      if (groupMap.containsKey(CarouselShelfParserKeys.carouselShelfNode)) {
        groupMap = groupMap[CarouselShelfParserKeys.carouselShelfNode];
        MediaCollection mediaCollectionLocal =
            await SharedParser.decodeCarouselShelfFileGroup(
              groupMap,
              mediaOrigin: mediaOrigin,
            );
        entries.add(mediaCollectionLocal);
      } else if (groupMap.containsKey(ShelfParserKeys.shelfNode)) {
        //多类型中夹杂的单列表，有group的title、name等
        groupMap = groupMap[ShelfParserKeys.shelfNode];
        MediaCollection mediaCollectionLocal =
            await SharedParser.decodeShelfFileGroup(
              groupMap,
              mediaOrigin: mediaOrigin,
            );
        entries.add(mediaCollectionLocal);
      } else if (groupMap.containsKey(ShelfParserKeys.playlistShelfNode)) {
        //纯单列表无group的title、name等
        groupMap = groupMap[ShelfParserKeys.playlistShelfNode];
        MediaCollection mediaCollectionLocal = MediaCollection(
          type: MediaCollectionShowType.listMusic,
        );
        List childRecords = groupMap[SharedParserKeys.childrenNode] ?? [];
        List childEntries = await decodeChildren(
          childRecords,
          mediaOrigin: mediaOrigin,
        );
        mediaCollectionLocal.children = childEntries;
        entries.add(mediaCollectionLocal);
      } else if (groupMap.containsKey(GridRendererParserKeys.girdNode)) {
        groupMap = groupMap[GridRendererParserKeys.girdNode];
        String? nameLocal = ParserHelper.parse<String>(
          groupMap,
          NavigationButtonParserKeys.sectionTitlePath,
        );
        MediaCollection mediaCollectionLocal = MediaCollection(
          type: nameLocal != null
              ? MediaCollectionShowType.twoRowPlaylist
              : MediaCollectionShowType.grid,
        );
        mediaCollectionLocal.name = nameLocal ?? '';
        List childRecords =
            ParserHelper.parse<List>(
              groupMap,
              GridRendererParserKeys.listPath,
            ) ??
            [];
        List childEntries = await decodeChildren(
          childRecords,
          mediaOrigin: mediaOrigin,
        );
        mediaCollectionLocal.children = childEntries;
        entries.add(mediaCollectionLocal);
      }
    }
    return entries;
  }

  static Future<FileInfo> decodeMultiRowMusicVideo(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(
          mediaRecord,
          MultiRowListParserKeys.videoIdPath,
        ) ??
        '';
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(
          mediaRecord,
          MultiRowListParserKeys.coverPath,
        ) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          MultiRowListParserKeys.titlePath,
        ) ??
        '';
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              mediaRecord,
              MultiRowListParserKeys.subtitleRunsPath,
            ) ??
            []) {
      secondaryText += textRun['text'];
    }
    mediaEntry.artist = secondaryText;
    await RecordSyncHelper.reconcileFileInfo(mediaEntry);
    return mediaEntry;
  }

  static Future<MediaCollection> decodeNavigationPlaylist(
    Map collectionRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    MediaCollection mediaCollectionLocal = MediaCollection(
      type: MediaCollectionShowType.twoRowPlaylist,
    );
    mediaCollectionLocal.playlistType =
        CollectionType.MUSIC_PAGE_TYPE_PLAYLIST.name;
    mediaCollectionLocal.id = ParserHelper.parse<String>(
      collectionRecord,
      NavigationButtonParserKeys.browseIdPath,
    );
    mediaCollectionLocal.params = ParserHelper.parse<String>(
      collectionRecord,
      NavigationButtonParserKeys.paramsPath,
    );
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          collectionRecord,
          NavigationButtonParserKeys.titlePath,
        ) ??
        '';
    mediaCollectionLocal.displayName = mediaCollectionLocal.name;
    await RecordSyncHelper.reconcileFileGroup(mediaCollectionLocal);
    return mediaCollectionLocal;
  }

  static Future<FileInfo> decodePanelVideo(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(
          mediaRecord,
          PanelVideoParserKeys.videoIdPath,
        ) ??
        '';
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(
          mediaRecord,
          PanelVideoParserKeys.coverPath,
        ) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          PanelVideoParserKeys.titlePath,
        ) ??
        '';
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              mediaRecord,
              PanelVideoParserKeys.subtitleRunsPath,
            ) ??
            []) {
      secondaryText += textRun['text'];
    }
    mediaEntry.artist = secondaryText;
    await RecordSyncHelper.reconcileFileInfo(mediaEntry);
    return mediaEntry;
  }

  static Future<PerformerDetails> decodeResponsiveListArtist(
    Map performerRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    PerformerDetails performerProfile = PerformerDetails();
    performerProfile.id = ParserHelper.parse<String>(
      performerRecord,
      ResponsiveListTowRowSharedParserKeys.browseIdPath,
    );
    performerProfile.thumbnail =
        ParserHelper.parse<String>(
          performerRecord,
          ResponsiveListParserKeys.coverPath,
        ) ??
        '';
    performerProfile.name =
        ParserHelper.parse<String>(
          performerRecord,
          ResponsiveListParserKeys.titlePath,
        ) ??
        "";
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              performerRecord,
              ResponsiveListParserKeys.subtitleRunsPath,
            ) ??
            []) {
      secondaryText += textRun['text'];
    }
    performerProfile.desc = secondaryText;
    await RecordSyncHelper.reconcileArtist(performerProfile);
    return performerProfile;
  }

  static Future<FileInfo> decodeResponsiveListMusic(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(
          mediaRecord,
          ResponsiveListParserKeys.videoIdPath,
        ) ??
        '';
    mediaEntry.type = ParserHelper.parse<String>(
      mediaRecord,
      ResponsiveListParserKeys.musicVideoTypePath,
    );
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(
          mediaRecord,
          ResponsiveListParserKeys.coverPath,
        ) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          ResponsiveListParserKeys.titlePath,
        ) ??
        '';
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              mediaRecord,
              ResponsiveListParserKeys.subtitleRunsPath,
            ) ??
            []) {
      secondaryText += textRun['text'];
    }
    mediaEntry.artist = secondaryText;
    await RecordSyncHelper.reconcileFileInfo(mediaEntry);
    return mediaEntry;
  }

  static Future<MediaCollection> decodeResponsiveListPlaylist(
    Map collectionRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    MediaCollection mediaCollectionLocal = MediaCollection();
    mediaCollectionLocal.id = ParserHelper.parse<String>(
      collectionRecord,
      ResponsiveListTowRowSharedParserKeys.browseIdPath,
    );
    mediaCollectionLocal.thumbnail =
        ParserHelper.parse<String>(
          collectionRecord,
          ResponsiveListParserKeys.coverPath,
        ) ??
        '';
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          collectionRecord,
          ResponsiveListParserKeys.titlePath,
        ) ??
        '';
    mediaCollectionLocal.displayName = mediaCollectionLocal.name;
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              collectionRecord,
              ResponsiveListParserKeys.subtitleRunsPath,
            ) ??
            []) {
      secondaryText += textRun['text'];
    }
    mediaCollectionLocal.detail = secondaryText;
    await RecordSyncHelper.reconcileFileGroup(mediaCollectionLocal);
    return mediaCollectionLocal;
  }

  ///解析单列表类的group（比如歌手主页的热门歌曲）
  static Future<MediaCollection> decodeShelfFileGroup(
    Map fileGroupMapArg, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    MediaCollection mediaCollectionLocal = MediaCollection(
      type: MediaCollectionShowType.listMusic,
    );
    mediaCollectionLocal.id = ParserHelper.parse<String>(
      fileGroupMapArg,
      ShelfParserKeys.groupIdPath,
    );
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          fileGroupMapArg,
          ShelfParserKeys.groupNamePath,
        ) ??
        '';
    mediaCollectionLocal.params = ParserHelper.parse<String>(
      fileGroupMapArg,
      ShelfParserKeys.groupParamsPath,
    );
    List childRecords = fileGroupMapArg[SharedParserKeys.childrenNode] ?? [];
    List childEntries = await decodeChildren(
      childRecords,
      mediaCollectionArg: mediaCollectionLocal,
      mediaOrigin: mediaOrigin,
    );
    mediaCollectionLocal.children = childEntries;
    return mediaCollectionLocal;
  }

  static Future<PerformerDetails> decodeTwoRowArtist(
    Map performerRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    PerformerDetails artistLocal = PerformerDetails();
    artistLocal.id = ParserHelper.parse<String>(
      performerRecord,
      ResponsiveListTowRowSharedParserKeys.browseIdPath,
    );
    artistLocal.thumbnail =
        ParserHelper.parse<String>(
          performerRecord,
          TwoRowParserKeys.coverPath,
        ) ??
        '';
    artistLocal.name =
        ParserHelper.parse<String>(
          performerRecord,
          TwoRowParserKeys.titlePath,
        ) ??
        '';
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              performerRecord,
              TwoRowParserKeys.subtitleRunsPath,
            ) ??
            []) {
      secondaryText += textRun['text'];
    }
    artistLocal.desc = secondaryText;
    await RecordSyncHelper.reconcileArtist(artistLocal);
    return artistLocal;
  }

  static Future<FileInfo> decodeTwoRowMusicVideo(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(mediaRecord, TwoRowParserKeys.videoIdPath) ??
        '';
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(mediaRecord, TwoRowParserKeys.coverPath) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(mediaRecord, TwoRowParserKeys.titlePath) ??
        '';
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              mediaRecord,
              TwoRowParserKeys.subtitleRunsPath,
            ) ??
            []) {
      secondaryText += textRun['text'];
    }
    mediaEntry.artist = secondaryText;
    await RecordSyncHelper.reconcileFileInfo(mediaEntry);
    return mediaEntry;
  }

  static Future<MediaCollection> decodeTwoRowPlaylist(
    Map collectionRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    MediaCollection mediaCollectionLocal = MediaCollection();
    mediaCollectionLocal.id = ParserHelper.parse<String>(
      collectionRecord,
      ResponsiveListTowRowSharedParserKeys.browseIdPath,
    );
    mediaCollectionLocal.thumbnail =
        ParserHelper.parse<String>(
          collectionRecord,
          TwoRowParserKeys.coverPath,
        ) ??
        '';
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          collectionRecord,
          TwoRowParserKeys.titlePath,
        ) ??
        '';
    mediaCollectionLocal.displayName = mediaCollectionLocal.name;
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              collectionRecord,
              TwoRowParserKeys.subtitleRunsPath,
            ) ??
            []) {
      secondaryText += textRun['text'];
    }
    mediaCollectionLocal.detail = secondaryText;
    await RecordSyncHelper.reconcileFileGroup(mediaCollectionLocal);
    return mediaCollectionLocal;
  }
}

class SharedParserKeys {
  static String childrenNode = 'contents';

  static List visitorDataPath = ['responseContext', 'visitorData'];
}

//单列表解析（如playlist详情页）
class ShelfParserKeys {
  static String shelfNode = 'musicShelfRenderer';
  static String playlistShelfNode = 'musicPlaylistShelfRenderer';

  //局部单列表的分组id（比如歌手列表的热门歌曲）
  static List groupIdPath = [
    'title',
    'runs',
    {ParserHelper.positionField: 0},
    'navigationEndpoint',
    'browseEndpoint',
    'browseId',
  ];

  //局部单列表的分组name（比如歌手列表的热门歌曲）
  static List groupNamePath = [
    'title',
    'runs',
    {ParserHelper.positionField: 0},
    'text',
  ];

  static List groupParamsPath = [
    'title',
    'runs',
    {ParserHelper.positionField: 0},
    'navigationEndpoint',
    'browseEndpoint',
    'params',
  ];
}

class TwoRowParserKeys {
  static String twoRowNode = 'musicTwoRowItemRenderer';

  static List musicVideoTypePath = [
    'navigationEndpoint',
    'watchEndpoint',
    'watchEndpointMusicSupportedConfigs',
    'watchEndpointMusicConfig',
    'musicVideoType',
  ];

  static List videoIdPath = ['navigationEndpoint', 'watchEndpoint', 'videoId'];

  static List coverPath = [
    'thumbnailRenderer',
    'musicThumbnailRenderer',
    'thumbnail',
    'thumbnails',
    {ParserHelper.positionField: 0},
    'url',
  ];

  static List titlePath = [
    'title',
    'runs',
    {ParserHelper.positionField: 0},
    'text',
  ];

  static List subtitleRunsPath = ['subtitle', 'runs'];
}
