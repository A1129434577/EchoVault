import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/models/artist_info.dart';
import 'package:echo_vault/parse/common_parse.dart';
import 'package:echo_vault/parse/data_sync_util.dart';
import 'package:echo_vault/parse/parse_util.dart';

///解析Youtube
class CommonYtParse {
  static Future<List<FileGroup>> parseHomeContents(List groupMapList, {MediaSourceInterface? source}) async {
    List<FileGroup> list = [];
    for(Map groupMap in groupMapList){
      if(groupMap.containsKey(HomeYTParseKeys.sectionParent)){
        groupMap = ParseUtil.parse<Map>(groupMap, HomeYTParseKeys.sectionItem)??{};
        FileGroup fileGroup = await CommonYtParse.parseHomeFileGroup(groupMap, source: source);
        list.add(fileGroup);
      }
    }
    return list;
  }

  ///解析Youtube(非Youtube Music)首页数据
  static Future<FileGroup> parseHomeFileGroup(Map fileGroupMap, {MediaSourceInterface? source}) async {
    FileGroup fileGroup = FileGroup();
    fileGroup.id = ParseUtil.parse<String>(fileGroupMap, HomeYTParseKeys.groupId);
    fileGroup.name = ParseUtil.parse<String>(fileGroupMap, HomeYTParseKeys.groupName)??'';
    List childrenMapList = fileGroupMap[CommonParseKeys.children]??[];
    List children = await parseHomeChildren(childrenMapList, fileGroup: fileGroup, source: source);

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

  static Future<List> parseHomeChildren(List childrenMapList, {FileGroup? fileGroup, MediaSourceInterface? source}) async {
    List children = [];
    for(final childrenMap in childrenMapList){
      if(childrenMap.containsKey(HomeYTParseKeys.richItem)){
        Map childMap = childrenMap[HomeYTParseKeys.richItem];
        String? playlistType = ParseUtil.parse<String>(childMap, HomeYTParseKeys.playlistType);
        String? videoId = ParseUtil.parse<String>(childMap, HomeYTParseKeys.videoId);
        if(playlistType == PlaylistType.LOCKUP_CONTENT_TYPE_ALBUM.name ||
            playlistType == PlaylistType.LOCKUP_CONTENT_TYPE_PLAYLIST.name){
          FileGroup playlist = await parseHomePlaylist(childMap, source: source);
          playlist.playlistType = playlistType;
          children.add(playlist);
        }
        else if(playlistType == FileType.LOCKUP_CONTENT_TYPE_VIDEO.name){
          FileInfo fileInfo = await parseHomePlaylistVideo(childMap, source: source);
          //B面parentId只用于埋点，无其他实际逻辑
          fileInfo.parentId = fileGroup?.name;
          children.add(fileInfo);
        }
        else if(videoId != null){
          FileInfo fileInfo = await parseHomeVideo(childMap, source: source);
          //B面parentId只用于埋点，无其他实际逻辑
          fileInfo.parentId = fileGroup?.name;
          children.add(fileInfo);
        }
      }
    }
    return children;
  }
  static Future<FileInfo> parseHomeVideo(Map fileInfoMap, {MediaSourceInterface? source}) async {
    FileInfo fileInfo = FileInfo(extension: 'mp4', source: source);
    fileInfo.fileId = ParseUtil.parse<String>(fileInfoMap, HomeYTParseKeys.videoId)??'';
    fileInfo.thumbnail = ParseUtil.parse<String>(fileInfoMap, HomeYTParseKeys.videoCover) ?? 'https://i.ytimg.com/vi/${fileInfo.fileId}/default.jpg';
    fileInfo.name = ParseUtil.parse<String>(fileInfoMap, HomeYTParseKeys.videoTitle)??'';
    fileInfo.artist = ParseUtil.parse<String>(fileInfoMap, HomeYTParseKeys.videoSubtitle);
    await DataSyncUtil.syncFileInfo(fileInfo);
    return fileInfo;
  }
  static Future<FileInfo> parseHomePlaylistVideo(Map fileInfoMap, {MediaSourceInterface? source}) async {
    FileInfo fileInfo = FileInfo(extension: 'mp4', source: source);
    fileInfo.fileId = ParseUtil.parse<String>(fileInfoMap, HomeYTParseKeys.playlistVideoId)??'';
    fileInfo.thumbnail = ParseUtil.parse<String>(fileInfoMap, HomeYTParseKeys.playlistVideoCover) ?? 'https://i.ytimg.com/vi/${fileInfo.fileId}/default.jpg';
    fileInfo.name = ParseUtil.parse<String>(fileInfoMap, HomeYTParseKeys.playlistVideoTitle)??'';
    fileInfo.artist = ParseUtil.parse<String>(fileInfoMap, HomeYTParseKeys.playlistVideoSubtitle);
    await DataSyncUtil.syncFileInfo(fileInfo);
    return fileInfo;
  }
  static Future<FileGroup> parseHomePlaylist(Map playlistMap, {MediaSourceInterface? source}) async {
    FileGroup fileGroup = FileGroup();
    fileGroup.id = ParseUtil.parse<String>(playlistMap, HomeYTParseKeys.playlistId);
    fileGroup.thumbnail = ParseUtil.parse<String>(playlistMap, HomeYTParseKeys.playlistCover)??'';
    fileGroup.name = ParseUtil.parse<String>(playlistMap, HomeYTParseKeys.playlistTitle)??'';
    fileGroup.displayName = fileGroup.name;
    fileGroup.detail = ParseUtil.parse<String>(playlistMap, HomeYTParseKeys.playlistSubtitle);
    await DataSyncUtil.syncFileGroup(fileGroup);
    return fileGroup;
  }

  static Future<List> parsePlaylistChildren(List childrenMapList, {FileGroup? fileGroup, MediaSourceInterface? source}) async {
    List children = [];
    for(final childrenMap in childrenMapList){
      if(childrenMap.containsKey(PlaylistYTParseKeys.panel)){
        Map childMap = childrenMap[PlaylistYTParseKeys.panel];
        String? videoId = ParseUtil.parse<String>(childMap, PlaylistYTParseKeys.videoId);
        if(videoId != null){
          FileInfo fileInfo = await parsePlaylistVideo(childMap, source: source);
          fileInfo.fileId = videoId;
          //B面parentId只用于埋点，无其他实际逻辑
          fileInfo.parentId = fileGroup?.name;
          children.add(fileInfo);
        }
      }
    }
    return children;
  }
  static Future<FileInfo> parsePlaylistVideo(Map fileInfoMap, {MediaSourceInterface? source}) async {
    FileInfo fileInfo = FileInfo(extension: 'mp4', source: source);
    fileInfo.fileId = ParseUtil.parse<String>(fileInfoMap, PlaylistYTParseKeys.videoId)??'';
    fileInfo.thumbnail = ParseUtil.parse<String>(fileInfoMap, PlaylistYTParseKeys.cover) ?? 'https://i.ytimg.com/vi/${fileInfo.fileId}/default.jpg';
    fileInfo.name = ParseUtil.parse<String>(fileInfoMap, PlaylistYTParseKeys.title)??'';
    fileInfo.artist = ParseUtil.parse<String>(fileInfoMap, PlaylistYTParseKeys.subtitle);
    await DataSyncUtil.syncFileInfo(fileInfo);
    return fileInfo;
  }

  static Future<List> parsePlayRecommendChildren(List childrenMapList, {FileGroup? fileGroup, MediaSourceInterface? source}) async {
    List children = [];
    for(final childrenMap in childrenMapList){
      if(childrenMap.containsKey(PlayRecommendYTParseKeys.lockupViewModel)){
        Map childMap = childrenMap[PlayRecommendYTParseKeys.lockupViewModel];
        String? videoId = ParseUtil.parse<String>(childMap, PlayRecommendYTParseKeys.videoId);
        if(videoId != null){
          FileInfo fileInfo = await parsePlayRecommendVideo(childMap, source: source);
          fileInfo.fileId = videoId;
          //B面parentId只用于埋点，无其他实际逻辑
          fileInfo.parentId = fileGroup?.name;
          children.add(fileInfo);
        }
      }
    }
    return children;
  }
  static Future<FileInfo> parsePlayRecommendVideo(Map fileInfoMap, {MediaSourceInterface? source}) async {
    FileInfo fileInfo = FileInfo(extension: 'mp4', source: source);
    fileInfo.fileId = ParseUtil.parse<String>(fileInfoMap, PlayRecommendYTParseKeys.videoId)??'';
    fileInfo.thumbnail = ParseUtil.parse<String>(fileInfoMap, PlayRecommendYTParseKeys.cover) ?? 'https://i.ytimg.com/vi/${fileInfo.fileId}/default.jpg';
    fileInfo.name = ParseUtil.parse<String>(fileInfoMap, PlayRecommendYTParseKeys.title)??'';
    fileInfo.artist = ParseUtil.parse<String>(fileInfoMap, PlayRecommendYTParseKeys.subtitle);
    await DataSyncUtil.syncFileInfo(fileInfo);
    return fileInfo;
  }

  static Future<List> parseArtistChildren(List childrenMapList, {FileGroup? fileGroup, MediaSourceInterface? source}) async {
    List children = [];
    for(final childrenMap in childrenMapList){
      if(childrenMap.containsKey(ArtistYTParseKeys.richItem)){
        Map childMap = childrenMap[ArtistYTParseKeys.richItem];
        String? playlistId = ParseUtil.parse<String>(childMap, ArtistYTParseKeys.albumId);
        String? videoRendererVideoId = ParseUtil.parse<String>(childMap, ArtistYTParseKeys.videoRendererVideoId);
        Map? lockupViewModel = ParseUtil.parse<Map>(childMap, ArtistYTParseKeys.lockupViewModelVideoItem);
        if(videoRendererVideoId != null){
          FileInfo fileInfo = await parseArtistVideoRendererVideo(childMap, source: source);
          //B面parentId只用于埋点，无其他实际逻辑
          fileInfo.parentId = fileGroup?.name;
          children.add(fileInfo);
        }
        else if(lockupViewModel != null){
          FileInfo fileInfo = await parseArtistLockupViewModelVideo(lockupViewModel, source: source);
          //B面parentId只用于埋点，无其他实际逻辑
          fileInfo.parentId = fileGroup?.name;
          children.add(fileInfo);
        }
        else if(playlistId != null){
          FileGroup playlist = await parseArtistAlbum(childMap, source: source);
          playlist.playlistType = PlaylistType.LOCKUP_CONTENT_TYPE_ALBUM.name;
          playlist.id = playlistId;
          children.add(playlist);
        }
      }
      else if(childrenMap.containsKey(ArtistYTParseKeys.lockupViewModelPlaylistItem)){
        Map childMap = childrenMap[ArtistYTParseKeys.lockupViewModelPlaylistItem];
        String? playlistId = ParseUtil.parse<String>(childMap, ArtistYTParseKeys.lockupViewModelId);
        if(playlistId != null){
          FileGroup playlist = await parseArtistPlaylist(childMap, source: source);
          playlist.id = playlistId;
          children.add(playlist);
        }
      }
    }
    return children;
  }
  static Future<FileInfo> parseArtistVideoRendererVideo(Map fileInfoMap, {MediaSourceInterface? source}) async {
    FileInfo fileInfo = FileInfo(extension: 'mp4', source: source);
    fileInfo.fileId = ParseUtil.parse<String>(fileInfoMap, ArtistYTParseKeys.videoRendererVideoId)??'';
    fileInfo.thumbnail = ParseUtil.parse<String>(fileInfoMap, ArtistYTParseKeys.videoRendererVideoCover) ?? 'https://i.ytimg.com/vi/${fileInfo.fileId}/default.jpg';
    fileInfo.name = ParseUtil.parse<String>(fileInfoMap, ArtistYTParseKeys.videoRendererVideoTitle)??'';
    String? viewCountText = ParseUtil.parse<String>(fileInfoMap, ArtistYTParseKeys.videoRendererViewCountText);
    String? lengthText = ParseUtil.parse<String>(fileInfoMap, ArtistYTParseKeys.videoRendererLengthText);
    String? publishedTimeText = ParseUtil.parse<String>(fileInfoMap, ArtistYTParseKeys.videoRendererPublishedTimeText);
    fileInfo.artist = [viewCountText, lengthText, publishedTimeText].join(' • ');
    await DataSyncUtil.syncFileInfo(fileInfo);
    return fileInfo;
  }
  static Future<FileInfo> parseArtistLockupViewModelVideo(Map fileInfoMap, {MediaSourceInterface? source}) async {
    FileInfo fileInfo = FileInfo(extension: 'mp4', source: source);
    fileInfo.fileId = ParseUtil.parse<String>(fileInfoMap, ArtistYTParseKeys.lockupViewModelId)??'';
    fileInfo.type = ParseUtil.parse<String>(fileInfoMap, ArtistYTParseKeys.lockupViewModelType);
    fileInfo.thumbnail = ParseUtil.parse<String>(fileInfoMap, ArtistYTParseKeys.lockupViewModelVideoCover) ?? 'https://i.ytimg.com/vi/${fileInfo.fileId}/default.jpg';
    fileInfo.name = ParseUtil.parse<String>(fileInfoMap, ArtistYTParseKeys.lockupViewModelTitle)??'';
    fileInfo.artist = ParseUtil.parse<String>(fileInfoMap, ArtistYTParseKeys.lockupViewModelSubtitle)??'';
    await DataSyncUtil.syncFileInfo(fileInfo);
    return fileInfo;
  }
  static Future<FileGroup> parseArtistAlbum(Map playlistMap, {MediaSourceInterface? source}) async {
    FileGroup fileGroup = FileGroup();
    fileGroup.thumbnail = ParseUtil.parse<String>(playlistMap, ArtistYTParseKeys.albumCover)??'';
    fileGroup.name = ParseUtil.parse<String>(playlistMap, ArtistYTParseKeys.albumTitle)??'';
    fileGroup.displayName = fileGroup.name;
    String subtitle = '';
    for (Map textRun in ParseUtil.parse<List?>(playlistMap, ArtistYTParseKeys.albumSubtitleRuns)??[]) {
      subtitle += textRun['text'];
    }
    fileGroup.detail = subtitle;
    await DataSyncUtil.syncFileGroup(fileGroup);
    return fileGroup;
  }
  static Future<FileGroup> parseArtistPlaylist(Map playlistMap, {MediaSourceInterface? source}) async {
    FileGroup fileGroup = FileGroup();
    fileGroup.playlistType = ParseUtil.parse<String>(playlistMap, ArtistYTParseKeys.lockupViewModelType);
    fileGroup.thumbnail = ParseUtil.parse<String>(playlistMap, ArtistYTParseKeys.lockupViewModelPlaylistCover)??'';
    fileGroup.name = ParseUtil.parse<String>(playlistMap, ArtistYTParseKeys.lockupViewModelTitle)??'';
    fileGroup.displayName = fileGroup.name;
    await DataSyncUtil.syncFileGroup(fileGroup);
    return fileGroup;
  }

  static Future<List> parseSearchTopChildren(List childrenMapList, {FileGroup? fileGroup, MediaSourceInterface? source}) async {
    List children = [];
    for(final childrenMap in childrenMapList){
      if(childrenMap.containsKey(SearchYTParseKeys.topVideoItem)){
        Map childMap = childrenMap[SearchYTParseKeys.topVideoItem];
        FileInfo fileInfo = await parseSearchTopVideo(childMap, source: source);
        //B面parentId只用于埋点，无其他实际逻辑
        fileInfo.parentId = fileGroup?.name;
        children.add(fileInfo);
      }else if(childrenMap.containsKey(SearchYTParseKeys.topCardItem)){
        Map childMap = childrenMap[SearchYTParseKeys.topCardItem];
        String? pageType = ParseUtil.parse<String>(childMap, SearchYTParseKeys.topCardPageType);
        if(pageType == ArtistInfo.ytSearchTypeName){
          ArtistInfo artist = await parseSearchTopCardArtist(childMap);
          children.add(artist);
        }else if(pageType == PlaylistType.WEB_PAGE_TYPE_PLAYLIST.name){
          FileGroup fileGroup = await parseSearchTopCardPlaylist(childMap);
          fileGroup.playlistType = pageType;
          children.add(fileGroup);
        }
      }
    }
    return children;
  }
  static Future<FileInfo> parseSearchTopVideo(Map fileInfoMap, {MediaSourceInterface? source}) async {
    FileInfo fileInfo = FileInfo(extension: 'mp4', source: source);
    fileInfo.fileId = ParseUtil.parse<String>(fileInfoMap, SearchYTParseKeys.topVideoId)??'';
    fileInfo.thumbnail = 'https://i.ytimg.com/vi/${fileInfo.fileId}/default.jpg';
    fileInfo.name = ParseUtil.parse<String>(fileInfoMap, SearchYTParseKeys.topVideoTitle)??'';
    fileInfo.artist = ParseUtil.parse<String>(fileInfoMap, SearchYTParseKeys.topVideoSubtitle)??ParseUtil.parse<String>(fileInfoMap, SearchYTParseKeys.topVideoSubtitle1);
    await DataSyncUtil.syncFileInfo(fileInfo);
    return fileInfo;
  }
  static Future<ArtistInfo> parseSearchTopCardArtist(Map artistMap, {MediaSourceInterface? source}) async {
    ArtistInfo artist = ArtistInfo();
    artist.ytId = ParseUtil.parse<String>(artistMap, SearchYTParseKeys.topCardBrowseId);
    artist.thumbnail = ParseUtil.parse<String>(artistMap, SearchYTParseKeys.topCardArtistCover)??'';
    artist.name = ParseUtil.parse<String>(artistMap, SearchYTParseKeys.topCardTitle)??'';
    artist.desc = ParseUtil.parse<String>(artistMap, SearchYTParseKeys.topCardSubtitle)??'';
    await DataSyncUtil.syncArtist(artist);
    return artist;
  }
  static Future<FileGroup> parseSearchTopCardPlaylist(Map playlistMap, {MediaSourceInterface? source}) async {
    FileGroup fileGroup = FileGroup();
    fileGroup.id = ParseUtil.parse<String>(playlistMap, SearchYTParseKeys.topCardBrowseId);
    fileGroup.name = ParseUtil.parse<String>(playlistMap, SearchYTParseKeys.topCardTitle)??'';
    fileGroup.detail = ParseUtil.parse<String>(playlistMap, SearchYTParseKeys.topCardSubtitle);
    fileGroup.displayName = fileGroup.name;
    await DataSyncUtil.syncFileGroup(fileGroup);
    return fileGroup;
  }

  static Future<List> parseSearchChildren(List childrenMapList, {FileGroup? fileGroup, MediaSourceInterface? source}) async {
    List children = [];
    for(final childrenMap in childrenMapList){
      if(childrenMap.containsKey(SearchYTParseKeys.channelRenderer)){
        Map childMap = childrenMap[SearchYTParseKeys.channelRenderer];
        ArtistInfo artist = await parseSearchArtist(childMap);
        children.add(artist);
      }
      else if(childrenMap.containsKey(SearchYTParseKeys.playlistItem)){
        Map childMap = childrenMap[SearchYTParseKeys.playlistItem];
        FileGroup playlist = await parseSearchPlaylist(childMap, source: source);
        children.add(playlist);
      }
      else if(childrenMap.containsKey(SearchYTParseKeys.videoRenderer)){
        Map childMap = childrenMap[SearchYTParseKeys.videoRenderer];
        FileInfo fileInfo = await parseSearchVideo(childMap, source: source);
        children.add(fileInfo);
      }
    }
    return children;
  }
  static Future<FileInfo> parseSearchVideo(Map fileInfoMap, {MediaSourceInterface? source}) async {
    FileInfo fileInfo = FileInfo(extension: 'mp4', source: source);
    fileInfo.fileId = ParseUtil.parse<String>(fileInfoMap, SearchYTParseKeys.videoId)??'';
    fileInfo.thumbnail = ParseUtil.parse<String>(fileInfoMap, SearchYTParseKeys.videoCover) ?? 'https://i.ytimg.com/vi/${fileInfo.fileId}/default.jpg';
    fileInfo.name = ParseUtil.parse<String>(fileInfoMap, SearchYTParseKeys.videoTitle)??'';
    fileInfo.artist = ParseUtil.parse<String>(fileInfoMap, SearchYTParseKeys.videoSubtitle);
    fileInfo.uid = ParseUtil.parse<String>(fileInfoMap, SearchYTParseKeys.videoUid);
    await DataSyncUtil.syncFileInfo(fileInfo);
    return fileInfo;
  }
  static Future<ArtistInfo> parseSearchArtist(Map artistMap, {MediaSourceInterface? source}) async {
    ArtistInfo artist = ArtistInfo();
    artist.ytId = ParseUtil.parse<String>(artistMap, SearchYTParseKeys.artistBrowseId);
    artist.thumbnail = ParseUtil.parse<String>(artistMap, SearchYTParseKeys.artistCover)??'';
    if(artist.thumbnail.startsWith('http')==false){
      artist.thumbnail = 'https:${artist.thumbnail}';
    }
    artist.name = ParseUtil.parse<String>(artistMap, SearchYTParseKeys.artistTitle)??'';
    artist.desc = ParseUtil.parse<String>(artistMap, SearchYTParseKeys.artistSubtitle)??'';
    await DataSyncUtil.syncArtist(artist);
    return artist;
  }
  static Future<FileGroup> parseSearchPlaylist(Map playlistMap, {MediaSourceInterface? source}) async {
    FileGroup fileGroup = FileGroup();
    fileGroup.id = ParseUtil.parse<String>(playlistMap, SearchYTParseKeys.playlistId);
    fileGroup.playlistType = ParseUtil.parse<String>(playlistMap, SearchYTParseKeys.playlistType);
    fileGroup.thumbnail = ParseUtil.parse<String>(playlistMap, SearchYTParseKeys.playlistCover)??'';
    fileGroup.name = ParseUtil.parse<String>(playlistMap, SearchYTParseKeys.playlistTitle)??'';
    fileGroup.displayName = fileGroup.name;
    fileGroup.detail = ParseUtil.parse<String>(playlistMap, SearchYTParseKeys.playlistSubtitle);
    await DataSyncUtil.syncFileGroup(fileGroup);
    return fileGroup;
  }
}

class HomeYTParseKeys {
  static List resourceList = [
    'contents',
    'twoColumnBrowseResultsRenderer',
    'tabs',
    {
      ParseUtil.indexKey: 0,
    },
    'tabRenderer',
    'content',
    'richGridRenderer',
    'contents',
  ];

  static String sectionParent = 'richSectionRenderer';

  static List sectionItem = [
    'richSectionRenderer',
    'content',
    'richShelfRenderer',
  ];

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

  static List groupName = [
    'title',
    'runs',
    {
      ParseUtil.indexKey: 0,
    },
    'text',
  ];

  static String richItem = 'richItemRenderer';
  static List videoId = [
    'content',
    'gridVideoRenderer',
    'navigationEndpoint',
    'watchEndpoint',
    'videoId',
  ];
  static List videoTitle = [
    'content',
    'gridVideoRenderer',
    'title',
    'simpleText',
  ];
  static List videoSubtitle = [
    'content',
    'gridVideoRenderer',
    'shortBylineText',
    'runs',
    {ParseUtil.indexKey: 0},
    'text',
  ];
  static List videoCover = [
    'content',
    'gridVideoRenderer',
    'thumbnail',
    'thumbnails',
    {ParseUtil.indexKey: 0},
    'url',
  ];

  static List playlistVideoId = [
    'content',
    'lockupViewModel',
    'contentId',
  ];
  static List playlistVideoTitle = [
    'content',
    'lockupViewModel',
    'metadata',
    'lockupMetadataViewModel',
    'title',
    'content'
  ];
  static List playlistVideoSubtitle = [
    'content',
    'lockupViewModel',
    'metadata',
    'lockupMetadataViewModel',
    'metadata',
    'contentMetadataViewModel',
    'metadataRows',
    {ParseUtil.indexKey: 0},
    'metadataParts',
    {ParseUtil.indexKey: 0},
    'text',
    'content'
  ];
  static List playlistVideoCover = [
    'content',
    'lockupViewModel',
    'contentImage',
    'thumbnailViewModel',
    'image',
    'sources',
    {ParseUtil.indexKey: 3},
    'url',
  ];

  static List playlistId = [
    'content',
    'lockupViewModel',
    'contentId',
  ];
  static List playlistTitle = [
    'content',
    'lockupViewModel',
    'metadata',
    'lockupMetadataViewModel',
    'title',
    'content'
  ];
  static List playlistSubtitle = [
    'content',
    'lockupViewModel',
    'metadata',
    'lockupMetadataViewModel',
    'metadata',
    'contentMetadataViewModel',
    'metadataRows',
    {ParseUtil.indexKey: 0},
    'metadataParts',
    {ParseUtil.indexKey: 0},
    'text',
    'content'
  ];
  static List playlistType = [
    'content',
    'lockupViewModel',
    'contentType',
  ];
  static List playlistCover = [
    'content',
    'lockupViewModel',
    'contentImage',
    'collectionThumbnailViewModel',
    'primaryThumbnail',
    'thumbnailViewModel',
    'image',
    'sources',
    {ParseUtil.indexKey: 0},
    'url',
  ];
}

class PlaylistYTParseKeys {
  static String panel = 'playlistPanelVideoRenderer';

  static List resourceList = [
    'contents',
    'twoColumnWatchNextResults',
    'playlist',
    'playlist',
    'contents',
  ];

  static List videoId = [
    'videoId',
  ];

  static List title = [
    'title',
    'simpleText',
  ];

  static List subtitle = [
    'shortBylineText',
    'runs',
    {ParseUtil.indexKey: 0},
    'text',
  ];

  static List cover = [
    'thumbnail',
    'thumbnails',
    {ParseUtil.indexKey: 0},
    'url',
  ];
}

class PlayRecommendYTParseKeys {
  static String lockupViewModel = 'lockupViewModel';

  static List resourceList = [
    'contents',
    'twoColumnWatchNextResults',
    'secondaryResults',
    'secondaryResults',
    'results',
  ];

  static List videoId = [
    'contentId',
  ];
  static List videoType = [
    'contentType',
  ];


  static List title = [
    'metadata',
    'lockupMetadataViewModel',
    'title',
    'content',
  ];

  static List subtitle = [
    'metadata',
    'lockupMetadataViewModel',
    'metadata',
    'contentMetadataViewModel',
    'metadataRows',
    {ParseUtil.indexKey: 1},
    'metadataParts',
    {ParseUtil.indexKey: 0},
    'text',
    'content',
  ];

  static List cover = [
    'contentImage',
    'thumbnailViewModel',
    'image',
    'sources',
    {ParseUtil.indexKey: 0},
    'url',
  ];
}

class ArtistYTParseKeys {
  static List cover = [
    'header',
    'pageHeaderRenderer',
    'content',
    'pageHeaderViewModel',
    'image',
    'decoratedAvatarViewModel',
    'avatar',
    'avatarViewModel',
    'image',
    'sources',
    {ParseUtil.indexKey: 2},
    'url',
  ];

  static List tabs = [
    'contents',
    'twoColumnBrowseResultsRenderer',
    'tabs',
  ];

  static List tabUrl = [
    'tabRenderer',
    'endpoint',
    'commandMetadata',
    'webCommandMetadata',
    'url',
  ];

  static List tabTitle = [
    'tabRenderer',
    'title',
  ];

  //视频
  static String videos = 'videos';
  //发布作品
  static String releases = 'releases';
  //播放列表
  static String playlists = 'playlists';

  static List params = [
    'tabRenderer',
    'endpoint',
    'browseEndpoint',
    'params',
  ];

  //歌手详情里面的视频和专辑都是richItem
  static String richItem = 'richItemRenderer';
  //音乐和专辑是richItem
  static List richItems = [
    'tabRenderer',
    'content',
    'richGridRenderer',
    'contents',
  ];

  //歌手详情里面的视频start-------------
  static List videoRendererVideoId = [
    'content',
    'videoRenderer',
    'videoId',
  ];
  static List videoRendererVideoTitle = [
    'content',
    'videoRenderer',
    'title',
    'runs',
    {ParseUtil.indexKey: 0},
    'text',
  ];
  static List videoRendererViewCountText = [
    'content',
    'videoRenderer',
    'viewCountText',
    'simpleText',
  ];
  static List videoRendererLengthText = [
    'content',
    'videoRenderer',
    'lengthText',
    'simpleText',
  ];
  static List videoRendererPublishedTimeText = [
    'content',
    'videoRenderer',
    'publishedTimeText',
    'simpleText',
  ];
  static List videoRendererVideoCover = [
    'content',
    'videoRenderer',
    'thumbnail',
    'thumbnails',
    {ParseUtil.indexKey: 0},
    'url',
  ];
  //歌手详情里面的视频end-------------

  //歌手详情里面的专辑start-------------
  static List albumId = [
    'content',
    'playlistRenderer',
    'playlistId',
  ];
  static List albumTitle = [
    'content',
    'playlistRenderer',
    'title',
    'simpleText',
  ];
  static List albumSubtitleRuns = [
    'content',
    'playlistRenderer',
    'shortBylineText',
    'runs',
  ];
  static List albumCover = [
    'content',
    'playlistRenderer',
    'thumbnails',
    {ParseUtil.indexKey: 0},
    'thumbnails',
    {ParseUtil.indexKey: 0},
    'url',
  ];
  //歌手详情里面的专辑end-------------

  //歌手详情里面的播放列表或视频start-------------
  //播放列表的第一层就是lockupViewModel
  //而视频的话上层是richItemRenderer，下一层才是lockupViewModel
  static String lockupViewModelPlaylistItem = 'lockupViewModel';
  static List lockupViewModelVideoItem = [
    'content',
    'lockupViewModel',
  ];
  static List lockupViewModelPlaylistItems = [
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'contents',
    {ParseUtil.indexKey: 0},
    'itemSectionRenderer',
    'contents',
    {ParseUtil.indexKey: 0},
    'gridRenderer',
    'items',
  ];
  static List lockupViewModelId = [
    'contentId',
  ];
  static List lockupViewModelType = [
    'contentType',
  ];
  static List lockupViewModelTitle = [
    'metadata',
    'lockupMetadataViewModel',
    'title',
    'content',
  ];
  static List lockupViewModelSubtitle = [
    'content',
    'lockupViewModel',
    'metadata',
    'lockupMetadataViewModel',
    'metadata',
    'contentMetadataViewModel',
    'metadataRows',
    {ParseUtil.indexKey: 0},
    'metadataParts',
    {ParseUtil.indexKey: 0},
    'text',
    'content',
  ];
  static List lockupViewModelPlaylistCover = [
    'contentImage',
    'collectionThumbnailViewModel',
    'primaryThumbnail',
    'thumbnailViewModel',
    'image',
    'sources',
    {ParseUtil.indexKey: 0},
    'url',
  ];
  static List lockupViewModelVideoCover = [
    'content',
    'lockupViewModel',
    'contentImage',
    'thumbnailViewModel',
    'image',
    'sources',
    {ParseUtil.indexKey: 0},
    'url',
  ];
  //歌手详情里面的播放列表end-------------
}

class SearchYTParseKeys {
  ///最佳搜索(可能没有)start-------------
  //最佳搜索有最佳搜索的卡片和下面带的列表
  //有这个表示有最佳搜索
  static List topUniversalWatchCardRenderer = [
    'contents',
    'twoColumnSearchResultsRenderer',
    'secondaryContents',
    'secondarySearchContainerRenderer',
    'contents',
    {ParseUtil.filterKey:'universalWatchCardRenderer'},
    {ParseUtil.indexKey: 0},
    'universalWatchCardRenderer',
  ];

  //可能是专辑，可能是歌手
  static String topCard = 'header';
  static String topCardItem = 'watchCardRichHeaderRenderer';
  static List topCardPageType = [
    'titleNavigationEndpoint',
    'commandMetadata',
    'webCommandMetadata',
    'webPageType',
  ];
  static List topCardBrowseId = [
    'titleNavigationEndpoint',
    'browseEndpoint',
    'browseId',
  ];
  static List topCardTitle = [
    'title',
    'simpleText',
  ];
  static List topCardSubtitle = [
    'subtitle',
    'simpleText',
  ];
  static List topCardAlbumCover = [
    ...topUniversalWatchCardRenderer,
    'callToAction',
    'watchCardHeroVideoRenderer',
    'heroImage',
    'singleHeroImageRenderer',
    'thumbnail',
    'thumbnails',
    {ParseUtil.indexKey: 0},
    'url',
  ];
  static List topCardArtistCover = [
    'avatar',
    'thumbnails',
    {ParseUtil.indexKey: 0},
    'url',
  ];

  //最佳搜索下面带的列表
  static List topVideoFileGroupFilterItems = [
    'sections',
    {ParseUtil.filterKey:'watchCardSectionSequenceRenderer'},
  ];
  static List topVideoFileGroupItems = [
    'watchCardSectionSequenceRenderer',
    'lists',
    {ParseUtil.filterKey:'verticalWatchCardListRenderer'},
    {ParseUtil.indexKey:0},
    'verticalWatchCardListRenderer',
    'items'
  ];

  static String topVideoItem = 'watchCardCompactVideoRenderer';
  static List topVideoId = [
    'navigationEndpoint',
    'watchEndpoint',
    'videoId',
  ];
  static List topVideoTitle = [
    'title',
    'simpleText',
  ];
  static List topVideoSubtitle = [
    'subtitle',
    'simpleText',
  ];
  static List topVideoSubtitle1 = [
    'subtitle',
    'runs',
    {ParseUtil.indexKey: 0},
    'text',
  ];
  ///最佳搜索(可能没有)end-------------

  static List resourceList = [
    'contents',
    'twoColumnSearchResultsRenderer',
    'primaryContents',
    'sectionListRenderer',
    'contents',
    {ParseUtil.filterKey:'itemSectionRenderer'},
    {ParseUtil.indexKey: 0},
    'itemSectionRenderer',
    'contents',
  ];

  static List moreResourceList = [
    'onResponseReceivedCommands',
    {ParseUtil.indexKey: 0},
    'appendContinuationItemsAction',
    'continuationItems',
    {ParseUtil.filterKey:'itemSectionRenderer'},
    {ParseUtil.indexKey: 0},
    'itemSectionRenderer',
    'contents',
  ];

  //翻页参数
  static List continuation = [
    'contents',
    'twoColumnSearchResultsRenderer',
    'primaryContents',
    'sectionListRenderer',
    'contents',
    {ParseUtil.filterKey:'continuationItemRenderer'},
    {ParseUtil.indexKey: 0},
    'continuationItemRenderer',
    'continuationEndpoint',
    'continuationCommand',
    'token',
  ];

  static List moreContinuation = [
    'onResponseReceivedCommands',
    {ParseUtil.indexKey: 0},
    'appendContinuationItemsAction',
    'continuationItems',
    {ParseUtil.filterKey:'continuationItemRenderer'},
    {ParseUtil.indexKey: 0},
    'continuationItemRenderer',
    'continuationEndpoint',
    'continuationCommand',
    'token',
  ];

  //搜索列表里面的视频start-------------
  static String videoRenderer = 'videoRenderer';
  static List videoId = [
    'videoId',
  ];
  static List videoCover = [
    'thumbnail',
    'thumbnails',
    {ParseUtil.indexKey: 0},
    'url',
  ];
  static List videoTitle = [
    'title',
    'runs',
    {ParseUtil.indexKey: 0},
    'text',
  ];
  static List videoSubtitle = [
    'ownerText',
    'runs',
    {ParseUtil.indexKey: 0},
    'text',
  ];
  static List videoUid = [
    'ownerText',
    'runs',
    {ParseUtil.indexKey: 0},
    'navigationEndpoint',
    'browseEndpoint',
    'browseId',
  ];
  //搜索列表里面的视频end-------------

  //搜索列表里面的播放列表start-------------
  static String playlistItem = 'lockupViewModel';
  static List playlistId = [
    'contentId',
  ];
  static List playlistType = [
    'contentType',
  ];
  static List playlistTitle = [
    'metadata',
    'lockupMetadataViewModel',
    'title',
    'content',
  ];
  static List playlistSubtitle = [
    'metadata',
    'lockupMetadataViewModel',
    'metadata',
    'contentMetadataViewModel',
    'metadataRows',
    {ParseUtil.indexKey:0},
    'metadataParts',
    {ParseUtil.indexKey:0},
    'text',
    'content',
  ];
  static List playlistCover = [
    'contentImage',
    'collectionThumbnailViewModel',
    'primaryThumbnail',
    'thumbnailViewModel',
    'image',
    'sources',
    {ParseUtil.indexKey: 0},
    'url',
  ];
  //搜索列表里面的播放列表end-------------

  //搜索列表里面的歌手start-------------
  static String channelRenderer = 'channelRenderer';
  static List artistBrowseId = [
    'channelId',
  ];
  static List artistTitle = [
    'title',
    'simpleText',
  ];
  static List artistSubtitle = [
    'videoCountText',
    'simpleText',
  ];
  static List artistCover = [
    'thumbnail',
    'thumbnails',
    {ParseUtil.indexKey: 0},
    'url',
  ];
  //搜索列表里面的歌手end-------------
}