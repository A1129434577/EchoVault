import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/models/artist_info.dart';
import 'package:echo_vault/parse/data_sync_util.dart';
import 'package:echo_vault/parse/parse_util.dart';

enum FileType {
  //如果列表里面一个ATV都没有，用全视频样式渲染
  MUSIC_VIDEO_TYPE_ATV,
  MUSIC_VIDEO_TYPE_OMV,
  MUSIC_VIDEO_TYPE_UGC,
  //播客
  MUSIC_VIDEO_TYPE_PODCAST_EPISODE,
  //YouTube上的视频类型
  LOCKUP_CONTENT_TYPE_VIDEO;
}

class CommonParse {

  static Future<List<FileGroup>> parseContents(List groupMapList, {MediaSourceInterface? source}) async {
    List<FileGroup> list = [];
    for(Map groupMap in groupMapList){
      if(groupMap.containsKey(CarouselShelfParseKeys.carouselShelf)){
        groupMap = groupMap[CarouselShelfParseKeys.carouselShelf];
        FileGroup fileGroup = await CommonParse.parseCarouselShelfFileGroup(groupMap, source: source);
        list.add(fileGroup);
      }else if(groupMap.containsKey(ShelfParseKeys.shelf)){
        //多类型中夹杂的单列表，有group的title、name等
        groupMap = groupMap[ShelfParseKeys.shelf];
        FileGroup fileGroup = await CommonParse.parseShelfFileGroup(groupMap, source: source);
        list.add(fileGroup);
      }else if(groupMap.containsKey(ShelfParseKeys.playlistShelf)){
        //纯单列表无group的title、name等
        groupMap = groupMap[ShelfParseKeys.playlistShelf];
        FileGroup fileGroup = FileGroup(type: FileGroupShowType.listMusic);
        List childrenMapList = groupMap[CommonParseKeys.children]??[];
        List children = await parseChildren(childrenMapList, source: source);
        fileGroup.children = children;
        list.add(fileGroup);
      }else if(groupMap.containsKey(GridRendererParseKeys.gird)){
        groupMap = groupMap[GridRendererParseKeys.gird];
        String? name = ParseUtil.parse<String>(groupMap, NavigationButtonParseKeys.sectionTitle);
        FileGroup fileGroup = FileGroup(type: name!=null?FileGroupShowType.twoRowPlaylist:FileGroupShowType.grid);
        fileGroup.name = name??'';
        List childrenMapList = ParseUtil.parse<List>(groupMap, GridRendererParseKeys.items)??[];
        List children = await parseChildren(childrenMapList, source: source);
        fileGroup.children = children;
        list.add(fileGroup);
      }
    }
    return list;
  }

  ///解析书架样式的group(比如主页数据)
  static Future<FileGroup> parseCarouselShelfFileGroup(Map fileGroupMap, {MediaSourceInterface? source}) async {
    FileGroup fileGroup = FileGroup();
    fileGroup.id = ParseUtil.parse<String>(fileGroupMap, CarouselShelfParseKeys.groupId);
    fileGroup.name = ParseUtil.parse<String>(fileGroupMap, CarouselShelfParseKeys.groupName)??'';
    fileGroup.params = ParseUtil.parse<String>(fileGroupMap, CarouselShelfParseKeys.groupParams);
    List childrenMapList = fileGroupMap[CommonParseKeys.children]??[];
    List children = await parseChildren(childrenMapList, fileGroup: fileGroup, source: source);

    if(fileGroup.type == null){
      //剔除itemList中的的另类(比如大多是是视频里出现了一个playlist)
      List<FileInfo> fileList = children.whereType<FileInfo>().toList();
      List<FileGroup> playlistList = children.whereType<FileGroup>().toList();
      List<ArtistInfo> artistList = children.whereType<ArtistInfo>().toList();
      if (fileList.length >= playlistList.length && fileList.length >= artistList.length) {
        fileGroup.type = FileGroupShowType.twoRowVideo;
        children = fileList;
      } else if (playlistList.length >= fileList.length && playlistList.length >= artistList.length) {
        fileGroup.type = FileGroupShowType.twoRowPlaylist;
        children = playlistList;
      } else {
        fileGroup.type = FileGroupShowType.twoRowArtist;
        children = artistList;
      }
    }
    fileGroup.children = children;
    return fileGroup;
  }

  ///解析单列表类的group（比如歌手主页的热门歌曲）
  static Future<FileGroup> parseShelfFileGroup(Map fileGroupMap, {MediaSourceInterface? source}) async {
    FileGroup fileGroup = FileGroup(type: FileGroupShowType.listMusic);
    fileGroup.id = ParseUtil.parse<String>(fileGroupMap, ShelfParseKeys.groupId);
    fileGroup.name = ParseUtil.parse<String>(fileGroupMap, ShelfParseKeys.groupName)??'';
    fileGroup.params = ParseUtil.parse<String>(fileGroupMap, ShelfParseKeys.groupParams);
    List childrenMapList = fileGroupMap[CommonParseKeys.children]??[];
    List children = await parseChildren(childrenMapList, fileGroup: fileGroup, source: source);
    fileGroup.children = children;
    return fileGroup;
  }

  static Future<List> parseChildren(List childrenMapList, {FileGroup? fileGroup, MediaSourceInterface? source}) async {
    List children = [];
    for(final childrenMap in childrenMapList){
      if(childrenMap.containsKey(ResponsiveListParseKeys.responsiveList)){
        Map childMap = childrenMap[ResponsiveListParseKeys.responsiveList];
        String? playlistType = ParseUtil.parse<String>(childMap, ResponsiveListTowRowCommonParseKeys.pageType);
        String? videoId = ParseUtil.parse<String>(childMap, ResponsiveListParseKeys.videoId);
        if(playlistType != null){
          if(playlistType == ArtistInfo.ytmTypeName){
            fileGroup?.type = FileGroupShowType.twoRowArtist;
            ArtistInfo artist = await parseResponsiveListArtist(childMap, source: source);
            children.add(artist);
          }else{
            fileGroup?.type = FileGroupShowType.twoRowPlaylist;
            FileGroup playlist = await parseResponsiveListPlaylist(childMap, source: source);
            playlist.playlistType = playlistType;
            children.add(playlist);
          }
        }
        else if(videoId != null){
          //这里注意一下：如果已经作为Shelf单列表样式展示了就不再使用其他样式
          fileGroup?.type ??= FileGroupShowType.responsiveListMusic;
          FileInfo fileInfo = await parseResponsiveListMusic(childMap, source: source);
          //B面parentId只用于埋点，无其他实际逻辑
          fileInfo.parentId = fileGroup?.name;
          children.add(fileInfo);
        }
      }
      else if(childrenMap.containsKey(TwoRowParseKeys.twoRow)){
        Map childMap = childrenMap[TwoRowParseKeys.twoRow];
        String? playlistType = ParseUtil.parse<String>(childMap, ResponsiveListTowRowCommonParseKeys.pageType);
        String? videoType = ParseUtil.parse<String>(childMap, TwoRowParseKeys.musicVideoType);
        if(playlistType != null){
          if(playlistType == ArtistInfo.ytmTypeName){
            ArtistInfo artist = await parseTwoRowArtist(childMap, source: source);
            children.add(artist);
          }else{
            FileGroup playlist = await parseTwoRowPlaylist(childMap, source: source);
            playlist.playlistType = playlistType;
            children.add(playlist);
          }
        }
        else if(videoType != null){
          FileInfo fileInfo = await parseTwoRowMusicVideo(childMap, source: source);
          fileInfo.type = videoType;
          //B面parentId只用于埋点，无其他实际逻辑
          fileInfo.parentId = fileGroup?.name;
          children.add(fileInfo);
        }
      }
      else if(childrenMap.containsKey(CardShelfParseKeys.cardShelf)){
        Map childMap = childrenMap[CardShelfParseKeys.cardShelf];
        String? playlistType = ParseUtil.parse<String>(childMap, CardShelfParseKeys.pageType);
        String? videoType = ParseUtil.parse<String>(childMap, CardShelfParseKeys.musicVideoType);
        if(playlistType != null){
          if(playlistType == ArtistInfo.ytmTypeName){
            ArtistInfo artist = await parseCardArtist(childMap, source: source);
            children.add(artist);
          }else{
            FileGroup playlist = await parseCardPlaylist(childMap, source: source);
            playlist.playlistType = playlistType;
            children.add(playlist);
          }
        }
        else if(videoType != null){
          FileInfo fileInfo = await parseCardMusicVideo(childMap, source: source);
          fileInfo.type = videoType;
          //B面parentId只用于埋点，无其他实际逻辑
          fileInfo.parentId = fileGroup?.name;
          children.add(fileInfo);
        }
      }
      else if(childrenMap.containsKey(MultiRowListParseKeys.multiRow)){
        Map childMap = childrenMap[MultiRowListParseKeys.multiRow];
        String? videoType = ParseUtil.parse<String>(childMap, MultiRowListParseKeys.musicVideoType);
        if(videoType != null){
          FileInfo fileInfo = await parseMultiRowMusicVideo(childMap, source: source);
          fileInfo.type = videoType;
          //B面parentId只用于埋点，无其他实际逻辑
          fileInfo.parentId = fileGroup?.name;
          children.add(fileInfo);
        }
      }
      else if(childrenMap.containsKey(PanelVideoParseKeys.panel)){
        Map childMap = childrenMap[PanelVideoParseKeys.panel];
        String? videoType = ParseUtil.parse<String>(childMap, PanelVideoParseKeys.musicVideoType);
        if(videoType != null){
          FileInfo fileInfo = await parsePanelVideo(childMap, source: source);
          fileInfo.type = videoType;
          //B面parentId只用于埋点，无其他实际逻辑
          fileInfo.parentId = fileGroup?.name;
          children.add(fileInfo);
        }
      }
      else if(childrenMap.containsKey(NavigationButtonParseKeys.navigation)){
        Map childMap = childrenMap[NavigationButtonParseKeys.navigation];
        FileGroup playlist = await parseNavigationPlaylist(childMap, source: source);
        children.add(playlist);
      }
    }
    return children;
  }

  static Future<FileInfo> parseResponsiveListMusic(Map fileInfoMap, {MediaSourceInterface? source}) async {
    FileInfo fileInfo = FileInfo(extension: 'mp4', source: source);
    fileInfo.fileId = ParseUtil.parse<String>(fileInfoMap, ResponsiveListParseKeys.videoId)??'';
    fileInfo.type = ParseUtil.parse<String>(fileInfoMap, ResponsiveListParseKeys.musicVideoType);
    fileInfo.thumbnail = ParseUtil.parse<String>(fileInfoMap, ResponsiveListParseKeys.cover) ?? 'https://i.ytimg.com/vi/${fileInfo.fileId}/default.jpg';
    fileInfo.name = ParseUtil.parse<String>(fileInfoMap, ResponsiveListParseKeys.title)??'';
    String subtitle = '';
    for (Map textRun in ParseUtil.parse<List?>(fileInfoMap, ResponsiveListParseKeys.subtitleRuns)??[]) {
      subtitle += textRun['text'];
    }
    fileInfo.artist = subtitle;
    await DataSyncUtil.syncFileInfo(fileInfo);
    return fileInfo;
  }
  static Future<ArtistInfo> parseResponsiveListArtist(Map artistMap, {MediaSourceInterface? source}) async {
    ArtistInfo artistInfo = ArtistInfo();
    artistInfo.id = ParseUtil.parse<String>(artistMap, ResponsiveListTowRowCommonParseKeys.browseId);
    artistInfo.thumbnail = ParseUtil.parse<String>(artistMap, ResponsiveListParseKeys.cover)??'';
    artistInfo.name = ParseUtil.parse<String>(artistMap, ResponsiveListParseKeys.title)??"";
    String subtitle = '';
    for (Map textRun in ParseUtil.parse<List?>(artistMap, ResponsiveListParseKeys.subtitleRuns)??[]) {
      subtitle += textRun['text'];
    }
    artistInfo.desc = subtitle;
    await DataSyncUtil.syncArtist(artistInfo);
    return artistInfo;
  }
  static Future<FileGroup> parseResponsiveListPlaylist(Map playlistMap, {MediaSourceInterface? source}) async {
    FileGroup fileGroup = FileGroup();
    fileGroup.id = ParseUtil.parse<String>(playlistMap, ResponsiveListTowRowCommonParseKeys.browseId);
    fileGroup.thumbnail = ParseUtil.parse<String>(playlistMap, ResponsiveListParseKeys.cover)??'';
    fileGroup.name = ParseUtil.parse<String>(playlistMap, ResponsiveListParseKeys.title)??'';
    fileGroup.displayName = fileGroup.name;
    String subtitle = '';
    for (Map textRun in ParseUtil.parse<List?>(playlistMap, ResponsiveListParseKeys.subtitleRuns)??[]) {
      subtitle += textRun['text'];
    }
    fileGroup.detail = subtitle;
    await DataSyncUtil.syncFileGroup(fileGroup);
    return fileGroup;
  }

  static Future<FileInfo> parseTwoRowMusicVideo(Map fileInfoMap, {MediaSourceInterface? source}) async {
    FileInfo fileInfo = FileInfo(extension: 'mp4', source: source);
    fileInfo.fileId = ParseUtil.parse<String>(fileInfoMap, TwoRowParseKeys.videoId)??'';
    fileInfo.thumbnail = ParseUtil.parse<String>(fileInfoMap, TwoRowParseKeys.cover) ?? 'https://i.ytimg.com/vi/${fileInfo.fileId}/default.jpg';
    fileInfo.name = ParseUtil.parse<String>(fileInfoMap, TwoRowParseKeys.title)??'';
    String subtitle = '';
    for (Map textRun in ParseUtil.parse<List?>(fileInfoMap, TwoRowParseKeys.subtitleRuns)??[]) {
      subtitle += textRun['text'];
    }
    fileInfo.artist = subtitle;
    await DataSyncUtil.syncFileInfo(fileInfo);
    return fileInfo;
  }
  static Future<ArtistInfo> parseTwoRowArtist(Map artistMap, {MediaSourceInterface? source}) async {
    ArtistInfo artist = ArtistInfo();
    artist.id = ParseUtil.parse<String>(artistMap, ResponsiveListTowRowCommonParseKeys.browseId);
    artist.thumbnail = ParseUtil.parse<String>(artistMap, TwoRowParseKeys.cover)??'';
    artist.name = ParseUtil.parse<String>(artistMap, TwoRowParseKeys.title)??'';
    String subtitle = '';
    for (Map textRun in ParseUtil.parse<List?>(artistMap, TwoRowParseKeys.subtitleRuns)??[]) {
      subtitle += textRun['text'];
    }
    artist.desc = subtitle;
    await DataSyncUtil.syncArtist(artist);
    return artist;
  }
  static Future<FileGroup> parseTwoRowPlaylist(Map playlistMap, {MediaSourceInterface? source}) async {
    FileGroup fileGroup = FileGroup();
    fileGroup.id = ParseUtil.parse<String>(playlistMap, ResponsiveListTowRowCommonParseKeys.browseId);
    fileGroup.thumbnail = ParseUtil.parse<String>(playlistMap, TwoRowParseKeys.cover)??'';
    fileGroup.name = ParseUtil.parse<String>(playlistMap, TwoRowParseKeys.title)??'';
    fileGroup.displayName = fileGroup.name;
    String subtitle = '';
    for (Map textRun in ParseUtil.parse<List?>(playlistMap, TwoRowParseKeys.subtitleRuns)??[]) {
      subtitle += textRun['text'];
    }
    fileGroup.detail = subtitle;
    await DataSyncUtil.syncFileGroup(fileGroup);
    return fileGroup;
  }

  static Future<FileInfo> parseCardMusicVideo(Map fileInfoMap, {MediaSourceInterface? source}) async {
    FileInfo fileInfo = FileInfo(extension: 'mp4', source: source);
    fileInfo.fileId = ParseUtil.parse<String>(fileInfoMap, CardShelfParseKeys.videoId)??'';
    fileInfo.thumbnail = ParseUtil.parse<String>(fileInfoMap, CardShelfParseKeys.cover) ?? 'https://i.ytimg.com/vi/${fileInfo.fileId}/default.jpg';
    fileInfo.name = ParseUtil.parse<String>(fileInfoMap, CardShelfParseKeys.title)??'';
    String subtitle = '';
    for (Map textRun in ParseUtil.parse<List?>(fileInfoMap, CardShelfParseKeys.subtitleRuns)??[]) {
      subtitle += textRun['text'];
    }
    fileInfo.artist = subtitle;
    await DataSyncUtil.syncFileInfo(fileInfo);
    return fileInfo;
  }
  static Future<ArtistInfo> parseCardArtist(Map artistMap, {MediaSourceInterface? source}) async {
    ArtistInfo artist = ArtistInfo();
    artist.id = ParseUtil.parse<String>(artistMap, CardShelfParseKeys.browseId);
    artist.thumbnail = ParseUtil.parse<String>(artistMap, CardShelfParseKeys.cover)??'';
    artist.name = ParseUtil.parse<String>(artistMap, CardShelfParseKeys.title)??'';
    String subtitle = '';
    for (Map textRun in ParseUtil.parse<List?>(artistMap, CardShelfParseKeys.subtitleRuns)??[]) {
      subtitle += textRun['text'];
    }
    artist.desc = subtitle;
    await DataSyncUtil.syncArtist(artist);
    return artist;
  }
  static Future<FileGroup> parseCardPlaylist(Map playlistMap, {MediaSourceInterface? source}) async {
    FileGroup fileGroup = FileGroup();
    fileGroup.id = ParseUtil.parse<String>(playlistMap, CardShelfParseKeys.browseId);
    fileGroup.thumbnail = ParseUtil.parse<String>(playlistMap, CardShelfParseKeys.cover)??'';
    fileGroup.name = ParseUtil.parse<String>(playlistMap, CardShelfParseKeys.title)??"";
    fileGroup.displayName = fileGroup.name;
    String subtitle = '';
    for (Map textRun in ParseUtil.parse<List?>(playlistMap, CardShelfParseKeys.subtitleRuns)??[]) {
      subtitle += textRun['text'];
    }
    fileGroup.detail = subtitle;
    await DataSyncUtil.syncFileGroup(fileGroup);
    return fileGroup;
  }

  static Future<FileInfo> parseMultiRowMusicVideo(Map fileInfoMap, {MediaSourceInterface? source}) async {
    FileInfo fileInfo = FileInfo(extension: 'mp4', source: source);
    fileInfo.fileId = ParseUtil.parse<String>(fileInfoMap, MultiRowListParseKeys.videoId)??'';
    fileInfo.thumbnail = ParseUtil.parse<String>(fileInfoMap, MultiRowListParseKeys.cover) ?? 'https://i.ytimg.com/vi/${fileInfo.fileId}/default.jpg';
    fileInfo.name = ParseUtil.parse<String>(fileInfoMap, MultiRowListParseKeys.title)??'';
    String subtitle = '';
    for (Map textRun in ParseUtil.parse<List?>(fileInfoMap, MultiRowListParseKeys.subtitleRuns)??[]) {
      subtitle += textRun['text'];
    }
    fileInfo.artist = subtitle;
    await DataSyncUtil.syncFileInfo(fileInfo);
    return fileInfo;
  }

  static Future<FileInfo> parsePanelVideo(Map fileInfoMap, {MediaSourceInterface? source}) async {
    FileInfo fileInfo = FileInfo(extension: 'mp4', source: source);
    fileInfo.fileId = ParseUtil.parse<String>(fileInfoMap, PanelVideoParseKeys.videoId)??'';
    fileInfo.thumbnail = ParseUtil.parse<String>(fileInfoMap, PanelVideoParseKeys.cover) ?? 'https://i.ytimg.com/vi/${fileInfo.fileId}/default.jpg';
    fileInfo.name = ParseUtil.parse<String>(fileInfoMap, PanelVideoParseKeys.title)??'';
    String subtitle = '';
    for (Map textRun in ParseUtil.parse<List?>(fileInfoMap, PanelVideoParseKeys.subtitleRuns)??[]) {
      subtitle += textRun['text'];
    }
    fileInfo.artist = subtitle;
    await DataSyncUtil.syncFileInfo(fileInfo);
    return fileInfo;
  }

  static Future<FileGroup> parseNavigationPlaylist(Map playlistMap, {MediaSourceInterface? source}) async {
    FileGroup fileGroup = FileGroup(type: FileGroupShowType.twoRowPlaylist);
    fileGroup.playlistType = PlaylistType.MUSIC_PAGE_TYPE_PLAYLIST.name;
    fileGroup.id = ParseUtil.parse<String>(playlistMap, NavigationButtonParseKeys.browseId);
    fileGroup.params = ParseUtil.parse<String>(playlistMap, NavigationButtonParseKeys.params);
    fileGroup.name = ParseUtil.parse<String>(playlistMap, NavigationButtonParseKeys.title)??'';
    fileGroup.displayName = fileGroup.name;
    await DataSyncUtil.syncFileGroup(fileGroup);
    return fileGroup;
  }
}

class CommonParseKeys {
  static String children = 'contents';

  static List visitorData = [
    'responseContext',
    'visitorData',
  ];
}

///类似主页样式分组列表解析参数
class SectionListParseKeys {
  //翻页参数
  static List initContinuation = [
    'contents',
    'singleColumnBrowseResultsRenderer',
    'tabs',
    {
      ParseUtil.indexKey: 0,
    },
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'continuations',
    {
      ParseUtil.indexKey: 0,
    },
    'nextContinuationData',
    'continuation',
  ];

  //翻页参数
  static List moreContinuation = [
    'continuationContents',
    'sectionListContinuation',
    'continuations',
    {
      ParseUtil.indexKey: 0,
    },
    'nextContinuationData',
    'continuation',
  ];

  //如果这个不为空说明不可用
  static List itemSectionRenderer = [
    'contents',
    'singleColumnBrowseResultsRenderer',
    'tabs',
    {
      ParseUtil.indexKey: 0,
    },
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'contents',
    {ParseUtil.filterKey:'itemSectionRenderer'}
  ];

  //翻页第一页数据列表
  static List initResourceList = [
    'contents',
    'singleColumnBrowseResultsRenderer',
    'tabs',
    {
      ParseUtil.indexKey: 0,
    },
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
class CarouselShelfParseKeys {
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
    {
      ParseUtil.indexKey: 0,
    },
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
class GridRendererParseKeys {
  static String gird = 'gridRenderer';
  static List items = [
    'items',
  ];
}

//单列表解析（如playlist详情页）
class ShelfParseKeys {
  static String shelf = 'musicShelfRenderer';
  static String playlistShelf = 'musicPlaylistShelfRenderer';

  //局部单列表的分组id（比如歌手列表的热门歌曲）
  static List groupId = [
    'title',
    'runs',
    {
      ParseUtil.indexKey: 0,
    },
    'navigationEndpoint',
    'browseEndpoint',
    'browseId',
  ];

  //局部单列表的分组name（比如歌手列表的热门歌曲）
  static List groupName = [
    'title',
    'runs',
    {
      ParseUtil.indexKey: 0,
    },
    'text',
  ];

  static List groupParams = [
    'title',
    'runs',
    {
      ParseUtil.indexKey: 0,
    },
    'navigationEndpoint',
    'browseEndpoint',
    'params',
  ];
}

class ResponsiveListTowRowCommonParseKeys {
  static List pageType = [
    'navigationEndpoint',
    'browseEndpoint',
    'browseEndpointContextSupportedConfigs',
    'browseEndpointContextMusicConfig',
    'pageType',
  ];
  static List browseId = [
    'navigationEndpoint',
    'browseEndpoint',
    'browseId',
  ];
}

class ResponsiveListParseKeys {
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

  static List videoId = [
    'playlistItemData',
    'videoId',
  ];

  static List cover = [
    'thumbnail',
    'musicThumbnailRenderer',
    'thumbnail',
    'thumbnails',
    {ParseUtil.indexKey: 1},
    'url',
  ];

  static List title = [
    'flexColumns',
    {ParseUtil.indexKey: 0},
    'musicResponsiveListItemFlexColumnRenderer',
    'text',
    'runs',
    {ParseUtil.indexKey: 0},
    'text',
  ];
  static List subtitleRuns = [
    'flexColumns',
    {ParseUtil.indexKey: 1},
    'musicResponsiveListItemFlexColumnRenderer',
    'text',
    'runs',
  ];
}

class TwoRowParseKeys {
  static String twoRow = 'musicTwoRowItemRenderer';

  static List musicVideoType = [
    'navigationEndpoint',
    'watchEndpoint',
    'watchEndpointMusicSupportedConfigs',
    'watchEndpointMusicConfig',
    'musicVideoType',
  ];

  static List videoId = [
    'navigationEndpoint',
    'watchEndpoint',
    'videoId',
  ];

  static List cover = [
    'thumbnailRenderer',
    'musicThumbnailRenderer',
    'thumbnail',
    'thumbnails',
    {ParseUtil.indexKey: 0},
    'url',
  ];

  static List title = [
    'title',
    'runs',
    {ParseUtil.indexKey: 0},
    'text',
  ];

  static List subtitleRuns = [
    'subtitle',
    'runs',
  ];
}

//卡片解析（如搜索最佳结果）
class CardShelfParseKeys {
  static String cardShelf = 'musicCardShelfRenderer';

  static List pageType = [
    'title',
    'runs',
    {ParseUtil.indexKey: 0},
    'navigationEndpoint',
    'browseEndpoint',
    'browseEndpointContextSupportedConfigs',
    'browseEndpointContextMusicConfig',
    'pageType',
  ];

  static List browseId = [
    'title',
    'runs',
    {ParseUtil.indexKey: 0},
    'navigationEndpoint',
    'browseEndpoint',
    'browseId',
  ];

  static List musicVideoType = [
    'title',
    'runs',
    {ParseUtil.indexKey: 0},
    'navigationEndpoint',
    'watchEndpoint',
    'watchEndpointMusicSupportedConfigs',
    'watchEndpointMusicConfig',
    'musicVideoType',
  ];

  static List videoId = [
    'title',
    'runs',
    {ParseUtil.indexKey: 0},
    'navigationEndpoint',
    'watchEndpoint',
    'videoId',
  ];

  static List cover = [
    'thumbnail',
    'musicThumbnailRenderer',
    'thumbnail',
    'thumbnails',
    {ParseUtil.indexKey: 0},
    'url',
  ];

  static List title = [
    'title',
    'runs',
    {ParseUtil.indexKey: 0},
    'text',
  ];

  static List subtitleRuns = [
    'subtitle',
    'runs',
  ];
}

//类似播客解析
class MultiRowListParseKeys {
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
    {ParseUtil.indexKey: 1},
    'url',
  ];

  static List title = [
    'title',
    'runs',
    {ParseUtil.indexKey: 0},
    'text',
  ];

  static List subtitleRuns = [
    'subtitle',
    'runs',
  ];
}

//接下来播放解析
class PanelVideoParseKeys {
  static String panel = 'playlistPanelVideoRenderer';

  static List musicVideoType = [
    'navigationEndpoint',
    'watchEndpoint',
    'watchEndpointMusicSupportedConfigs',
    'watchEndpointMusicConfig',
    'musicVideoType',
  ];

  static List videoId = [
    'videoId',
  ];

  static List cover = [
    'thumbnail',
    'thumbnails',
    {ParseUtil.indexKey: 1},
    'url',
  ];

  static List title = [
    'title',
    'runs',
    {ParseUtil.indexKey: 0},
    'text',
  ];

  static List subtitleRuns = [
    'longBylineText',
    'runs',
  ];
}

//比如首页为你推荐的精选播放列表
class NavigationButtonParseKeys {
  static List sectionTitle = [
    'header',
    'gridHeaderRenderer',
    'title',
    'runs',
    {
      ParseUtil.indexKey: 0,
    },
    'text',
  ];

  static String navigation = 'musicNavigationButtonRenderer';

  //局部单列表的分组id（比如歌手列表的热门歌曲）
  static List browseId = [
    'clickCommand',
    'browseEndpoint',
    'browseId',
  ];

  //局部单列表的分组name（比如歌手列表的热门歌曲）
  static List title = [
    'buttonText',
    'runs',
    {
      ParseUtil.indexKey: 0,
    },
    'text',
  ];

  static List params = [
    'clickCommand',
    'browseEndpoint',
    'params',
  ];
}