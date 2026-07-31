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

class SharedParser {
  static Future<List<MediaCollection>> parseContents(
    List groupMapList, {
    MediaSourceInterface? source,
  }) async {
    List<MediaCollection> list = [];
    for (Map groupMap in groupMapList) {
      if (groupMap.containsKey(CarouselShelfParserKeys.carouselShelf)) {
        groupMap = groupMap[CarouselShelfParserKeys.carouselShelf];
        MediaCollection mediaCollection =
            await SharedParser.parseCarouselShelfFileGroup(
              groupMap,
              source: source,
            );
        list.add(mediaCollection);
      } else if (groupMap.containsKey(ShelfParserKeys.shelf)) {
        //多类型中夹杂的单列表，有group的title、name等
        groupMap = groupMap[ShelfParserKeys.shelf];
        MediaCollection mediaCollection =
            await SharedParser.parseShelfFileGroup(groupMap, source: source);
        list.add(mediaCollection);
      } else if (groupMap.containsKey(ShelfParserKeys.playlistShelf)) {
        //纯单列表无group的title、name等
        groupMap = groupMap[ShelfParserKeys.playlistShelf];
        MediaCollection mediaCollection = MediaCollection(
          type: MediaCollectionShowType.listMusic,
        );
        List childrenMapList = groupMap[SharedParserKeys.children] ?? [];
        List children = await parseChildren(childrenMapList, source: source);
        mediaCollection.children = children;
        list.add(mediaCollection);
      } else if (groupMap.containsKey(GridRendererParserKeys.gird)) {
        groupMap = groupMap[GridRendererParserKeys.gird];
        String? name = ParserHelper.parse<String>(
          groupMap,
          NavigationButtonParserKeys.sectionTitle,
        );
        MediaCollection mediaCollection = MediaCollection(
          type: name != null
              ? MediaCollectionShowType.twoRowPlaylist
              : MediaCollectionShowType.grid,
        );
        mediaCollection.name = name ?? '';
        List childrenMapList =
            ParserHelper.parse<List>(groupMap, GridRendererParserKeys.items) ??
            [];
        List children = await parseChildren(childrenMapList, source: source);
        mediaCollection.children = children;
        list.add(mediaCollection);
      }
    }
    return list;
  }

  ///解析书架样式的group(比如主页数据)
  static Future<MediaCollection> parseCarouselShelfFileGroup(
    Map fileGroupMap, {
    MediaSourceInterface? source,
  }) async {
    MediaCollection mediaCollection = MediaCollection();
    mediaCollection.id = ParserHelper.parse<String>(
      fileGroupMap,
      CarouselShelfParserKeys.groupId,
    );
    mediaCollection.name =
        ParserHelper.parse<String>(
          fileGroupMap,
          CarouselShelfParserKeys.groupName,
        ) ??
        '';
    mediaCollection.params = ParserHelper.parse<String>(
      fileGroupMap,
      CarouselShelfParserKeys.groupParams,
    );
    List childrenMapList = fileGroupMap[SharedParserKeys.children] ?? [];
    List children = await parseChildren(
      childrenMapList,
      mediaCollection: mediaCollection,
      source: source,
    );

    if (mediaCollection.type == null) {
      //剔除itemList中的的另类(比如大多是是视频里出现了一个playlist)
      List<FileInfo> fileList = children.whereType<FileInfo>().toList();
      List<MediaCollection> playlistList = children
          .whereType<MediaCollection>()
          .toList();
      List<PerformerDetails> performers = children
          .whereType<PerformerDetails>()
          .toList();
      if (fileList.length >= playlistList.length &&
          fileList.length >= performers.length) {
        mediaCollection.type = MediaCollectionShowType.twoRowVideo;
        children = fileList;
      } else if (playlistList.length >= fileList.length &&
          playlistList.length >= performers.length) {
        mediaCollection.type = MediaCollectionShowType.twoRowPlaylist;
        children = playlistList;
      } else {
        mediaCollection.type = MediaCollectionShowType.twoRowArtist;
        children = performers;
      }
    }
    mediaCollection.children = children;
    return mediaCollection;
  }

  ///解析单列表类的group（比如歌手主页的热门歌曲）
  static Future<MediaCollection> parseShelfFileGroup(
    Map fileGroupMap, {
    MediaSourceInterface? source,
  }) async {
    MediaCollection mediaCollection = MediaCollection(
      type: MediaCollectionShowType.listMusic,
    );
    mediaCollection.id = ParserHelper.parse<String>(
      fileGroupMap,
      ShelfParserKeys.groupId,
    );
    mediaCollection.name =
        ParserHelper.parse<String>(fileGroupMap, ShelfParserKeys.groupName) ??
        '';
    mediaCollection.params = ParserHelper.parse<String>(
      fileGroupMap,
      ShelfParserKeys.groupParams,
    );
    List childrenMapList = fileGroupMap[SharedParserKeys.children] ?? [];
    List children = await parseChildren(
      childrenMapList,
      mediaCollection: mediaCollection,
      source: source,
    );
    mediaCollection.children = children;
    return mediaCollection;
  }

  static Future<List> parseChildren(
    List childrenMapList, {
    MediaCollection? mediaCollection,
    MediaSourceInterface? source,
  }) async {
    List children = [];
    for (final childrenMap in childrenMapList) {
      if (childrenMap.containsKey(ResponsiveListParserKeys.responsiveList)) {
        Map childMap = childrenMap[ResponsiveListParserKeys.responsiveList];
        String? playlistType = ParserHelper.parse<String>(
          childMap,
          ResponsiveListTowRowSharedParserKeys.pageType,
        );
        String? videoId = ParserHelper.parse<String>(
          childMap,
          ResponsiveListParserKeys.videoId,
        );
        if (playlistType != null) {
          if (playlistType == PerformerDetails.ytmTypeName) {
            mediaCollection?.type = MediaCollectionShowType.twoRowArtist;
            PerformerDetails artist = await parseResponsiveListArtist(
              childMap,
              source: source,
            );
            children.add(artist);
          } else {
            mediaCollection?.type = MediaCollectionShowType.twoRowPlaylist;
            MediaCollection playlist = await parseResponsiveListPlaylist(
              childMap,
              source: source,
            );
            playlist.playlistType = playlistType;
            children.add(playlist);
          }
        } else if (videoId != null) {
          //这里注意一下：如果已经作为Shelf单列表样式展示了就不再使用其他样式
          mediaCollection?.type ??= MediaCollectionShowType.responsiveListMusic;
          FileInfo mediaDetails = await parseResponsiveListMusic(
            childMap,
            source: source,
          );
          //B面parentId只用于埋点，无其他实际逻辑
          mediaDetails.parentId = mediaCollection?.name;
          children.add(mediaDetails);
        }
      } else if (childrenMap.containsKey(TwoRowParserKeys.twoRow)) {
        Map childMap = childrenMap[TwoRowParserKeys.twoRow];
        String? playlistType = ParserHelper.parse<String>(
          childMap,
          ResponsiveListTowRowSharedParserKeys.pageType,
        );
        String? videoType = ParserHelper.parse<String>(
          childMap,
          TwoRowParserKeys.musicVideoType,
        );
        if (playlistType != null) {
          if (playlistType == PerformerDetails.ytmTypeName) {
            PerformerDetails artist = await parseTwoRowArtist(
              childMap,
              source: source,
            );
            children.add(artist);
          } else {
            MediaCollection playlist = await parseTwoRowPlaylist(
              childMap,
              source: source,
            );
            playlist.playlistType = playlistType;
            children.add(playlist);
          }
        } else if (videoType != null) {
          FileInfo mediaDetails = await parseTwoRowMusicVideo(
            childMap,
            source: source,
          );
          mediaDetails.type = videoType;
          //B面parentId只用于埋点，无其他实际逻辑
          mediaDetails.parentId = mediaCollection?.name;
          children.add(mediaDetails);
        }
      } else if (childrenMap.containsKey(CardShelfParserKeys.cardShelf)) {
        Map childMap = childrenMap[CardShelfParserKeys.cardShelf];
        String? playlistType = ParserHelper.parse<String>(
          childMap,
          CardShelfParserKeys.pageType,
        );
        String? videoType = ParserHelper.parse<String>(
          childMap,
          CardShelfParserKeys.musicVideoType,
        );
        if (playlistType != null) {
          if (playlistType == PerformerDetails.ytmTypeName) {
            PerformerDetails artist = await parseCardArtist(
              childMap,
              source: source,
            );
            children.add(artist);
          } else {
            MediaCollection playlist = await parseCardPlaylist(
              childMap,
              source: source,
            );
            playlist.playlistType = playlistType;
            children.add(playlist);
          }
        } else if (videoType != null) {
          FileInfo mediaDetails = await parseCardMusicVideo(
            childMap,
            source: source,
          );
          mediaDetails.type = videoType;
          //B面parentId只用于埋点，无其他实际逻辑
          mediaDetails.parentId = mediaCollection?.name;
          children.add(mediaDetails);
        }
      } else if (childrenMap.containsKey(MultiRowListParserKeys.multiRow)) {
        Map childMap = childrenMap[MultiRowListParserKeys.multiRow];
        String? videoType = ParserHelper.parse<String>(
          childMap,
          MultiRowListParserKeys.musicVideoType,
        );
        if (videoType != null) {
          FileInfo mediaDetails = await parseMultiRowMusicVideo(
            childMap,
            source: source,
          );
          mediaDetails.type = videoType;
          //B面parentId只用于埋点，无其他实际逻辑
          mediaDetails.parentId = mediaCollection?.name;
          children.add(mediaDetails);
        }
      } else if (childrenMap.containsKey(PanelVideoParserKeys.panel)) {
        Map childMap = childrenMap[PanelVideoParserKeys.panel];
        String? videoType = ParserHelper.parse<String>(
          childMap,
          PanelVideoParserKeys.musicVideoType,
        );
        if (videoType != null) {
          FileInfo mediaDetails = await parsePanelVideo(
            childMap,
            source: source,
          );
          mediaDetails.type = videoType;
          //B面parentId只用于埋点，无其他实际逻辑
          mediaDetails.parentId = mediaCollection?.name;
          children.add(mediaDetails);
        }
      } else if (childrenMap.containsKey(
        NavigationButtonParserKeys.navigation,
      )) {
        Map childMap = childrenMap[NavigationButtonParserKeys.navigation];
        MediaCollection playlist = await parseNavigationPlaylist(
          childMap,
          source: source,
        );
        children.add(playlist);
      }
    }
    return children;
  }

  static Future<FileInfo> parseResponsiveListMusic(
    Map fileInfoMap, {
    MediaSourceInterface? source,
  }) async {
    FileInfo mediaDetails = FileInfo(extension: 'mp4', source: source);
    mediaDetails.fileId =
        ParserHelper.parse<String>(
          fileInfoMap,
          ResponsiveListParserKeys.videoId,
        ) ??
        '';
    mediaDetails.type = ParserHelper.parse<String>(
      fileInfoMap,
      ResponsiveListParserKeys.musicVideoType,
    );
    mediaDetails.thumbnail =
        ParserHelper.parse<String>(
          fileInfoMap,
          ResponsiveListParserKeys.cover,
        ) ??
        'https://i.ytimg.com/vi/${mediaDetails.fileId}/default.jpg';
    mediaDetails.name =
        ParserHelper.parse<String>(
          fileInfoMap,
          ResponsiveListParserKeys.title,
        ) ??
        '';
    String subtitle = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              fileInfoMap,
              ResponsiveListParserKeys.subtitleRuns,
            ) ??
            []) {
      subtitle += textRun['text'];
    }
    mediaDetails.artist = subtitle;
    await RecordSyncHelper.syncFileInfo(mediaDetails);
    return mediaDetails;
  }

  static Future<PerformerDetails> parseResponsiveListArtist(
    Map artistMap, {
    MediaSourceInterface? source,
  }) async {
    PerformerDetails performerDetails = PerformerDetails();
    performerDetails.id = ParserHelper.parse<String>(
      artistMap,
      ResponsiveListTowRowSharedParserKeys.browseId,
    );
    performerDetails.thumbnail =
        ParserHelper.parse<String>(artistMap, ResponsiveListParserKeys.cover) ??
        '';
    performerDetails.name =
        ParserHelper.parse<String>(artistMap, ResponsiveListParserKeys.title) ??
        "";
    String subtitle = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              artistMap,
              ResponsiveListParserKeys.subtitleRuns,
            ) ??
            []) {
      subtitle += textRun['text'];
    }
    performerDetails.desc = subtitle;
    await RecordSyncHelper.syncArtist(performerDetails);
    return performerDetails;
  }

  static Future<MediaCollection> parseResponsiveListPlaylist(
    Map playlistMap, {
    MediaSourceInterface? source,
  }) async {
    MediaCollection mediaCollection = MediaCollection();
    mediaCollection.id = ParserHelper.parse<String>(
      playlistMap,
      ResponsiveListTowRowSharedParserKeys.browseId,
    );
    mediaCollection.thumbnail =
        ParserHelper.parse<String>(
          playlistMap,
          ResponsiveListParserKeys.cover,
        ) ??
        '';
    mediaCollection.name =
        ParserHelper.parse<String>(
          playlistMap,
          ResponsiveListParserKeys.title,
        ) ??
        '';
    mediaCollection.displayName = mediaCollection.name;
    String subtitle = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              playlistMap,
              ResponsiveListParserKeys.subtitleRuns,
            ) ??
            []) {
      subtitle += textRun['text'];
    }
    mediaCollection.detail = subtitle;
    await RecordSyncHelper.syncFileGroup(mediaCollection);
    return mediaCollection;
  }

  static Future<FileInfo> parseTwoRowMusicVideo(
    Map fileInfoMap, {
    MediaSourceInterface? source,
  }) async {
    FileInfo mediaDetails = FileInfo(extension: 'mp4', source: source);
    mediaDetails.fileId =
        ParserHelper.parse<String>(fileInfoMap, TwoRowParserKeys.videoId) ?? '';
    mediaDetails.thumbnail =
        ParserHelper.parse<String>(fileInfoMap, TwoRowParserKeys.cover) ??
        'https://i.ytimg.com/vi/${mediaDetails.fileId}/default.jpg';
    mediaDetails.name =
        ParserHelper.parse<String>(fileInfoMap, TwoRowParserKeys.title) ?? '';
    String subtitle = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              fileInfoMap,
              TwoRowParserKeys.subtitleRuns,
            ) ??
            []) {
      subtitle += textRun['text'];
    }
    mediaDetails.artist = subtitle;
    await RecordSyncHelper.syncFileInfo(mediaDetails);
    return mediaDetails;
  }

  static Future<PerformerDetails> parseTwoRowArtist(
    Map artistMap, {
    MediaSourceInterface? source,
  }) async {
    PerformerDetails artist = PerformerDetails();
    artist.id = ParserHelper.parse<String>(
      artistMap,
      ResponsiveListTowRowSharedParserKeys.browseId,
    );
    artist.thumbnail =
        ParserHelper.parse<String>(artistMap, TwoRowParserKeys.cover) ?? '';
    artist.name =
        ParserHelper.parse<String>(artistMap, TwoRowParserKeys.title) ?? '';
    String subtitle = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              artistMap,
              TwoRowParserKeys.subtitleRuns,
            ) ??
            []) {
      subtitle += textRun['text'];
    }
    artist.desc = subtitle;
    await RecordSyncHelper.syncArtist(artist);
    return artist;
  }

  static Future<MediaCollection> parseTwoRowPlaylist(
    Map playlistMap, {
    MediaSourceInterface? source,
  }) async {
    MediaCollection mediaCollection = MediaCollection();
    mediaCollection.id = ParserHelper.parse<String>(
      playlistMap,
      ResponsiveListTowRowSharedParserKeys.browseId,
    );
    mediaCollection.thumbnail =
        ParserHelper.parse<String>(playlistMap, TwoRowParserKeys.cover) ?? '';
    mediaCollection.name =
        ParserHelper.parse<String>(playlistMap, TwoRowParserKeys.title) ?? '';
    mediaCollection.displayName = mediaCollection.name;
    String subtitle = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              playlistMap,
              TwoRowParserKeys.subtitleRuns,
            ) ??
            []) {
      subtitle += textRun['text'];
    }
    mediaCollection.detail = subtitle;
    await RecordSyncHelper.syncFileGroup(mediaCollection);
    return mediaCollection;
  }

  static Future<FileInfo> parseCardMusicVideo(
    Map fileInfoMap, {
    MediaSourceInterface? source,
  }) async {
    FileInfo mediaDetails = FileInfo(extension: 'mp4', source: source);
    mediaDetails.fileId =
        ParserHelper.parse<String>(fileInfoMap, CardShelfParserKeys.videoId) ??
        '';
    mediaDetails.thumbnail =
        ParserHelper.parse<String>(fileInfoMap, CardShelfParserKeys.cover) ??
        'https://i.ytimg.com/vi/${mediaDetails.fileId}/default.jpg';
    mediaDetails.name =
        ParserHelper.parse<String>(fileInfoMap, CardShelfParserKeys.title) ??
        '';
    String subtitle = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              fileInfoMap,
              CardShelfParserKeys.subtitleRuns,
            ) ??
            []) {
      subtitle += textRun['text'];
    }
    mediaDetails.artist = subtitle;
    await RecordSyncHelper.syncFileInfo(mediaDetails);
    return mediaDetails;
  }

  static Future<PerformerDetails> parseCardArtist(
    Map artistMap, {
    MediaSourceInterface? source,
  }) async {
    PerformerDetails artist = PerformerDetails();
    artist.id = ParserHelper.parse<String>(
      artistMap,
      CardShelfParserKeys.browseId,
    );
    artist.thumbnail =
        ParserHelper.parse<String>(artistMap, CardShelfParserKeys.cover) ?? '';
    artist.name =
        ParserHelper.parse<String>(artistMap, CardShelfParserKeys.title) ?? '';
    String subtitle = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              artistMap,
              CardShelfParserKeys.subtitleRuns,
            ) ??
            []) {
      subtitle += textRun['text'];
    }
    artist.desc = subtitle;
    await RecordSyncHelper.syncArtist(artist);
    return artist;
  }

  static Future<MediaCollection> parseCardPlaylist(
    Map playlistMap, {
    MediaSourceInterface? source,
  }) async {
    MediaCollection mediaCollection = MediaCollection();
    mediaCollection.id = ParserHelper.parse<String>(
      playlistMap,
      CardShelfParserKeys.browseId,
    );
    mediaCollection.thumbnail =
        ParserHelper.parse<String>(playlistMap, CardShelfParserKeys.cover) ??
        '';
    mediaCollection.name =
        ParserHelper.parse<String>(playlistMap, CardShelfParserKeys.title) ??
        "";
    mediaCollection.displayName = mediaCollection.name;
    String subtitle = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              playlistMap,
              CardShelfParserKeys.subtitleRuns,
            ) ??
            []) {
      subtitle += textRun['text'];
    }
    mediaCollection.detail = subtitle;
    await RecordSyncHelper.syncFileGroup(mediaCollection);
    return mediaCollection;
  }

  static Future<FileInfo> parseMultiRowMusicVideo(
    Map fileInfoMap, {
    MediaSourceInterface? source,
  }) async {
    FileInfo mediaDetails = FileInfo(extension: 'mp4', source: source);
    mediaDetails.fileId =
        ParserHelper.parse<String>(
          fileInfoMap,
          MultiRowListParserKeys.videoId,
        ) ??
        '';
    mediaDetails.thumbnail =
        ParserHelper.parse<String>(fileInfoMap, MultiRowListParserKeys.cover) ??
        'https://i.ytimg.com/vi/${mediaDetails.fileId}/default.jpg';
    mediaDetails.name =
        ParserHelper.parse<String>(fileInfoMap, MultiRowListParserKeys.title) ??
        '';
    String subtitle = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              fileInfoMap,
              MultiRowListParserKeys.subtitleRuns,
            ) ??
            []) {
      subtitle += textRun['text'];
    }
    mediaDetails.artist = subtitle;
    await RecordSyncHelper.syncFileInfo(mediaDetails);
    return mediaDetails;
  }

  static Future<FileInfo> parsePanelVideo(
    Map fileInfoMap, {
    MediaSourceInterface? source,
  }) async {
    FileInfo mediaDetails = FileInfo(extension: 'mp4', source: source);
    mediaDetails.fileId =
        ParserHelper.parse<String>(fileInfoMap, PanelVideoParserKeys.videoId) ??
        '';
    mediaDetails.thumbnail =
        ParserHelper.parse<String>(fileInfoMap, PanelVideoParserKeys.cover) ??
        'https://i.ytimg.com/vi/${mediaDetails.fileId}/default.jpg';
    mediaDetails.name =
        ParserHelper.parse<String>(fileInfoMap, PanelVideoParserKeys.title) ??
        '';
    String subtitle = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              fileInfoMap,
              PanelVideoParserKeys.subtitleRuns,
            ) ??
            []) {
      subtitle += textRun['text'];
    }
    mediaDetails.artist = subtitle;
    await RecordSyncHelper.syncFileInfo(mediaDetails);
    return mediaDetails;
  }

  static Future<MediaCollection> parseNavigationPlaylist(
    Map playlistMap, {
    MediaSourceInterface? source,
  }) async {
    MediaCollection mediaCollection = MediaCollection(
      type: MediaCollectionShowType.twoRowPlaylist,
    );
    mediaCollection.playlistType = CollectionType.MUSIC_PAGE_TYPE_PLAYLIST.name;
    mediaCollection.id = ParserHelper.parse<String>(
      playlistMap,
      NavigationButtonParserKeys.browseId,
    );
    mediaCollection.params = ParserHelper.parse<String>(
      playlistMap,
      NavigationButtonParserKeys.params,
    );
    mediaCollection.name =
        ParserHelper.parse<String>(
          playlistMap,
          NavigationButtonParserKeys.title,
        ) ??
        '';
    mediaCollection.displayName = mediaCollection.name;
    await RecordSyncHelper.syncFileGroup(mediaCollection);
    return mediaCollection;
  }
}

class SharedParserKeys {
  static String children = 'contents';

  static List visitorData = ['responseContext', 'visitorData'];
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
  static List items = ['items'];
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
