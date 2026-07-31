import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/core/parsing/shared_parser.dart';
import 'package:echo_vault/core/parsing/record_sync_helper.dart';
import 'package:echo_vault/core/parsing/parser_helper.dart';

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

///解析Youtube
class MusicCatalogParser {
  static Future<MediaCollection> parseArtistAlbum(
    Map collectionRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    MediaCollection mediaCollectionLocal = MediaCollection();
    mediaCollectionLocal.thumbnail =
        ParserHelper.parse<String>(
          collectionRecord,
          PerformerCatalogParserKeys.albumCover,
        ) ??
        '';
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          collectionRecord,
          PerformerCatalogParserKeys.albumTitle,
        ) ??
        '';
    mediaCollectionLocal.displayName = mediaCollectionLocal.name;
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              collectionRecord,
              PerformerCatalogParserKeys.albumSubtitleRuns,
            ) ??
            []) {
      secondaryText += textRun['text'];
    }
    mediaCollectionLocal.detail = secondaryText;
    await RecordSyncHelper.syncFileGroup(mediaCollectionLocal);
    return mediaCollectionLocal;
  }

  static Future<List> parseArtistChildren(
    List childRecords, {
    MediaCollection? mediaCollectionArg,
    MediaSourceInterface? mediaOrigin,
  }) async {
    List childEntries = [];
    for (final childrenMap in childRecords) {
      if (childrenMap.containsKey(PerformerCatalogParserKeys.richItem)) {
        Map nestedRecord = childrenMap[PerformerCatalogParserKeys.richItem];
        String? playlistIdLocal = ParserHelper.parse<String>(
          nestedRecord,
          PerformerCatalogParserKeys.albumId,
        );
        String? videoRendererVideoIdLocal = ParserHelper.parse<String>(
          nestedRecord,
          PerformerCatalogParserKeys.videoRendererVideoId,
        );
        Map? lockupViewModelLocal = ParserHelper.parse<Map>(
          nestedRecord,
          PerformerCatalogParserKeys.lockupViewModelVideoItem,
        );
        if (videoRendererVideoIdLocal != null) {
          FileInfo mediaEntry = await parseArtistVideoRendererVideo(
            nestedRecord,
            mediaOrigin: mediaOrigin,
          );
          //B面parentId只用于埋点，无其他实际逻辑
          mediaEntry.parentId = mediaCollectionArg?.name;
          childEntries.add(mediaEntry);
        } else if (lockupViewModelLocal != null) {
          FileInfo mediaEntry = await parseArtistLockupViewModelVideo(
            lockupViewModelLocal,
            mediaOrigin: mediaOrigin,
          );
          //B面parentId只用于埋点，无其他实际逻辑
          mediaEntry.parentId = mediaCollectionArg?.name;
          childEntries.add(mediaEntry);
        } else if (playlistIdLocal != null) {
          MediaCollection playlistLocal = await parseArtistAlbum(
            nestedRecord,
            mediaOrigin: mediaOrigin,
          );
          playlistLocal.playlistType =
              CollectionType.LOCKUP_CONTENT_TYPE_ALBUM.name;
          playlistLocal.id = playlistIdLocal;
          childEntries.add(playlistLocal);
        }
      } else if (childrenMap.containsKey(
        PerformerCatalogParserKeys.lockupViewModelPlaylistItem,
      )) {
        Map nestedRecord =
            childrenMap[PerformerCatalogParserKeys.lockupViewModelPlaylistItem];
        String? playlistIdLocal = ParserHelper.parse<String>(
          nestedRecord,
          PerformerCatalogParserKeys.lockupViewModelId,
        );
        if (playlistIdLocal != null) {
          MediaCollection playlistLocal = await parseArtistPlaylist(
            nestedRecord,
            mediaOrigin: mediaOrigin,
          );
          playlistLocal.id = playlistIdLocal;
          childEntries.add(playlistLocal);
        }
      }
    }
    return childEntries;
  }

  static Future<FileInfo> parseArtistLockupViewModelVideo(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(
          mediaRecord,
          PerformerCatalogParserKeys.lockupViewModelId,
        ) ??
        '';
    mediaEntry.type = ParserHelper.parse<String>(
      mediaRecord,
      PerformerCatalogParserKeys.lockupViewModelType,
    );
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(
          mediaRecord,
          PerformerCatalogParserKeys.lockupViewModelVideoCover,
        ) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          PerformerCatalogParserKeys.lockupViewModelTitle,
        ) ??
        '';
    mediaEntry.artist =
        ParserHelper.parse<String>(
          mediaRecord,
          PerformerCatalogParserKeys.lockupViewModelSubtitle,
        ) ??
        '';
    await RecordSyncHelper.syncFileInfo(mediaEntry);
    return mediaEntry;
  }

  static Future<MediaCollection> parseArtistPlaylist(
    Map collectionRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    MediaCollection mediaCollectionLocal = MediaCollection();
    mediaCollectionLocal.playlistType = ParserHelper.parse<String>(
      collectionRecord,
      PerformerCatalogParserKeys.lockupViewModelType,
    );
    mediaCollectionLocal.thumbnail =
        ParserHelper.parse<String>(
          collectionRecord,
          PerformerCatalogParserKeys.lockupViewModelPlaylistCover,
        ) ??
        '';
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          collectionRecord,
          PerformerCatalogParserKeys.lockupViewModelTitle,
        ) ??
        '';
    mediaCollectionLocal.displayName = mediaCollectionLocal.name;
    await RecordSyncHelper.syncFileGroup(mediaCollectionLocal);
    return mediaCollectionLocal;
  }

  static Future<FileInfo> parseArtistVideoRendererVideo(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(
          mediaRecord,
          PerformerCatalogParserKeys.videoRendererVideoId,
        ) ??
        '';
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(
          mediaRecord,
          PerformerCatalogParserKeys.videoRendererVideoCover,
        ) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          PerformerCatalogParserKeys.videoRendererVideoTitle,
        ) ??
        '';
    String? viewCountTextLocal = ParserHelper.parse<String>(
      mediaRecord,
      PerformerCatalogParserKeys.videoRendererViewCountText,
    );
    String? lengthTextLocal = ParserHelper.parse<String>(
      mediaRecord,
      PerformerCatalogParserKeys.videoRendererLengthText,
    );
    String? publishedTimeTextLocal = ParserHelper.parse<String>(
      mediaRecord,
      PerformerCatalogParserKeys.videoRendererPublishedTimeText,
    );
    mediaEntry.artist = [
      viewCountTextLocal,
      lengthTextLocal,
      publishedTimeTextLocal,
    ].join(' • ');
    await RecordSyncHelper.syncFileInfo(mediaEntry);
    return mediaEntry;
  }

  static Future<List> parseHomeChildren(
    List childRecords, {
    MediaCollection? mediaCollectionArg,
    MediaSourceInterface? mediaOrigin,
  }) async {
    List childEntries = [];
    for (final childrenMap in childRecords) {
      if (childrenMap.containsKey(DiscoveryCatalogParserKeys.richItem)) {
        Map nestedRecord = childrenMap[DiscoveryCatalogParserKeys.richItem];
        String? playlistTypeLocal = ParserHelper.parse<String>(
          nestedRecord,
          DiscoveryCatalogParserKeys.playlistType,
        );
        String? mediaId = ParserHelper.parse<String>(
          nestedRecord,
          DiscoveryCatalogParserKeys.videoId,
        );
        if (playlistTypeLocal ==
                CollectionType.LOCKUP_CONTENT_TYPE_ALBUM.name ||
            playlistTypeLocal ==
                CollectionType.LOCKUP_CONTENT_TYPE_PLAYLIST.name) {
          MediaCollection playlistLocal = await parseHomePlaylist(
            nestedRecord,
            mediaOrigin: mediaOrigin,
          );
          playlistLocal.playlistType = playlistTypeLocal;
          childEntries.add(playlistLocal);
        } else if (playlistTypeLocal ==
            MediaType.LOCKUP_CONTENT_TYPE_VIDEO.name) {
          FileInfo mediaEntry = await parseHomePlaylistVideo(
            nestedRecord,
            mediaOrigin: mediaOrigin,
          );
          //B面parentId只用于埋点，无其他实际逻辑
          mediaEntry.parentId = mediaCollectionArg?.name;
          childEntries.add(mediaEntry);
        } else if (mediaId != null) {
          FileInfo mediaEntry = await parseHomeVideo(
            nestedRecord,
            mediaOrigin: mediaOrigin,
          );
          //B面parentId只用于埋点，无其他实际逻辑
          mediaEntry.parentId = mediaCollectionArg?.name;
          childEntries.add(mediaEntry);
        }
      }
    }
    return childEntries;
  }

  static Future<List<MediaCollection>> parseHomeContents(
    List groupMapListArg, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    List<MediaCollection> entries = [];
    for (Map groupMap in groupMapListArg) {
      if (groupMap.containsKey(DiscoveryCatalogParserKeys.sectionParent)) {
        groupMap =
            ParserHelper.parse<Map>(
              groupMap,
              DiscoveryCatalogParserKeys.sectionItem,
            ) ??
            {};
        MediaCollection mediaCollectionLocal =
            await MusicCatalogParser.parseHomeFileGroup(
              groupMap,
              mediaOrigin: mediaOrigin,
            );
        entries.add(mediaCollectionLocal);
      }
    }
    return entries;
  }

  ///解析Youtube(非Youtube Music)首页数据
  static Future<MediaCollection> parseHomeFileGroup(
    Map fileGroupMapArg, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    MediaCollection mediaCollectionLocal = MediaCollection();
    mediaCollectionLocal.id = ParserHelper.parse<String>(
      fileGroupMapArg,
      DiscoveryCatalogParserKeys.groupId,
    );
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          fileGroupMapArg,
          DiscoveryCatalogParserKeys.groupName,
        ) ??
        '';
    List childRecords = fileGroupMapArg[SharedParserKeys.children] ?? [];
    List childEntries = await parseHomeChildren(
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

  static Future<MediaCollection> parseHomePlaylist(
    Map collectionRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    MediaCollection mediaCollectionLocal = MediaCollection();
    mediaCollectionLocal.id = ParserHelper.parse<String>(
      collectionRecord,
      DiscoveryCatalogParserKeys.playlistId,
    );
    mediaCollectionLocal.thumbnail =
        ParserHelper.parse<String>(
          collectionRecord,
          DiscoveryCatalogParserKeys.playlistCover,
        ) ??
        '';
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          collectionRecord,
          DiscoveryCatalogParserKeys.playlistTitle,
        ) ??
        '';
    mediaCollectionLocal.displayName = mediaCollectionLocal.name;
    mediaCollectionLocal.detail = ParserHelper.parse<String>(
      collectionRecord,
      DiscoveryCatalogParserKeys.playlistSubtitle,
    );
    await RecordSyncHelper.syncFileGroup(mediaCollectionLocal);
    return mediaCollectionLocal;
  }

  static Future<FileInfo> parseHomePlaylistVideo(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(
          mediaRecord,
          DiscoveryCatalogParserKeys.playlistVideoId,
        ) ??
        '';
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(
          mediaRecord,
          DiscoveryCatalogParserKeys.playlistVideoCover,
        ) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          DiscoveryCatalogParserKeys.playlistVideoTitle,
        ) ??
        '';
    mediaEntry.artist = ParserHelper.parse<String>(
      mediaRecord,
      DiscoveryCatalogParserKeys.playlistVideoSubtitle,
    );
    await RecordSyncHelper.syncFileInfo(mediaEntry);
    return mediaEntry;
  }

  static Future<FileInfo> parseHomeVideo(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(
          mediaRecord,
          DiscoveryCatalogParserKeys.videoId,
        ) ??
        '';
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(
          mediaRecord,
          DiscoveryCatalogParserKeys.videoCover,
        ) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          DiscoveryCatalogParserKeys.videoTitle,
        ) ??
        '';
    mediaEntry.artist = ParserHelper.parse<String>(
      mediaRecord,
      DiscoveryCatalogParserKeys.videoSubtitle,
    );
    await RecordSyncHelper.syncFileInfo(mediaEntry);
    return mediaEntry;
  }

  static Future<List> parsePlayRecommendChildren(
    List childRecords, {
    MediaCollection? mediaCollectionArg,
    MediaSourceInterface? mediaOrigin,
  }) async {
    List childEntries = [];
    for (final childrenMap in childRecords) {
      if (childrenMap.containsKey(
        PlaybackSuggestionParserKeys.lockupViewModel,
      )) {
        Map nestedRecord =
            childrenMap[PlaybackSuggestionParserKeys.lockupViewModel];
        String? mediaId = ParserHelper.parse<String>(
          nestedRecord,
          PlaybackSuggestionParserKeys.videoId,
        );
        if (mediaId != null) {
          FileInfo mediaEntry = await parsePlayRecommendVideo(
            nestedRecord,
            mediaOrigin: mediaOrigin,
          );
          mediaEntry.fileId = mediaId;
          //B面parentId只用于埋点，无其他实际逻辑
          mediaEntry.parentId = mediaCollectionArg?.name;
          childEntries.add(mediaEntry);
        }
      }
    }
    return childEntries;
  }

  static Future<FileInfo> parsePlayRecommendVideo(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(
          mediaRecord,
          PlaybackSuggestionParserKeys.videoId,
        ) ??
        '';
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(
          mediaRecord,
          PlaybackSuggestionParserKeys.cover,
        ) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          PlaybackSuggestionParserKeys.title,
        ) ??
        '';
    mediaEntry.artist = ParserHelper.parse<String>(
      mediaRecord,
      PlaybackSuggestionParserKeys.subtitle,
    );
    await RecordSyncHelper.syncFileInfo(mediaEntry);
    return mediaEntry;
  }

  static Future<List> parsePlaylistChildren(
    List childRecords, {
    MediaCollection? mediaCollectionArg,
    MediaSourceInterface? mediaOrigin,
  }) async {
    List childEntries = [];
    for (final childrenMap in childRecords) {
      if (childrenMap.containsKey(CollectionCatalogParserKeys.panel)) {
        Map nestedRecord = childrenMap[CollectionCatalogParserKeys.panel];
        String? mediaId = ParserHelper.parse<String>(
          nestedRecord,
          CollectionCatalogParserKeys.videoId,
        );
        if (mediaId != null) {
          FileInfo mediaEntry = await parsePlaylistVideo(
            nestedRecord,
            mediaOrigin: mediaOrigin,
          );
          mediaEntry.fileId = mediaId;
          //B面parentId只用于埋点，无其他实际逻辑
          mediaEntry.parentId = mediaCollectionArg?.name;
          childEntries.add(mediaEntry);
        }
      }
    }
    return childEntries;
  }

  static Future<FileInfo> parsePlaylistVideo(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(
          mediaRecord,
          CollectionCatalogParserKeys.videoId,
        ) ??
        '';
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(
          mediaRecord,
          CollectionCatalogParserKeys.cover,
        ) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          CollectionCatalogParserKeys.title,
        ) ??
        '';
    mediaEntry.artist = ParserHelper.parse<String>(
      mediaRecord,
      CollectionCatalogParserKeys.subtitle,
    );
    await RecordSyncHelper.syncFileInfo(mediaEntry);
    return mediaEntry;
  }

  static Future<PerformerDetails> parseSearchArtist(
    Map performerRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    PerformerDetails artistLocal = PerformerDetails();
    artistLocal.ytId = ParserHelper.parse<String>(
      performerRecord,
      SearchCatalogParserKeys.artistBrowseId,
    );
    artistLocal.thumbnail =
        ParserHelper.parse<String>(
          performerRecord,
          SearchCatalogParserKeys.artistCover,
        ) ??
        '';
    if (artistLocal.thumbnail.startsWith('http') == false) {
      artistLocal.thumbnail = 'https:${artistLocal.thumbnail}';
    }
    artistLocal.name =
        ParserHelper.parse<String>(
          performerRecord,
          SearchCatalogParserKeys.artistTitle,
        ) ??
        '';
    artistLocal.desc =
        ParserHelper.parse<String>(
          performerRecord,
          SearchCatalogParserKeys.artistSubtitle,
        ) ??
        '';
    await RecordSyncHelper.syncArtist(artistLocal);
    return artistLocal;
  }

  static Future<List> parseSearchChildren(
    List childRecords, {
    MediaCollection? mediaCollectionArg,
    MediaSourceInterface? mediaOrigin,
  }) async {
    List childEntries = [];
    for (final childrenMap in childRecords) {
      if (childrenMap.containsKey(SearchCatalogParserKeys.channelRenderer)) {
        Map nestedRecord = childrenMap[SearchCatalogParserKeys.channelRenderer];
        PerformerDetails artistLocal = await parseSearchArtist(nestedRecord);
        childEntries.add(artistLocal);
      } else if (childrenMap.containsKey(
        SearchCatalogParserKeys.playlistItem,
      )) {
        Map nestedRecord = childrenMap[SearchCatalogParserKeys.playlistItem];
        MediaCollection playlistLocal = await parseSearchPlaylist(
          nestedRecord,
          mediaOrigin: mediaOrigin,
        );
        childEntries.add(playlistLocal);
      } else if (childrenMap.containsKey(
        SearchCatalogParserKeys.videoRenderer,
      )) {
        Map nestedRecord = childrenMap[SearchCatalogParserKeys.videoRenderer];
        FileInfo mediaEntry = await parseSearchVideo(
          nestedRecord,
          mediaOrigin: mediaOrigin,
        );
        childEntries.add(mediaEntry);
      }
    }
    return childEntries;
  }

  static Future<MediaCollection> parseSearchPlaylist(
    Map collectionRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    MediaCollection mediaCollectionLocal = MediaCollection();
    mediaCollectionLocal.id = ParserHelper.parse<String>(
      collectionRecord,
      SearchCatalogParserKeys.playlistId,
    );
    mediaCollectionLocal.playlistType = ParserHelper.parse<String>(
      collectionRecord,
      SearchCatalogParserKeys.playlistType,
    );
    mediaCollectionLocal.thumbnail =
        ParserHelper.parse<String>(
          collectionRecord,
          SearchCatalogParserKeys.playlistCover,
        ) ??
        '';
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          collectionRecord,
          SearchCatalogParserKeys.playlistTitle,
        ) ??
        '';
    mediaCollectionLocal.displayName = mediaCollectionLocal.name;
    mediaCollectionLocal.detail = ParserHelper.parse<String>(
      collectionRecord,
      SearchCatalogParserKeys.playlistSubtitle,
    );
    await RecordSyncHelper.syncFileGroup(mediaCollectionLocal);
    return mediaCollectionLocal;
  }

  static Future<PerformerDetails> parseSearchTopCardArtist(
    Map performerRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    PerformerDetails artistLocal = PerformerDetails();
    artistLocal.ytId = ParserHelper.parse<String>(
      performerRecord,
      SearchCatalogParserKeys.topCardBrowseId,
    );
    artistLocal.thumbnail =
        ParserHelper.parse<String>(
          performerRecord,
          SearchCatalogParserKeys.topCardArtistCover,
        ) ??
        '';
    artistLocal.name =
        ParserHelper.parse<String>(
          performerRecord,
          SearchCatalogParserKeys.topCardTitle,
        ) ??
        '';
    artistLocal.desc =
        ParserHelper.parse<String>(
          performerRecord,
          SearchCatalogParserKeys.topCardSubtitle,
        ) ??
        '';
    await RecordSyncHelper.syncArtist(artistLocal);
    return artistLocal;
  }

  static Future<MediaCollection> parseSearchTopCardPlaylist(
    Map collectionRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    MediaCollection mediaCollectionLocal = MediaCollection();
    mediaCollectionLocal.id = ParserHelper.parse<String>(
      collectionRecord,
      SearchCatalogParserKeys.topCardBrowseId,
    );
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          collectionRecord,
          SearchCatalogParserKeys.topCardTitle,
        ) ??
        '';
    mediaCollectionLocal.detail = ParserHelper.parse<String>(
      collectionRecord,
      SearchCatalogParserKeys.topCardSubtitle,
    );
    mediaCollectionLocal.displayName = mediaCollectionLocal.name;
    await RecordSyncHelper.syncFileGroup(mediaCollectionLocal);
    return mediaCollectionLocal;
  }

  static Future<List> parseSearchTopChildren(
    List childRecords, {
    MediaCollection? mediaCollectionArg,
    MediaSourceInterface? mediaOrigin,
  }) async {
    List childEntries = [];
    for (final childrenMap in childRecords) {
      if (childrenMap.containsKey(SearchCatalogParserKeys.topVideoItem)) {
        Map nestedRecord = childrenMap[SearchCatalogParserKeys.topVideoItem];
        FileInfo mediaEntry = await parseSearchTopVideo(
          nestedRecord,
          mediaOrigin: mediaOrigin,
        );
        //B面parentId只用于埋点，无其他实际逻辑
        mediaEntry.parentId = mediaCollectionArg?.name;
        childEntries.add(mediaEntry);
      } else if (childrenMap.containsKey(SearchCatalogParserKeys.topCardItem)) {
        Map nestedRecord = childrenMap[SearchCatalogParserKeys.topCardItem];
        String? pageTypeLocal = ParserHelper.parse<String>(
          nestedRecord,
          SearchCatalogParserKeys.topCardPageType,
        );
        if (pageTypeLocal == PerformerDetails.ytSearchTypeName) {
          PerformerDetails artistLocal = await parseSearchTopCardArtist(
            nestedRecord,
          );
          childEntries.add(artistLocal);
        } else if (pageTypeLocal ==
            CollectionType.WEB_PAGE_TYPE_PLAYLIST.name) {
          MediaCollection mediaCollectionLocal =
              await parseSearchTopCardPlaylist(nestedRecord);
          mediaCollectionLocal.playlistType = pageTypeLocal;
          childEntries.add(mediaCollectionLocal);
        }
      }
    }
    return childEntries;
  }

  static Future<FileInfo> parseSearchTopVideo(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(
          mediaRecord,
          SearchCatalogParserKeys.topVideoId,
        ) ??
        '';
    mediaEntry.thumbnail =
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          SearchCatalogParserKeys.topVideoTitle,
        ) ??
        '';
    mediaEntry.artist =
        ParserHelper.parse<String>(
          mediaRecord,
          SearchCatalogParserKeys.topVideoSubtitle,
        ) ??
        ParserHelper.parse<String>(
          mediaRecord,
          SearchCatalogParserKeys.topVideoSubtitle1,
        );
    await RecordSyncHelper.syncFileInfo(mediaEntry);
    return mediaEntry;
  }

  static Future<FileInfo> parseSearchVideo(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(
          mediaRecord,
          SearchCatalogParserKeys.videoId,
        ) ??
        '';
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(
          mediaRecord,
          SearchCatalogParserKeys.videoCover,
        ) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          SearchCatalogParserKeys.videoTitle,
        ) ??
        '';
    mediaEntry.artist = ParserHelper.parse<String>(
      mediaRecord,
      SearchCatalogParserKeys.videoSubtitle,
    );
    mediaEntry.uid = ParserHelper.parse<String>(
      mediaRecord,
      SearchCatalogParserKeys.videoUid,
    );
    await RecordSyncHelper.syncFileInfo(mediaEntry);
    return mediaEntry;
  }
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
