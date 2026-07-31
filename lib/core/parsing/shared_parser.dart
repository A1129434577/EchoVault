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
  static String cardShelf = 'musicCardShelfRenderer';

  static List pageType = [
    'title',
    'runs',
    {ParserHelper.indexKey: 0},
    'navigationEndpoint',
    'browseEndpoint',
    'browseEndpointContextSupportedConfigs',
    'browseEndpointContextMusicConfig',
    'pageType',
  ];

  static List browseId = [
    'title',
    'runs',
    {ParserHelper.indexKey: 0},
    'navigationEndpoint',
    'browseEndpoint',
    'browseId',
  ];

  static List musicVideoType = [
    'title',
    'runs',
    {ParserHelper.indexKey: 0},
    'navigationEndpoint',
    'watchEndpoint',
    'watchEndpointMusicSupportedConfigs',
    'watchEndpointMusicConfig',
    'musicVideoType',
  ];

  static List videoId = [
    'title',
    'runs',
    {ParserHelper.indexKey: 0},
    'navigationEndpoint',
    'watchEndpoint',
    'videoId',
  ];

  static List cover = [
    'thumbnail',
    'musicThumbnailRenderer',
    'thumbnail',
    'thumbnails',
    {ParserHelper.indexKey: 0},
    'url',
  ];

  static List title = [
    'title',
    'runs',
    {ParserHelper.indexKey: 0},
    'text',
  ];

  static List subtitleRuns = ['subtitle', 'runs'];
}

//书架样式页面解析（如主页，歌手主页）
class CarouselShelfParserKeys {
  static String carouselShelf = 'musicCarouselShelfRenderer';

  static List groupId = [
    'header',
    'musicCarouselShelfBasicHeaderRenderer',
    'moreContentButton',
    'buttonRenderer',
    'navigationEndpoint',
    'browseEndpoint',
    'browseId',
  ];

  static List groupName = [
    'header',
    'musicCarouselShelfBasicHeaderRenderer',
    'title',
    'runs',
    {ParserHelper.indexKey: 0},
    'text',
  ];

  static List groupParams = [
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
  static String gird = 'gridRenderer';
  static List list = ['items'];
}

//类似播客解析
class MultiRowListParserKeys {
  static String multiRow = 'musicMultiRowListItemRenderer';

  static List musicVideoType = [
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

  static List videoId = [
    'overlay',
    'musicItemThumbnailOverlayRenderer',
    'content',
    'musicPlayButtonRenderer',
    'playNavigationEndpoint',
    'watchEndpoint',
    'videoId',
  ];

  static List cover = [
    'thumbnail',
    'musicThumbnailRenderer',
    'thumbnail',
    'thumbnails',
    {ParserHelper.indexKey: 1},
    'url',
  ];

  static List title = [
    'title',
    'runs',
    {ParserHelper.indexKey: 0},
    'text',
  ];

  static List subtitleRuns = ['subtitle', 'runs'];
}

//比如首页为你推荐的精选播放列表
class NavigationButtonParserKeys {
  static List sectionTitle = [
    'header',
    'gridHeaderRenderer',
    'title',
    'runs',
    {ParserHelper.indexKey: 0},
    'text',
  ];

  static String navigation = 'musicNavigationButtonRenderer';

  //局部单列表的分组id（比如歌手列表的热门歌曲）
  static List browseId = ['clickCommand', 'browseEndpoint', 'browseId'];

  //局部单列表的分组name（比如歌手列表的热门歌曲）
  static List title = [
    'buttonText',
    'runs',
    {ParserHelper.indexKey: 0},
    'text',
  ];

  static List params = ['clickCommand', 'browseEndpoint', 'params'];
}

//接下来播放解析
class PanelVideoParserKeys {
  static String panel = 'playlistPanelVideoRenderer';

  static List musicVideoType = [
    'navigationEndpoint',
    'watchEndpoint',
    'watchEndpointMusicSupportedConfigs',
    'watchEndpointMusicConfig',
    'musicVideoType',
  ];

  static List videoId = ['videoId'];

  static List cover = [
    'thumbnail',
    'thumbnails',
    {ParserHelper.indexKey: 1},
    'url',
  ];

  static List title = [
    'title',
    'runs',
    {ParserHelper.indexKey: 0},
    'text',
  ];

  static List subtitleRuns = ['longBylineText', 'runs'];
}

class ResponsiveListParserKeys {
  static String responsiveList = 'musicResponsiveListItemRenderer';

  static List musicVideoType = [
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

  static List videoId = ['playlistItemData', 'videoId'];

  static List cover = [
    'thumbnail',
    'musicThumbnailRenderer',
    'thumbnail',
    'thumbnails',
    {ParserHelper.indexKey: 1},
    'url',
  ];

  static List title = [
    'flexColumns',
    {ParserHelper.indexKey: 0},
    'musicResponsiveListItemFlexColumnRenderer',
    'text',
    'runs',
    {ParserHelper.indexKey: 0},
    'text',
  ];
  static List subtitleRuns = [
    'flexColumns',
    {ParserHelper.indexKey: 1},
    'musicResponsiveListItemFlexColumnRenderer',
    'text',
    'runs',
  ];
}

class ResponsiveListTowRowSharedParserKeys {
  static List pageType = [
    'navigationEndpoint',
    'browseEndpoint',
    'browseEndpointContextSupportedConfigs',
    'browseEndpointContextMusicConfig',
    'pageType',
  ];
  static List browseId = ['navigationEndpoint', 'browseEndpoint', 'browseId'];
}

///类似主页样式分组列表解析参数
class SectionListParserKeys {
  //翻页参数
  static List initContinuation = [
    'contents',
    'singleColumnBrowseResultsRenderer',
    'tabs',
    {ParserHelper.indexKey: 0},
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'continuations',
    {ParserHelper.indexKey: 0},
    'nextContinuationData',
    'continuation',
  ];

  //翻页参数
  static List moreContinuation = [
    'continuationContents',
    'sectionListContinuation',
    'continuations',
    {ParserHelper.indexKey: 0},
    'nextContinuationData',
    'continuation',
  ];

  //如果这个不为空说明不可用
  static List itemSectionRenderer = [
    'contents',
    'singleColumnBrowseResultsRenderer',
    'tabs',
    {ParserHelper.indexKey: 0},
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'contents',
    {ParserHelper.filterKey: 'itemSectionRenderer'},
  ];

  //翻页第一页数据列表
  static List initResourceList = [
    'contents',
    'singleColumnBrowseResultsRenderer',
    'tabs',
    {ParserHelper.indexKey: 0},
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'contents',
  ];

  //翻页更多页数据列表
  static List moreResourceList = [
    'continuationContents',
    'sectionListContinuation',
    'contents',
  ];

  //点击右侧更多之后的数据列表
  static List tapMoreResourceList = [
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
      CardShelfParserKeys.browseId,
    );
    artistLocal.thumbnail =
        ParserHelper.parse<String>(
          performerRecord,
          CardShelfParserKeys.cover,
        ) ??
        '';
    artistLocal.name =
        ParserHelper.parse<String>(
          performerRecord,
          CardShelfParserKeys.title,
        ) ??
        '';
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              performerRecord,
              CardShelfParserKeys.subtitleRuns,
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
        ParserHelper.parse<String>(mediaRecord, CardShelfParserKeys.videoId) ??
        '';
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(mediaRecord, CardShelfParserKeys.cover) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(mediaRecord, CardShelfParserKeys.title) ??
        '';
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              mediaRecord,
              CardShelfParserKeys.subtitleRuns,
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
      CardShelfParserKeys.browseId,
    );
    mediaCollectionLocal.thumbnail =
        ParserHelper.parse<String>(
          collectionRecord,
          CardShelfParserKeys.cover,
        ) ??
        '';
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          collectionRecord,
          CardShelfParserKeys.title,
        ) ??
        "";
    mediaCollectionLocal.displayName = mediaCollectionLocal.name;
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              collectionRecord,
              CardShelfParserKeys.subtitleRuns,
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
      CarouselShelfParserKeys.groupId,
    );
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          fileGroupMapArg,
          CarouselShelfParserKeys.groupName,
        ) ??
        '';
    mediaCollectionLocal.params = ParserHelper.parse<String>(
      fileGroupMapArg,
      CarouselShelfParserKeys.groupParams,
    );
    List childRecords = fileGroupMapArg[SharedParserKeys.children] ?? [];
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
      if (childrenMap.containsKey(ResponsiveListParserKeys.responsiveList)) {
        Map nestedRecord = childrenMap[ResponsiveListParserKeys.responsiveList];
        String? playlistTypeLocal = ParserHelper.parse<String>(
          nestedRecord,
          ResponsiveListTowRowSharedParserKeys.pageType,
        );
        String? mediaId = ParserHelper.parse<String>(
          nestedRecord,
          ResponsiveListParserKeys.videoId,
        );
        if (playlistTypeLocal != null) {
          if (playlistTypeLocal == PerformerDetails.ytmTypeName) {
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
      } else if (childrenMap.containsKey(TwoRowParserKeys.twoRow)) {
        Map nestedRecord = childrenMap[TwoRowParserKeys.twoRow];
        String? playlistTypeLocal = ParserHelper.parse<String>(
          nestedRecord,
          ResponsiveListTowRowSharedParserKeys.pageType,
        );
        String? videoTypeLocal = ParserHelper.parse<String>(
          nestedRecord,
          TwoRowParserKeys.musicVideoType,
        );
        if (playlistTypeLocal != null) {
          if (playlistTypeLocal == PerformerDetails.ytmTypeName) {
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
      } else if (childrenMap.containsKey(CardShelfParserKeys.cardShelf)) {
        Map nestedRecord = childrenMap[CardShelfParserKeys.cardShelf];
        String? playlistTypeLocal = ParserHelper.parse<String>(
          nestedRecord,
          CardShelfParserKeys.pageType,
        );
        String? videoTypeLocal = ParserHelper.parse<String>(
          nestedRecord,
          CardShelfParserKeys.musicVideoType,
        );
        if (playlistTypeLocal != null) {
          if (playlistTypeLocal == PerformerDetails.ytmTypeName) {
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
      } else if (childrenMap.containsKey(MultiRowListParserKeys.multiRow)) {
        Map nestedRecord = childrenMap[MultiRowListParserKeys.multiRow];
        String? videoTypeLocal = ParserHelper.parse<String>(
          nestedRecord,
          MultiRowListParserKeys.musicVideoType,
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
      } else if (childrenMap.containsKey(PanelVideoParserKeys.panel)) {
        Map nestedRecord = childrenMap[PanelVideoParserKeys.panel];
        String? videoTypeLocal = ParserHelper.parse<String>(
          nestedRecord,
          PanelVideoParserKeys.musicVideoType,
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
        NavigationButtonParserKeys.navigation,
      )) {
        Map nestedRecord = childrenMap[NavigationButtonParserKeys.navigation];
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
      if (groupMap.containsKey(CarouselShelfParserKeys.carouselShelf)) {
        groupMap = groupMap[CarouselShelfParserKeys.carouselShelf];
        MediaCollection mediaCollectionLocal =
            await SharedParser.decodeCarouselShelfFileGroup(
              groupMap,
              mediaOrigin: mediaOrigin,
            );
        entries.add(mediaCollectionLocal);
      } else if (groupMap.containsKey(ShelfParserKeys.shelf)) {
        //多类型中夹杂的单列表，有group的title、name等
        groupMap = groupMap[ShelfParserKeys.shelf];
        MediaCollection mediaCollectionLocal =
            await SharedParser.decodeShelfFileGroup(
              groupMap,
              mediaOrigin: mediaOrigin,
            );
        entries.add(mediaCollectionLocal);
      } else if (groupMap.containsKey(ShelfParserKeys.playlistShelf)) {
        //纯单列表无group的title、name等
        groupMap = groupMap[ShelfParserKeys.playlistShelf];
        MediaCollection mediaCollectionLocal = MediaCollection(
          type: MediaCollectionShowType.listMusic,
        );
        List childRecords = groupMap[SharedParserKeys.children] ?? [];
        List childEntries = await decodeChildren(
          childRecords,
          mediaOrigin: mediaOrigin,
        );
        mediaCollectionLocal.children = childEntries;
        entries.add(mediaCollectionLocal);
      } else if (groupMap.containsKey(GridRendererParserKeys.gird)) {
        groupMap = groupMap[GridRendererParserKeys.gird];
        String? nameLocal = ParserHelper.parse<String>(
          groupMap,
          NavigationButtonParserKeys.sectionTitle,
        );
        MediaCollection mediaCollectionLocal = MediaCollection(
          type: nameLocal != null
              ? MediaCollectionShowType.twoRowPlaylist
              : MediaCollectionShowType.grid,
        );
        mediaCollectionLocal.name = nameLocal ?? '';
        List childRecords =
            ParserHelper.parse<List>(groupMap, GridRendererParserKeys.list) ??
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
          MultiRowListParserKeys.videoId,
        ) ??
        '';
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(mediaRecord, MultiRowListParserKeys.cover) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(mediaRecord, MultiRowListParserKeys.title) ??
        '';
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              mediaRecord,
              MultiRowListParserKeys.subtitleRuns,
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
      NavigationButtonParserKeys.browseId,
    );
    mediaCollectionLocal.params = ParserHelper.parse<String>(
      collectionRecord,
      NavigationButtonParserKeys.params,
    );
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          collectionRecord,
          NavigationButtonParserKeys.title,
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
        ParserHelper.parse<String>(mediaRecord, PanelVideoParserKeys.videoId) ??
        '';
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(mediaRecord, PanelVideoParserKeys.cover) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(mediaRecord, PanelVideoParserKeys.title) ??
        '';
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              mediaRecord,
              PanelVideoParserKeys.subtitleRuns,
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
      ResponsiveListTowRowSharedParserKeys.browseId,
    );
    performerProfile.thumbnail =
        ParserHelper.parse<String>(
          performerRecord,
          ResponsiveListParserKeys.cover,
        ) ??
        '';
    performerProfile.name =
        ParserHelper.parse<String>(
          performerRecord,
          ResponsiveListParserKeys.title,
        ) ??
        "";
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              performerRecord,
              ResponsiveListParserKeys.subtitleRuns,
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
          ResponsiveListParserKeys.videoId,
        ) ??
        '';
    mediaEntry.type = ParserHelper.parse<String>(
      mediaRecord,
      ResponsiveListParserKeys.musicVideoType,
    );
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(
          mediaRecord,
          ResponsiveListParserKeys.cover,
        ) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          ResponsiveListParserKeys.title,
        ) ??
        '';
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              mediaRecord,
              ResponsiveListParserKeys.subtitleRuns,
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
      ResponsiveListTowRowSharedParserKeys.browseId,
    );
    mediaCollectionLocal.thumbnail =
        ParserHelper.parse<String>(
          collectionRecord,
          ResponsiveListParserKeys.cover,
        ) ??
        '';
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          collectionRecord,
          ResponsiveListParserKeys.title,
        ) ??
        '';
    mediaCollectionLocal.displayName = mediaCollectionLocal.name;
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              collectionRecord,
              ResponsiveListParserKeys.subtitleRuns,
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
      ShelfParserKeys.groupId,
    );
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          fileGroupMapArg,
          ShelfParserKeys.groupName,
        ) ??
        '';
    mediaCollectionLocal.params = ParserHelper.parse<String>(
      fileGroupMapArg,
      ShelfParserKeys.groupParams,
    );
    List childRecords = fileGroupMapArg[SharedParserKeys.children] ?? [];
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
      ResponsiveListTowRowSharedParserKeys.browseId,
    );
    artistLocal.thumbnail =
        ParserHelper.parse<String>(performerRecord, TwoRowParserKeys.cover) ??
        '';
    artistLocal.name =
        ParserHelper.parse<String>(performerRecord, TwoRowParserKeys.title) ??
        '';
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              performerRecord,
              TwoRowParserKeys.subtitleRuns,
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
        ParserHelper.parse<String>(mediaRecord, TwoRowParserKeys.videoId) ?? '';
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(mediaRecord, TwoRowParserKeys.cover) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(mediaRecord, TwoRowParserKeys.title) ?? '';
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              mediaRecord,
              TwoRowParserKeys.subtitleRuns,
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
      ResponsiveListTowRowSharedParserKeys.browseId,
    );
    mediaCollectionLocal.thumbnail =
        ParserHelper.parse<String>(collectionRecord, TwoRowParserKeys.cover) ??
        '';
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(collectionRecord, TwoRowParserKeys.title) ??
        '';
    mediaCollectionLocal.displayName = mediaCollectionLocal.name;
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              collectionRecord,
              TwoRowParserKeys.subtitleRuns,
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
  static String children = 'contents';

  static List visitorData = ['responseContext', 'visitorData'];
}

//单列表解析（如playlist详情页）
class ShelfParserKeys {
  static String shelf = 'musicShelfRenderer';
  static String playlistShelf = 'musicPlaylistShelfRenderer';

  //局部单列表的分组id（比如歌手列表的热门歌曲）
  static List groupId = [
    'title',
    'runs',
    {ParserHelper.indexKey: 0},
    'navigationEndpoint',
    'browseEndpoint',
    'browseId',
  ];

  //局部单列表的分组name（比如歌手列表的热门歌曲）
  static List groupName = [
    'title',
    'runs',
    {ParserHelper.indexKey: 0},
    'text',
  ];

  static List groupParams = [
    'title',
    'runs',
    {ParserHelper.indexKey: 0},
    'navigationEndpoint',
    'browseEndpoint',
    'params',
  ];
}

class TwoRowParserKeys {
  static String twoRow = 'musicTwoRowItemRenderer';

  static List musicVideoType = [
    'navigationEndpoint',
    'watchEndpoint',
    'watchEndpointMusicSupportedConfigs',
    'watchEndpointMusicConfig',
    'musicVideoType',
  ];

  static List videoId = ['navigationEndpoint', 'watchEndpoint', 'videoId'];

  static List cover = [
    'thumbnailRenderer',
    'musicThumbnailRenderer',
    'thumbnail',
    'thumbnails',
    {ParserHelper.indexKey: 0},
    'url',
  ];

  static List title = [
    'title',
    'runs',
    {ParserHelper.indexKey: 0},
    'text',
  ];

  static List subtitleRuns = ['subtitle', 'runs'];
}
