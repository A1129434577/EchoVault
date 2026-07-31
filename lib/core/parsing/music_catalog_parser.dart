import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/core/parsing/shared_parser.dart';
import 'package:echo_vault/core/parsing/record_sync_helper.dart';
import 'package:echo_vault/core/parsing/parser_helper.dart';

///解析Youtube
class MusicCatalogParser {
  static Future<List<MediaCollection>> parseHomeContents(
    List groupMapList, {
    MediaSourceInterface? source,
  }) async {
    List<MediaCollection> list = [];
    for (Map groupMap in groupMapList) {
      if (groupMap.containsKey(DiscoveryCatalogParserKeys.sectionParent)) {
        groupMap =
            ParserHelper.parse<Map>(
              groupMap,
              DiscoveryCatalogParserKeys.sectionItem,
            ) ??
            {};
        MediaCollection mediaCollection =
            await MusicCatalogParser.parseHomeFileGroup(
              groupMap,
              source: source,
            );
        list.add(mediaCollection);
      }
    }
    return list;
  }

  ///解析Youtube(非Youtube Music)首页数据
  static Future<MediaCollection> parseHomeFileGroup(
    Map fileGroupMap, {
    MediaSourceInterface? source,
  }) async {
    MediaCollection mediaCollection = MediaCollection();
    mediaCollection.id = ParserHelper.parse<String>(
      fileGroupMap,
      DiscoveryCatalogParserKeys.groupId,
    );
    mediaCollection.name =
        ParserHelper.parse<String>(
          fileGroupMap,
          DiscoveryCatalogParserKeys.groupName,
        ) ??
        '';
    List childrenMapList = fileGroupMap[SharedParserKeys.children] ?? [];
    List children = await parseHomeChildren(
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

  static Future<List> parseHomeChildren(
    List childrenMapList, {
    MediaCollection? mediaCollection,
    MediaSourceInterface? source,
  }) async {
    List children = [];
    for (final childrenMap in childrenMapList) {
      if (childrenMap.containsKey(DiscoveryCatalogParserKeys.richItem)) {
        Map childMap = childrenMap[DiscoveryCatalogParserKeys.richItem];
        String? playlistType = ParserHelper.parse<String>(
          childMap,
          DiscoveryCatalogParserKeys.playlistType,
        );
        String? videoId = ParserHelper.parse<String>(
          childMap,
          DiscoveryCatalogParserKeys.videoId,
        );
        if (playlistType == CollectionType.LOCKUP_CONTENT_TYPE_ALBUM.name ||
            playlistType == CollectionType.LOCKUP_CONTENT_TYPE_PLAYLIST.name) {
          MediaCollection playlist = await parseHomePlaylist(
            childMap,
            source: source,
          );
          playlist.playlistType = playlistType;
          children.add(playlist);
        } else if (playlistType == MediaType.LOCKUP_CONTENT_TYPE_VIDEO.name) {
          FileInfo mediaDetails = await parseHomePlaylistVideo(
            childMap,
            source: source,
          );
          //B面parentId只用于埋点，无其他实际逻辑
          mediaDetails.parentId = mediaCollection?.name;
          children.add(mediaDetails);
        } else if (videoId != null) {
          FileInfo mediaDetails = await parseHomeVideo(
            childMap,
            source: source,
          );
          //B面parentId只用于埋点，无其他实际逻辑
          mediaDetails.parentId = mediaCollection?.name;
          children.add(mediaDetails);
        }
      }
    }
    return children;
  }

  static Future<FileInfo> parseHomeVideo(
    Map fileInfoMap, {
    MediaSourceInterface? source,
  }) async {
    FileInfo mediaDetails = FileInfo(extension: 'mp4', source: source);
    mediaDetails.fileId =
        ParserHelper.parse<String>(
          fileInfoMap,
          DiscoveryCatalogParserKeys.videoId,
        ) ??
        '';
    mediaDetails.thumbnail =
        ParserHelper.parse<String>(
          fileInfoMap,
          DiscoveryCatalogParserKeys.videoCover,
        ) ??
        'https://i.ytimg.com/vi/${mediaDetails.fileId}/default.jpg';
    mediaDetails.name =
        ParserHelper.parse<String>(
          fileInfoMap,
          DiscoveryCatalogParserKeys.videoTitle,
        ) ??
        '';
    mediaDetails.artist = ParserHelper.parse<String>(
      fileInfoMap,
      DiscoveryCatalogParserKeys.videoSubtitle,
    );
    await RecordSyncHelper.syncFileInfo(mediaDetails);
    return mediaDetails;
  }

  static Future<FileInfo> parseHomePlaylistVideo(
    Map fileInfoMap, {
    MediaSourceInterface? source,
  }) async {
    FileInfo mediaDetails = FileInfo(extension: 'mp4', source: source);
    mediaDetails.fileId =
        ParserHelper.parse<String>(
          fileInfoMap,
          DiscoveryCatalogParserKeys.playlistVideoId,
        ) ??
        '';
    mediaDetails.thumbnail =
        ParserHelper.parse<String>(
          fileInfoMap,
          DiscoveryCatalogParserKeys.playlistVideoCover,
        ) ??
        'https://i.ytimg.com/vi/${mediaDetails.fileId}/default.jpg';
    mediaDetails.name =
        ParserHelper.parse<String>(
          fileInfoMap,
          DiscoveryCatalogParserKeys.playlistVideoTitle,
        ) ??
        '';
    mediaDetails.artist = ParserHelper.parse<String>(
      fileInfoMap,
      DiscoveryCatalogParserKeys.playlistVideoSubtitle,
    );
    await RecordSyncHelper.syncFileInfo(mediaDetails);
    return mediaDetails;
  }

  static Future<MediaCollection> parseHomePlaylist(
    Map playlistMap, {
    MediaSourceInterface? source,
  }) async {
    MediaCollection mediaCollection = MediaCollection();
    mediaCollection.id = ParserHelper.parse<String>(
      playlistMap,
      DiscoveryCatalogParserKeys.playlistId,
    );
    mediaCollection.thumbnail =
        ParserHelper.parse<String>(
          playlistMap,
          DiscoveryCatalogParserKeys.playlistCover,
        ) ??
        '';
    mediaCollection.name =
        ParserHelper.parse<String>(
          playlistMap,
          DiscoveryCatalogParserKeys.playlistTitle,
        ) ??
        '';
    mediaCollection.displayName = mediaCollection.name;
    mediaCollection.detail = ParserHelper.parse<String>(
      playlistMap,
      DiscoveryCatalogParserKeys.playlistSubtitle,
    );
    await RecordSyncHelper.syncFileGroup(mediaCollection);
    return mediaCollection;
  }

  static Future<List> parsePlaylistChildren(
    List childrenMapList, {
    MediaCollection? mediaCollection,
    MediaSourceInterface? source,
  }) async {
    List children = [];
    for (final childrenMap in childrenMapList) {
      if (childrenMap.containsKey(CollectionCatalogParserKeys.panel)) {
        Map childMap = childrenMap[CollectionCatalogParserKeys.panel];
        String? videoId = ParserHelper.parse<String>(
          childMap,
          CollectionCatalogParserKeys.videoId,
        );
        if (videoId != null) {
          FileInfo mediaDetails = await parsePlaylistVideo(
            childMap,
            source: source,
          );
          mediaDetails.fileId = videoId;
          //B面parentId只用于埋点，无其他实际逻辑
          mediaDetails.parentId = mediaCollection?.name;
          children.add(mediaDetails);
        }
      }
    }
    return children;
  }

  static Future<FileInfo> parsePlaylistVideo(
    Map fileInfoMap, {
    MediaSourceInterface? source,
  }) async {
    FileInfo mediaDetails = FileInfo(extension: 'mp4', source: source);
    mediaDetails.fileId =
        ParserHelper.parse<String>(
          fileInfoMap,
          CollectionCatalogParserKeys.videoId,
        ) ??
        '';
    mediaDetails.thumbnail =
        ParserHelper.parse<String>(
          fileInfoMap,
          CollectionCatalogParserKeys.cover,
        ) ??
        'https://i.ytimg.com/vi/${mediaDetails.fileId}/default.jpg';
    mediaDetails.name =
        ParserHelper.parse<String>(
          fileInfoMap,
          CollectionCatalogParserKeys.title,
        ) ??
        '';
    mediaDetails.artist = ParserHelper.parse<String>(
      fileInfoMap,
      CollectionCatalogParserKeys.subtitle,
    );
    await RecordSyncHelper.syncFileInfo(mediaDetails);
    return mediaDetails;
  }

  static Future<List> parsePlayRecommendChildren(
    List childrenMapList, {
    MediaCollection? mediaCollection,
    MediaSourceInterface? source,
  }) async {
    List children = [];
    for (final childrenMap in childrenMapList) {
      if (childrenMap.containsKey(
        PlaybackSuggestionParserKeys.lockupViewModel,
      )) {
        Map childMap =
            childrenMap[PlaybackSuggestionParserKeys.lockupViewModel];
        String? videoId = ParserHelper.parse<String>(
          childMap,
          PlaybackSuggestionParserKeys.videoId,
        );
        if (videoId != null) {
          FileInfo mediaDetails = await parsePlayRecommendVideo(
            childMap,
            source: source,
          );
          mediaDetails.fileId = videoId;
          //B面parentId只用于埋点，无其他实际逻辑
          mediaDetails.parentId = mediaCollection?.name;
          children.add(mediaDetails);
        }
      }
    }
    return children;
  }

  static Future<FileInfo> parsePlayRecommendVideo(
    Map fileInfoMap, {
    MediaSourceInterface? source,
  }) async {
    FileInfo mediaDetails = FileInfo(extension: 'mp4', source: source);
    mediaDetails.fileId =
        ParserHelper.parse<String>(
          fileInfoMap,
          PlaybackSuggestionParserKeys.videoId,
        ) ??
        '';
    mediaDetails.thumbnail =
        ParserHelper.parse<String>(
          fileInfoMap,
          PlaybackSuggestionParserKeys.cover,
        ) ??
        'https://i.ytimg.com/vi/${mediaDetails.fileId}/default.jpg';
    mediaDetails.name =
        ParserHelper.parse<String>(
          fileInfoMap,
          PlaybackSuggestionParserKeys.title,
        ) ??
        '';
    mediaDetails.artist = ParserHelper.parse<String>(
      fileInfoMap,
      PlaybackSuggestionParserKeys.subtitle,
    );
    await RecordSyncHelper.syncFileInfo(mediaDetails);
    return mediaDetails;
  }

  static Future<List> parseArtistChildren(
    List childrenMapList, {
    MediaCollection? mediaCollection,
    MediaSourceInterface? source,
  }) async {
    List children = [];
    for (final childrenMap in childrenMapList) {
      if (childrenMap.containsKey(PerformerCatalogParserKeys.richItem)) {
        Map childMap = childrenMap[PerformerCatalogParserKeys.richItem];
        String? playlistId = ParserHelper.parse<String>(
          childMap,
          PerformerCatalogParserKeys.albumId,
        );
        String? videoRendererVideoId = ParserHelper.parse<String>(
          childMap,
          PerformerCatalogParserKeys.videoRendererVideoId,
        );
        Map? lockupViewModel = ParserHelper.parse<Map>(
          childMap,
          PerformerCatalogParserKeys.lockupViewModelVideoItem,
        );
        if (videoRendererVideoId != null) {
          FileInfo mediaDetails = await parseArtistVideoRendererVideo(
            childMap,
            source: source,
          );
          //B面parentId只用于埋点，无其他实际逻辑
          mediaDetails.parentId = mediaCollection?.name;
          children.add(mediaDetails);
        } else if (lockupViewModel != null) {
          FileInfo mediaDetails = await parseArtistLockupViewModelVideo(
            lockupViewModel,
            source: source,
          );
          //B面parentId只用于埋点，无其他实际逻辑
          mediaDetails.parentId = mediaCollection?.name;
          children.add(mediaDetails);
        } else if (playlistId != null) {
          MediaCollection playlist = await parseArtistAlbum(
            childMap,
            source: source,
          );
          playlist.playlistType = CollectionType.LOCKUP_CONTENT_TYPE_ALBUM.name;
          playlist.id = playlistId;
          children.add(playlist);
        }
      } else if (childrenMap.containsKey(
        PerformerCatalogParserKeys.lockupViewModelPlaylistItem,
      )) {
        Map childMap =
            childrenMap[PerformerCatalogParserKeys.lockupViewModelPlaylistItem];
        String? playlistId = ParserHelper.parse<String>(
          childMap,
          PerformerCatalogParserKeys.lockupViewModelId,
        );
        if (playlistId != null) {
          MediaCollection playlist = await parseArtistPlaylist(
            childMap,
            source: source,
          );
          playlist.id = playlistId;
          children.add(playlist);
        }
      }
    }
    return children;
  }

  static Future<FileInfo> parseArtistVideoRendererVideo(
    Map fileInfoMap, {
    MediaSourceInterface? source,
  }) async {
    FileInfo mediaDetails = FileInfo(extension: 'mp4', source: source);
    mediaDetails.fileId =
        ParserHelper.parse<String>(
          fileInfoMap,
          PerformerCatalogParserKeys.videoRendererVideoId,
        ) ??
        '';
    mediaDetails.thumbnail =
        ParserHelper.parse<String>(
          fileInfoMap,
          PerformerCatalogParserKeys.videoRendererVideoCover,
        ) ??
        'https://i.ytimg.com/vi/${mediaDetails.fileId}/default.jpg';
    mediaDetails.name =
        ParserHelper.parse<String>(
          fileInfoMap,
          PerformerCatalogParserKeys.videoRendererVideoTitle,
        ) ??
        '';
    String? viewCountText = ParserHelper.parse<String>(
      fileInfoMap,
      PerformerCatalogParserKeys.videoRendererViewCountText,
    );
    String? lengthText = ParserHelper.parse<String>(
      fileInfoMap,
      PerformerCatalogParserKeys.videoRendererLengthText,
    );
    String? publishedTimeText = ParserHelper.parse<String>(
      fileInfoMap,
      PerformerCatalogParserKeys.videoRendererPublishedTimeText,
    );
    mediaDetails.artist = [
      viewCountText,
      lengthText,
      publishedTimeText,
    ].join(' • ');
    await RecordSyncHelper.syncFileInfo(mediaDetails);
    return mediaDetails;
  }

  static Future<FileInfo> parseArtistLockupViewModelVideo(
    Map fileInfoMap, {
    MediaSourceInterface? source,
  }) async {
    FileInfo mediaDetails = FileInfo(extension: 'mp4', source: source);
    mediaDetails.fileId =
        ParserHelper.parse<String>(
          fileInfoMap,
          PerformerCatalogParserKeys.lockupViewModelId,
        ) ??
        '';
    mediaDetails.type = ParserHelper.parse<String>(
      fileInfoMap,
      PerformerCatalogParserKeys.lockupViewModelType,
    );
    mediaDetails.thumbnail =
        ParserHelper.parse<String>(
          fileInfoMap,
          PerformerCatalogParserKeys.lockupViewModelVideoCover,
        ) ??
        'https://i.ytimg.com/vi/${mediaDetails.fileId}/default.jpg';
    mediaDetails.name =
        ParserHelper.parse<String>(
          fileInfoMap,
          PerformerCatalogParserKeys.lockupViewModelTitle,
        ) ??
        '';
    mediaDetails.artist =
        ParserHelper.parse<String>(
          fileInfoMap,
          PerformerCatalogParserKeys.lockupViewModelSubtitle,
        ) ??
        '';
    await RecordSyncHelper.syncFileInfo(mediaDetails);
    return mediaDetails;
  }

  static Future<MediaCollection> parseArtistAlbum(
    Map playlistMap, {
    MediaSourceInterface? source,
  }) async {
    MediaCollection mediaCollection = MediaCollection();
    mediaCollection.thumbnail =
        ParserHelper.parse<String>(
          playlistMap,
          PerformerCatalogParserKeys.albumCover,
        ) ??
        '';
    mediaCollection.name =
        ParserHelper.parse<String>(
          playlistMap,
          PerformerCatalogParserKeys.albumTitle,
        ) ??
        '';
    mediaCollection.displayName = mediaCollection.name;
    String subtitle = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              playlistMap,
              PerformerCatalogParserKeys.albumSubtitleRuns,
            ) ??
            []) {
      subtitle += textRun['text'];
    }
    mediaCollection.detail = subtitle;
    await RecordSyncHelper.syncFileGroup(mediaCollection);
    return mediaCollection;
  }

  static Future<MediaCollection> parseArtistPlaylist(
    Map playlistMap, {
    MediaSourceInterface? source,
  }) async {
    MediaCollection mediaCollection = MediaCollection();
    mediaCollection.playlistType = ParserHelper.parse<String>(
      playlistMap,
      PerformerCatalogParserKeys.lockupViewModelType,
    );
    mediaCollection.thumbnail =
        ParserHelper.parse<String>(
          playlistMap,
          PerformerCatalogParserKeys.lockupViewModelPlaylistCover,
        ) ??
        '';
    mediaCollection.name =
        ParserHelper.parse<String>(
          playlistMap,
          PerformerCatalogParserKeys.lockupViewModelTitle,
        ) ??
        '';
    mediaCollection.displayName = mediaCollection.name;
    await RecordSyncHelper.syncFileGroup(mediaCollection);
    return mediaCollection;
  }

  static Future<List> parseSearchTopChildren(
    List childrenMapList, {
    MediaCollection? mediaCollection,
    MediaSourceInterface? source,
  }) async {
    List children = [];
    for (final childrenMap in childrenMapList) {
      if (childrenMap.containsKey(SearchCatalogParserKeys.topVideoItem)) {
        Map childMap = childrenMap[SearchCatalogParserKeys.topVideoItem];
        FileInfo mediaDetails = await parseSearchTopVideo(
          childMap,
          source: source,
        );
        //B面parentId只用于埋点，无其他实际逻辑
        mediaDetails.parentId = mediaCollection?.name;
        children.add(mediaDetails);
      } else if (childrenMap.containsKey(SearchCatalogParserKeys.topCardItem)) {
        Map childMap = childrenMap[SearchCatalogParserKeys.topCardItem];
        String? pageType = ParserHelper.parse<String>(
          childMap,
          SearchCatalogParserKeys.topCardPageType,
        );
        if (pageType == PerformerDetails.ytSearchTypeName) {
          PerformerDetails artist = await parseSearchTopCardArtist(childMap);
          children.add(artist);
        } else if (pageType == CollectionType.WEB_PAGE_TYPE_PLAYLIST.name) {
          MediaCollection mediaCollection = await parseSearchTopCardPlaylist(
            childMap,
          );
          mediaCollection.playlistType = pageType;
          children.add(mediaCollection);
        }
      }
    }
    return children;
  }

  static Future<FileInfo> parseSearchTopVideo(
    Map fileInfoMap, {
    MediaSourceInterface? source,
  }) async {
    FileInfo mediaDetails = FileInfo(extension: 'mp4', source: source);
    mediaDetails.fileId =
        ParserHelper.parse<String>(
          fileInfoMap,
          SearchCatalogParserKeys.topVideoId,
        ) ??
        '';
    mediaDetails.thumbnail =
        'https://i.ytimg.com/vi/${mediaDetails.fileId}/default.jpg';
    mediaDetails.name =
        ParserHelper.parse<String>(
          fileInfoMap,
          SearchCatalogParserKeys.topVideoTitle,
        ) ??
        '';
    mediaDetails.artist =
        ParserHelper.parse<String>(
          fileInfoMap,
          SearchCatalogParserKeys.topVideoSubtitle,
        ) ??
        ParserHelper.parse<String>(
          fileInfoMap,
          SearchCatalogParserKeys.topVideoSubtitle1,
        );
    await RecordSyncHelper.syncFileInfo(mediaDetails);
    return mediaDetails;
  }

  static Future<PerformerDetails> parseSearchTopCardArtist(
    Map artistMap, {
    MediaSourceInterface? source,
  }) async {
    PerformerDetails artist = PerformerDetails();
    artist.ytId = ParserHelper.parse<String>(
      artistMap,
      SearchCatalogParserKeys.topCardBrowseId,
    );
    artist.thumbnail =
        ParserHelper.parse<String>(
          artistMap,
          SearchCatalogParserKeys.topCardArtistCover,
        ) ??
        '';
    artist.name =
        ParserHelper.parse<String>(
          artistMap,
          SearchCatalogParserKeys.topCardTitle,
        ) ??
        '';
    artist.desc =
        ParserHelper.parse<String>(
          artistMap,
          SearchCatalogParserKeys.topCardSubtitle,
        ) ??
        '';
    await RecordSyncHelper.syncArtist(artist);
    return artist;
  }

  static Future<MediaCollection> parseSearchTopCardPlaylist(
    Map playlistMap, {
    MediaSourceInterface? source,
  }) async {
    MediaCollection mediaCollection = MediaCollection();
    mediaCollection.id = ParserHelper.parse<String>(
      playlistMap,
      SearchCatalogParserKeys.topCardBrowseId,
    );
    mediaCollection.name =
        ParserHelper.parse<String>(
          playlistMap,
          SearchCatalogParserKeys.topCardTitle,
        ) ??
        '';
    mediaCollection.detail = ParserHelper.parse<String>(
      playlistMap,
      SearchCatalogParserKeys.topCardSubtitle,
    );
    mediaCollection.displayName = mediaCollection.name;
    await RecordSyncHelper.syncFileGroup(mediaCollection);
    return mediaCollection;
  }

  static Future<List> parseSearchChildren(
    List childrenMapList, {
    MediaCollection? mediaCollection,
    MediaSourceInterface? source,
  }) async {
    List children = [];
    for (final childrenMap in childrenMapList) {
      if (childrenMap.containsKey(SearchCatalogParserKeys.channelRenderer)) {
        Map childMap = childrenMap[SearchCatalogParserKeys.channelRenderer];
        PerformerDetails artist = await parseSearchArtist(childMap);
        children.add(artist);
      } else if (childrenMap.containsKey(
        SearchCatalogParserKeys.playlistItem,
      )) {
        Map childMap = childrenMap[SearchCatalogParserKeys.playlistItem];
        MediaCollection playlist = await parseSearchPlaylist(
          childMap,
          source: source,
        );
        children.add(playlist);
      } else if (childrenMap.containsKey(
        SearchCatalogParserKeys.videoRenderer,
      )) {
        Map childMap = childrenMap[SearchCatalogParserKeys.videoRenderer];
        FileInfo mediaDetails = await parseSearchVideo(
          childMap,
          source: source,
        );
        children.add(mediaDetails);
      }
    }
    return children;
  }

  static Future<FileInfo> parseSearchVideo(
    Map fileInfoMap, {
    MediaSourceInterface? source,
  }) async {
    FileInfo mediaDetails = FileInfo(extension: 'mp4', source: source);
    mediaDetails.fileId =
        ParserHelper.parse<String>(
          fileInfoMap,
          SearchCatalogParserKeys.videoId,
        ) ??
        '';
    mediaDetails.thumbnail =
        ParserHelper.parse<String>(
          fileInfoMap,
          SearchCatalogParserKeys.videoCover,
        ) ??
        'https://i.ytimg.com/vi/${mediaDetails.fileId}/default.jpg';
    mediaDetails.name =
        ParserHelper.parse<String>(
          fileInfoMap,
          SearchCatalogParserKeys.videoTitle,
        ) ??
        '';
    mediaDetails.artist = ParserHelper.parse<String>(
      fileInfoMap,
      SearchCatalogParserKeys.videoSubtitle,
    );
    mediaDetails.uid = ParserHelper.parse<String>(
      fileInfoMap,
      SearchCatalogParserKeys.videoUid,
    );
    await RecordSyncHelper.syncFileInfo(mediaDetails);
    return mediaDetails;
  }

  static Future<PerformerDetails> parseSearchArtist(
    Map artistMap, {
    MediaSourceInterface? source,
  }) async {
    PerformerDetails artist = PerformerDetails();
    artist.ytId = ParserHelper.parse<String>(
      artistMap,
      SearchCatalogParserKeys.artistBrowseId,
    );
    artist.thumbnail =
        ParserHelper.parse<String>(
          artistMap,
          SearchCatalogParserKeys.artistCover,
        ) ??
        '';
    if (artist.thumbnail.startsWith('http') == false) {
      artist.thumbnail = 'https:${artist.thumbnail}';
    }
    artist.name =
        ParserHelper.parse<String>(
          artistMap,
          SearchCatalogParserKeys.artistTitle,
        ) ??
        '';
    artist.desc =
        ParserHelper.parse<String>(
          artistMap,
          SearchCatalogParserKeys.artistSubtitle,
        ) ??
        '';
    await RecordSyncHelper.syncArtist(artist);
    return artist;
  }

  static Future<MediaCollection> parseSearchPlaylist(
    Map playlistMap, {
    MediaSourceInterface? source,
  }) async {
    MediaCollection mediaCollection = MediaCollection();
    mediaCollection.id = ParserHelper.parse<String>(
      playlistMap,
      SearchCatalogParserKeys.playlistId,
    );
    mediaCollection.playlistType = ParserHelper.parse<String>(
      playlistMap,
      SearchCatalogParserKeys.playlistType,
    );
    mediaCollection.thumbnail =
        ParserHelper.parse<String>(
          playlistMap,
          SearchCatalogParserKeys.playlistCover,
        ) ??
        '';
    mediaCollection.name =
        ParserHelper.parse<String>(
          playlistMap,
          SearchCatalogParserKeys.playlistTitle,
        ) ??
        '';
    mediaCollection.displayName = mediaCollection.name;
    mediaCollection.detail = ParserHelper.parse<String>(
      playlistMap,
      SearchCatalogParserKeys.playlistSubtitle,
    );
    await RecordSyncHelper.syncFileGroup(mediaCollection);
    return mediaCollection;
  }
}

class DiscoveryCatalogParserKeys {
  static List resourceList = [
    'contents',
    'twoColumnBrowseResultsRenderer',
    'tabs',
    {ParserHelper.indexKey: 0},
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
    {ParserHelper.indexKey: 0},
    'navigationEndpoint',
    'browseEndpoint',
    'browseId',
  ];

  static List groupName = [
    'title',
    'runs',
    {ParserHelper.indexKey: 0},
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
    {ParserHelper.indexKey: 0},
    'text',
  ];
  static List videoCover = [
    'content',
    'gridVideoRenderer',
    'thumbnail',
    'thumbnails',
    {ParserHelper.indexKey: 0},
    'url',
  ];

  static List playlistVideoId = ['content', 'lockupViewModel', 'contentId'];
  static List playlistVideoTitle = [
    'content',
    'lockupViewModel',
    'metadata',
    'lockupMetadataViewModel',
    'title',
    'content',
  ];
  static List playlistVideoSubtitle = [
    'content',
    'lockupViewModel',
    'metadata',
    'lockupMetadataViewModel',
    'metadata',
    'contentMetadataViewModel',
    'metadataRows',
    {ParserHelper.indexKey: 0},
    'metadataParts',
    {ParserHelper.indexKey: 0},
    'text',
    'content',
  ];
  static List playlistVideoCover = [
    'content',
    'lockupViewModel',
    'contentImage',
    'thumbnailViewModel',
    'image',
    'sources',
    {ParserHelper.indexKey: 3},
    'url',
  ];

  static List playlistId = ['content', 'lockupViewModel', 'contentId'];
  static List playlistTitle = [
    'content',
    'lockupViewModel',
    'metadata',
    'lockupMetadataViewModel',
    'title',
    'content',
  ];
  static List playlistSubtitle = [
    'content',
    'lockupViewModel',
    'metadata',
    'lockupMetadataViewModel',
    'metadata',
    'contentMetadataViewModel',
    'metadataRows',
    {ParserHelper.indexKey: 0},
    'metadataParts',
    {ParserHelper.indexKey: 0},
    'text',
    'content',
  ];
  static List playlistType = ['content', 'lockupViewModel', 'contentType'];
  static List playlistCover = [
    'content',
    'lockupViewModel',
    'contentImage',
    'collectionThumbnailViewModel',
    'primaryThumbnail',
    'thumbnailViewModel',
    'image',
    'sources',
    {ParserHelper.indexKey: 0},
    'url',
  ];
}

class CollectionCatalogParserKeys {
  static String panel = 'playlistPanelVideoRenderer';

  static List resourceList = [
    'contents',
    'twoColumnWatchNextResults',
    'playlist',
    'playlist',
    'contents',
  ];

  static List videoId = ['videoId'];

  static List title = ['title', 'simpleText'];

  static List subtitle = [
    'shortBylineText',
    'runs',
    {ParserHelper.indexKey: 0},
    'text',
  ];

  static List cover = [
    'thumbnail',
    'thumbnails',
    {ParserHelper.indexKey: 0},
    'url',
  ];
}

class PlaybackSuggestionParserKeys {
  static String lockupViewModel = 'lockupViewModel';

  static List resourceList = [
    'contents',
    'twoColumnWatchNextResults',
    'secondaryResults',
    'secondaryResults',
    'results',
  ];

  static List videoId = ['contentId'];
  static List videoType = ['contentType'];

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
    {ParserHelper.indexKey: 1},
    'metadataParts',
    {ParserHelper.indexKey: 0},
    'text',
    'content',
  ];

  static List cover = [
    'contentImage',
    'thumbnailViewModel',
    'image',
    'sources',
    {ParserHelper.indexKey: 0},
    'url',
  ];
}

class PerformerCatalogParserKeys {
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
    {ParserHelper.indexKey: 2},
    'url',
  ];

  static List tabs = ['contents', 'twoColumnBrowseResultsRenderer', 'tabs'];

  static List tabUrl = [
    'tabRenderer',
    'endpoint',
    'commandMetadata',
    'webCommandMetadata',
    'url',
  ];

  static List tabTitle = ['tabRenderer', 'title'];

  //视频
  static String videos = 'videos';
  //发布作品
  static String releases = 'releases';
  //播放列表
  static String playlists = 'playlists';

  static List params = ['tabRenderer', 'endpoint', 'browseEndpoint', 'params'];

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
  static List videoRendererVideoId = ['content', 'videoRenderer', 'videoId'];
  static List videoRendererVideoTitle = [
    'content',
    'videoRenderer',
    'title',
    'runs',
    {ParserHelper.indexKey: 0},
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
    {ParserHelper.indexKey: 0},
    'url',
  ];
  //歌手详情里面的视频end-------------

  //歌手详情里面的专辑start-------------
  static List albumId = ['content', 'playlistRenderer', 'playlistId'];
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
    {ParserHelper.indexKey: 0},
    'thumbnails',
    {ParserHelper.indexKey: 0},
    'url',
  ];
  //歌手详情里面的专辑end-------------

  //歌手详情里面的播放列表或视频start-------------
  //播放列表的第一层就是lockupViewModel
  //而视频的话上层是richItemRenderer，下一层才是lockupViewModel
  static String lockupViewModelPlaylistItem = 'lockupViewModel';
  static List lockupViewModelVideoItem = ['content', 'lockupViewModel'];
  static List lockupViewModelPlaylistItems = [
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'contents',
    {ParserHelper.indexKey: 0},
    'itemSectionRenderer',
    'contents',
    {ParserHelper.indexKey: 0},
    'gridRenderer',
    'items',
  ];
  static List lockupViewModelId = ['contentId'];
  static List lockupViewModelType = ['contentType'];
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
    {ParserHelper.indexKey: 0},
    'metadataParts',
    {ParserHelper.indexKey: 0},
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
    {ParserHelper.indexKey: 0},
    'url',
  ];
  static List lockupViewModelVideoCover = [
    'content',
    'lockupViewModel',
    'contentImage',
    'thumbnailViewModel',
    'image',
    'sources',
    {ParserHelper.indexKey: 0},
    'url',
  ];
  //歌手详情里面的播放列表end-------------
}

class SearchCatalogParserKeys {
  ///最佳搜索(可能没有)start-------------
  //最佳搜索有最佳搜索的卡片和下面带的列表
  //有这个表示有最佳搜索
  static List topUniversalWatchCardRenderer = [
    'contents',
    'twoColumnSearchResultsRenderer',
    'secondaryContents',
    'secondarySearchContainerRenderer',
    'contents',
    {ParserHelper.filterKey: 'universalWatchCardRenderer'},
    {ParserHelper.indexKey: 0},
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
  static List topCardTitle = ['title', 'simpleText'];
  static List topCardSubtitle = ['subtitle', 'simpleText'];
  static List topCardAlbumCover = [
    ...topUniversalWatchCardRenderer,
    'callToAction',
    'watchCardHeroVideoRenderer',
    'heroImage',
    'singleHeroImageRenderer',
    'thumbnail',
    'thumbnails',
    {ParserHelper.indexKey: 0},
    'url',
  ];
  static List topCardArtistCover = [
    'avatar',
    'thumbnails',
    {ParserHelper.indexKey: 0},
    'url',
  ];

  //最佳搜索下面带的列表
  static List topVideoFileGroupFilterItems = [
    'sections',
    {ParserHelper.filterKey: 'watchCardSectionSequenceRenderer'},
  ];
  static List topVideoFileGroupItems = [
    'watchCardSectionSequenceRenderer',
    'lists',
    {ParserHelper.filterKey: 'verticalWatchCardListRenderer'},
    {ParserHelper.indexKey: 0},
    'verticalWatchCardListRenderer',
    'items',
  ];

  static String topVideoItem = 'watchCardCompactVideoRenderer';
  static List topVideoId = ['navigationEndpoint', 'watchEndpoint', 'videoId'];
  static List topVideoTitle = ['title', 'simpleText'];
  static List topVideoSubtitle = ['subtitle', 'simpleText'];
  static List topVideoSubtitle1 = [
    'subtitle',
    'runs',
    {ParserHelper.indexKey: 0},
    'text',
  ];

  ///最佳搜索(可能没有)end-------------

  static List resourceList = [
    'contents',
    'twoColumnSearchResultsRenderer',
    'primaryContents',
    'sectionListRenderer',
    'contents',
    {ParserHelper.filterKey: 'itemSectionRenderer'},
    {ParserHelper.indexKey: 0},
    'itemSectionRenderer',
    'contents',
  ];

  static List moreResourceList = [
    'onResponseReceivedCommands',
    {ParserHelper.indexKey: 0},
    'appendContinuationItemsAction',
    'continuationItems',
    {ParserHelper.filterKey: 'itemSectionRenderer'},
    {ParserHelper.indexKey: 0},
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
    {ParserHelper.filterKey: 'continuationItemRenderer'},
    {ParserHelper.indexKey: 0},
    'continuationItemRenderer',
    'continuationEndpoint',
    'continuationCommand',
    'token',
  ];

  static List moreContinuation = [
    'onResponseReceivedCommands',
    {ParserHelper.indexKey: 0},
    'appendContinuationItemsAction',
    'continuationItems',
    {ParserHelper.filterKey: 'continuationItemRenderer'},
    {ParserHelper.indexKey: 0},
    'continuationItemRenderer',
    'continuationEndpoint',
    'continuationCommand',
    'token',
  ];

  //搜索列表里面的视频start-------------
  static String videoRenderer = 'videoRenderer';
  static List videoId = ['videoId'];
  static List videoCover = [
    'thumbnail',
    'thumbnails',
    {ParserHelper.indexKey: 0},
    'url',
  ];
  static List videoTitle = [
    'title',
    'runs',
    {ParserHelper.indexKey: 0},
    'text',
  ];
  static List videoSubtitle = [
    'ownerText',
    'runs',
    {ParserHelper.indexKey: 0},
    'text',
  ];
  static List videoUid = [
    'ownerText',
    'runs',
    {ParserHelper.indexKey: 0},
    'navigationEndpoint',
    'browseEndpoint',
    'browseId',
  ];
  //搜索列表里面的视频end-------------

  //搜索列表里面的播放列表start-------------
  static String playlistItem = 'lockupViewModel';
  static List playlistId = ['contentId'];
  static List playlistType = ['contentType'];
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
    {ParserHelper.indexKey: 0},
    'metadataParts',
    {ParserHelper.indexKey: 0},
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
    {ParserHelper.indexKey: 0},
    'url',
  ];
  //搜索列表里面的播放列表end-------------

  //搜索列表里面的歌手start-------------
  static String channelRenderer = 'channelRenderer';
  static List artistBrowseId = ['channelId'];
  static List artistTitle = ['title', 'simpleText'];
  static List artistSubtitle = ['videoCountText', 'simpleText'];
  static List artistCover = [
    'thumbnail',
    'thumbnails',
    {ParserHelper.indexKey: 0},
    'url',
  ];
  //搜索列表里面的歌手end-------------
}
