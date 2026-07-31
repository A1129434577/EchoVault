import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/core/parsing/shared_parser.dart';
import 'package:echo_vault/core/parsing/record_sync_helper.dart';
import 'package:echo_vault/core/parsing/parser_helper.dart';

class CollectionCatalogParserKeys {
  static String panelNode = 'playlistPanelVideoRenderer';

  static List resourceListPath = [
    'contents',
    'twoColumnWatchNextResults',
    'playlist',
    'playlist',
    'contents',
  ];

  static List videoIdPath = ['videoId'];

  static List titlePath = ['title', 'simpleText'];

  static List subtitlePath = [
    'shortBylineText',
    'runs',
    {ParserHelper.positionField: 0},
    'text',
  ];

  static List coverPath = [
    'thumbnail',
    'thumbnails',
    {ParserHelper.positionField: 0},
    'url',
  ];
}

class DiscoveryCatalogParserKeys {
  static List resourceListPath = [
    'contents',
    'twoColumnBrowseResultsRenderer',
    'tabs',
    {ParserHelper.positionField: 0},
    'tabRenderer',
    'content',
    'richGridRenderer',
    'contents',
  ];

  static String sectionParentNode = 'richSectionRenderer';

  static List sectionItemPath = [
    'richSectionRenderer',
    'content',
    'richShelfRenderer',
  ];

  static List groupIdPath = [
    'title',
    'runs',
    {ParserHelper.positionField: 0},
    'navigationEndpoint',
    'browseEndpoint',
    'browseId',
  ];

  static List groupNamePath = [
    'title',
    'runs',
    {ParserHelper.positionField: 0},
    'text',
  ];

  static String richItemNode = 'richItemRenderer';
  static List videoIdPath = [
    'content',
    'gridVideoRenderer',
    'navigationEndpoint',
    'watchEndpoint',
    'videoId',
  ];
  static List videoTitlePath = [
    'content',
    'gridVideoRenderer',
    'title',
    'simpleText',
  ];
  static List videoSubtitlePath = [
    'content',
    'gridVideoRenderer',
    'shortBylineText',
    'runs',
    {ParserHelper.positionField: 0},
    'text',
  ];
  static List videoCoverPath = [
    'content',
    'gridVideoRenderer',
    'thumbnail',
    'thumbnails',
    {ParserHelper.positionField: 0},
    'url',
  ];

  static List playlistVideoIdPath = ['content', 'lockupViewModel', 'contentId'];
  static List playlistVideoTitlePath = [
    'content',
    'lockupViewModel',
    'metadata',
    'lockupMetadataViewModel',
    'title',
    'content',
  ];
  static List playlistVideoSubtitlePath = [
    'content',
    'lockupViewModel',
    'metadata',
    'lockupMetadataViewModel',
    'metadata',
    'contentMetadataViewModel',
    'metadataRows',
    {ParserHelper.positionField: 0},
    'metadataParts',
    {ParserHelper.positionField: 0},
    'text',
    'content',
  ];
  static List playlistVideoCoverPath = [
    'content',
    'lockupViewModel',
    'contentImage',
    'thumbnailViewModel',
    'image',
    'sources',
    {ParserHelper.positionField: 3},
    'url',
  ];

  static List playlistIdPath = ['content', 'lockupViewModel', 'contentId'];
  static List playlistTitlePath = [
    'content',
    'lockupViewModel',
    'metadata',
    'lockupMetadataViewModel',
    'title',
    'content',
  ];
  static List playlistSubtitlePath = [
    'content',
    'lockupViewModel',
    'metadata',
    'lockupMetadataViewModel',
    'metadata',
    'contentMetadataViewModel',
    'metadataRows',
    {ParserHelper.positionField: 0},
    'metadataParts',
    {ParserHelper.positionField: 0},
    'text',
    'content',
  ];
  static List playlistTypePath = ['content', 'lockupViewModel', 'contentType'];
  static List playlistCoverPath = [
    'content',
    'lockupViewModel',
    'contentImage',
    'collectionThumbnailViewModel',
    'primaryThumbnail',
    'thumbnailViewModel',
    'image',
    'sources',
    {ParserHelper.positionField: 0},
    'url',
  ];
}

///解析Youtube
class MusicCatalogParser {
  static Future<MediaCollection> decodeArtistAlbum(
    Map collectionRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    MediaCollection mediaCollectionLocal = MediaCollection();
    mediaCollectionLocal.thumbnail =
        ParserHelper.parse<String>(
          collectionRecord,
          PerformerCatalogParserKeys.albumCoverPath,
        ) ??
        '';
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          collectionRecord,
          PerformerCatalogParserKeys.albumTitlePath,
        ) ??
        '';
    mediaCollectionLocal.displayName = mediaCollectionLocal.name;
    String secondaryText = '';
    for (Map textRun
        in ParserHelper.parse<List?>(
              collectionRecord,
              PerformerCatalogParserKeys.albumSubtitleRunsPath,
            ) ??
            []) {
      secondaryText += textRun['text'];
    }
    mediaCollectionLocal.detail = secondaryText;
    await RecordSyncHelper.reconcileFileGroup(mediaCollectionLocal);
    return mediaCollectionLocal;
  }

  static Future<List> decodeArtistChildren(
    List childRecords, {
    MediaCollection? mediaCollectionArg,
    MediaSourceInterface? mediaOrigin,
  }) async {
    List childEntries = [];
    for (final childrenMap in childRecords) {
      if (childrenMap.containsKey(PerformerCatalogParserKeys.richItemNode)) {
        Map nestedRecord = childrenMap[PerformerCatalogParserKeys.richItemNode];
        String? playlistIdLocal = ParserHelper.parse<String>(
          nestedRecord,
          PerformerCatalogParserKeys.albumIdPath,
        );
        String? videoRendererVideoIdLocal = ParserHelper.parse<String>(
          nestedRecord,
          PerformerCatalogParserKeys.videoRendererVideoIdPath,
        );
        Map? lockupViewModelLocal = ParserHelper.parse<Map>(
          nestedRecord,
          PerformerCatalogParserKeys.lockupViewModelVideoItemPath,
        );
        if (videoRendererVideoIdLocal != null) {
          FileInfo mediaEntry = await decodeArtistVideoRendererVideo(
            nestedRecord,
            mediaOrigin: mediaOrigin,
          );
          //B面parentId只用于埋点，无其他实际逻辑
          mediaEntry.parentId = mediaCollectionArg?.name;
          childEntries.add(mediaEntry);
        } else if (lockupViewModelLocal != null) {
          FileInfo mediaEntry = await decodeArtistLockupViewModelVideo(
            lockupViewModelLocal,
            mediaOrigin: mediaOrigin,
          );
          //B面parentId只用于埋点，无其他实际逻辑
          mediaEntry.parentId = mediaCollectionArg?.name;
          childEntries.add(mediaEntry);
        } else if (playlistIdLocal != null) {
          MediaCollection playlistLocal = await decodeArtistAlbum(
            nestedRecord,
            mediaOrigin: mediaOrigin,
          );
          playlistLocal.playlistType =
              CollectionType.LOCKUP_CONTENT_TYPE_ALBUM.name;
          playlistLocal.id = playlistIdLocal;
          childEntries.add(playlistLocal);
        }
      } else if (childrenMap.containsKey(
        PerformerCatalogParserKeys.lockupViewModelPlaylistItemNode,
      )) {
        Map nestedRecord =
            childrenMap[PerformerCatalogParserKeys
                .lockupViewModelPlaylistItemNode];
        String? playlistIdLocal = ParserHelper.parse<String>(
          nestedRecord,
          PerformerCatalogParserKeys.lockupViewModelIdPath,
        );
        if (playlistIdLocal != null) {
          MediaCollection playlistLocal = await decodeArtistPlaylist(
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

  static Future<FileInfo> decodeArtistLockupViewModelVideo(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(
          mediaRecord,
          PerformerCatalogParserKeys.lockupViewModelIdPath,
        ) ??
        '';
    mediaEntry.type = ParserHelper.parse<String>(
      mediaRecord,
      PerformerCatalogParserKeys.lockupViewModelTypePath,
    );
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(
          mediaRecord,
          PerformerCatalogParserKeys.lockupViewModelVideoCoverPath,
        ) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          PerformerCatalogParserKeys.lockupViewModelTitlePath,
        ) ??
        '';
    mediaEntry.artist =
        ParserHelper.parse<String>(
          mediaRecord,
          PerformerCatalogParserKeys.lockupViewModelSubtitlePath,
        ) ??
        '';
    await RecordSyncHelper.reconcileFileInfo(mediaEntry);
    return mediaEntry;
  }

  static Future<MediaCollection> decodeArtistPlaylist(
    Map collectionRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    MediaCollection mediaCollectionLocal = MediaCollection();
    mediaCollectionLocal.playlistType = ParserHelper.parse<String>(
      collectionRecord,
      PerformerCatalogParserKeys.lockupViewModelTypePath,
    );
    mediaCollectionLocal.thumbnail =
        ParserHelper.parse<String>(
          collectionRecord,
          PerformerCatalogParserKeys.lockupViewModelPlaylistCoverPath,
        ) ??
        '';
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          collectionRecord,
          PerformerCatalogParserKeys.lockupViewModelTitlePath,
        ) ??
        '';
    mediaCollectionLocal.displayName = mediaCollectionLocal.name;
    await RecordSyncHelper.reconcileFileGroup(mediaCollectionLocal);
    return mediaCollectionLocal;
  }

  static Future<FileInfo> decodeArtistVideoRendererVideo(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(
          mediaRecord,
          PerformerCatalogParserKeys.videoRendererVideoIdPath,
        ) ??
        '';
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(
          mediaRecord,
          PerformerCatalogParserKeys.videoRendererVideoCoverPath,
        ) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          PerformerCatalogParserKeys.videoRendererVideoTitlePath,
        ) ??
        '';
    String? viewCountTextLocal = ParserHelper.parse<String>(
      mediaRecord,
      PerformerCatalogParserKeys.videoRendererViewCountTextPath,
    );
    String? lengthTextLocal = ParserHelper.parse<String>(
      mediaRecord,
      PerformerCatalogParserKeys.videoRendererLengthTextPath,
    );
    String? publishedTimeTextLocal = ParserHelper.parse<String>(
      mediaRecord,
      PerformerCatalogParserKeys.videoRendererPublishedTimeTextPath,
    );
    mediaEntry.artist = [
      viewCountTextLocal,
      lengthTextLocal,
      publishedTimeTextLocal,
    ].join(' • ');
    await RecordSyncHelper.reconcileFileInfo(mediaEntry);
    return mediaEntry;
  }

  static Future<List> decodeHomeChildren(
    List childRecords, {
    MediaCollection? mediaCollectionArg,
    MediaSourceInterface? mediaOrigin,
  }) async {
    List childEntries = [];
    for (final childrenMap in childRecords) {
      if (childrenMap.containsKey(DiscoveryCatalogParserKeys.richItemNode)) {
        Map nestedRecord = childrenMap[DiscoveryCatalogParserKeys.richItemNode];
        String? playlistTypeLocal = ParserHelper.parse<String>(
          nestedRecord,
          DiscoveryCatalogParserKeys.playlistTypePath,
        );
        String? mediaId = ParserHelper.parse<String>(
          nestedRecord,
          DiscoveryCatalogParserKeys.videoIdPath,
        );
        if (playlistTypeLocal ==
                CollectionType.LOCKUP_CONTENT_TYPE_ALBUM.name ||
            playlistTypeLocal ==
                CollectionType.LOCKUP_CONTENT_TYPE_PLAYLIST.name) {
          MediaCollection playlistLocal = await decodeHomePlaylist(
            nestedRecord,
            mediaOrigin: mediaOrigin,
          );
          playlistLocal.playlistType = playlistTypeLocal;
          childEntries.add(playlistLocal);
        } else if (playlistTypeLocal ==
            MediaType.LOCKUP_CONTENT_TYPE_VIDEO.name) {
          FileInfo mediaEntry = await decodeHomePlaylistVideo(
            nestedRecord,
            mediaOrigin: mediaOrigin,
          );
          //B面parentId只用于埋点，无其他实际逻辑
          mediaEntry.parentId = mediaCollectionArg?.name;
          childEntries.add(mediaEntry);
        } else if (mediaId != null) {
          FileInfo mediaEntry = await decodeHomeVideo(
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

  static Future<List<MediaCollection>> decodeHomeContents(
    List groupMapListArg, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    List<MediaCollection> entries = [];
    for (Map groupMap in groupMapListArg) {
      if (groupMap.containsKey(DiscoveryCatalogParserKeys.sectionParentNode)) {
        groupMap =
            ParserHelper.parse<Map>(
              groupMap,
              DiscoveryCatalogParserKeys.sectionItemPath,
            ) ??
            {};
        MediaCollection mediaCollectionLocal =
            await MusicCatalogParser.decodeHomeFileGroup(
              groupMap,
              mediaOrigin: mediaOrigin,
            );
        entries.add(mediaCollectionLocal);
      }
    }
    return entries;
  }

  ///解析Youtube(非Youtube Music)首页数据
  static Future<MediaCollection> decodeHomeFileGroup(
    Map fileGroupMapArg, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    MediaCollection mediaCollectionLocal = MediaCollection();
    mediaCollectionLocal.id = ParserHelper.parse<String>(
      fileGroupMapArg,
      DiscoveryCatalogParserKeys.groupIdPath,
    );
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          fileGroupMapArg,
          DiscoveryCatalogParserKeys.groupNamePath,
        ) ??
        '';
    List childRecords = fileGroupMapArg[SharedParserKeys.childrenNode] ?? [];
    List childEntries = await decodeHomeChildren(
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

  static Future<MediaCollection> decodeHomePlaylist(
    Map collectionRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    MediaCollection mediaCollectionLocal = MediaCollection();
    mediaCollectionLocal.id = ParserHelper.parse<String>(
      collectionRecord,
      DiscoveryCatalogParserKeys.playlistIdPath,
    );
    mediaCollectionLocal.thumbnail =
        ParserHelper.parse<String>(
          collectionRecord,
          DiscoveryCatalogParserKeys.playlistCoverPath,
        ) ??
        '';
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          collectionRecord,
          DiscoveryCatalogParserKeys.playlistTitlePath,
        ) ??
        '';
    mediaCollectionLocal.displayName = mediaCollectionLocal.name;
    mediaCollectionLocal.detail = ParserHelper.parse<String>(
      collectionRecord,
      DiscoveryCatalogParserKeys.playlistSubtitlePath,
    );
    await RecordSyncHelper.reconcileFileGroup(mediaCollectionLocal);
    return mediaCollectionLocal;
  }

  static Future<FileInfo> decodeHomePlaylistVideo(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(
          mediaRecord,
          DiscoveryCatalogParserKeys.playlistVideoIdPath,
        ) ??
        '';
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(
          mediaRecord,
          DiscoveryCatalogParserKeys.playlistVideoCoverPath,
        ) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          DiscoveryCatalogParserKeys.playlistVideoTitlePath,
        ) ??
        '';
    mediaEntry.artist = ParserHelper.parse<String>(
      mediaRecord,
      DiscoveryCatalogParserKeys.playlistVideoSubtitlePath,
    );
    await RecordSyncHelper.reconcileFileInfo(mediaEntry);
    return mediaEntry;
  }

  static Future<FileInfo> decodeHomeVideo(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(
          mediaRecord,
          DiscoveryCatalogParserKeys.videoIdPath,
        ) ??
        '';
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(
          mediaRecord,
          DiscoveryCatalogParserKeys.videoCoverPath,
        ) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          DiscoveryCatalogParserKeys.videoTitlePath,
        ) ??
        '';
    mediaEntry.artist = ParserHelper.parse<String>(
      mediaRecord,
      DiscoveryCatalogParserKeys.videoSubtitlePath,
    );
    await RecordSyncHelper.reconcileFileInfo(mediaEntry);
    return mediaEntry;
  }

  static Future<List> decodePlayRecommendChildren(
    List childRecords, {
    MediaCollection? mediaCollectionArg,
    MediaSourceInterface? mediaOrigin,
  }) async {
    List childEntries = [];
    for (final childrenMap in childRecords) {
      if (childrenMap.containsKey(
        PlaybackSuggestionParserKeys.lockupViewModelNode,
      )) {
        Map nestedRecord =
            childrenMap[PlaybackSuggestionParserKeys.lockupViewModelNode];
        String? mediaId = ParserHelper.parse<String>(
          nestedRecord,
          PlaybackSuggestionParserKeys.videoIdPath,
        );
        if (mediaId != null) {
          FileInfo mediaEntry = await decodePlayRecommendVideo(
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

  static Future<FileInfo> decodePlayRecommendVideo(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(
          mediaRecord,
          PlaybackSuggestionParserKeys.videoIdPath,
        ) ??
        '';
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(
          mediaRecord,
          PlaybackSuggestionParserKeys.coverPath,
        ) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          PlaybackSuggestionParserKeys.titlePath,
        ) ??
        '';
    mediaEntry.artist = ParserHelper.parse<String>(
      mediaRecord,
      PlaybackSuggestionParserKeys.subtitlePath,
    );
    await RecordSyncHelper.reconcileFileInfo(mediaEntry);
    return mediaEntry;
  }

  static Future<List> decodePlaylistChildren(
    List childRecords, {
    MediaCollection? mediaCollectionArg,
    MediaSourceInterface? mediaOrigin,
  }) async {
    List childEntries = [];
    for (final childrenMap in childRecords) {
      if (childrenMap.containsKey(CollectionCatalogParserKeys.panelNode)) {
        Map nestedRecord = childrenMap[CollectionCatalogParserKeys.panelNode];
        String? mediaId = ParserHelper.parse<String>(
          nestedRecord,
          CollectionCatalogParserKeys.videoIdPath,
        );
        if (mediaId != null) {
          FileInfo mediaEntry = await decodePlaylistVideo(
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

  static Future<FileInfo> decodePlaylistVideo(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(
          mediaRecord,
          CollectionCatalogParserKeys.videoIdPath,
        ) ??
        '';
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(
          mediaRecord,
          CollectionCatalogParserKeys.coverPath,
        ) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          CollectionCatalogParserKeys.titlePath,
        ) ??
        '';
    mediaEntry.artist = ParserHelper.parse<String>(
      mediaRecord,
      CollectionCatalogParserKeys.subtitlePath,
    );
    await RecordSyncHelper.reconcileFileInfo(mediaEntry);
    return mediaEntry;
  }

  static Future<PerformerDetails> decodeSearchArtist(
    Map performerRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    PerformerDetails artistLocal = PerformerDetails();
    artistLocal.ytId = ParserHelper.parse<String>(
      performerRecord,
      SearchCatalogParserKeys.artistBrowseIdPath,
    );
    artistLocal.thumbnail =
        ParserHelper.parse<String>(
          performerRecord,
          SearchCatalogParserKeys.artistCoverPath,
        ) ??
        '';
    if (artistLocal.thumbnail.startsWith('http') == false) {
      artistLocal.thumbnail = 'https:${artistLocal.thumbnail}';
    }
    artistLocal.name =
        ParserHelper.parse<String>(
          performerRecord,
          SearchCatalogParserKeys.artistTitlePath,
        ) ??
        '';
    artistLocal.desc =
        ParserHelper.parse<String>(
          performerRecord,
          SearchCatalogParserKeys.artistSubtitlePath,
        ) ??
        '';
    await RecordSyncHelper.reconcileArtist(artistLocal);
    return artistLocal;
  }

  static Future<List> decodeSearchChildren(
    List childRecords, {
    MediaCollection? mediaCollectionArg,
    MediaSourceInterface? mediaOrigin,
  }) async {
    List childEntries = [];
    for (final childrenMap in childRecords) {
      if (childrenMap.containsKey(
        SearchCatalogParserKeys.channelRendererNode,
      )) {
        Map nestedRecord =
            childrenMap[SearchCatalogParserKeys.channelRendererNode];
        PerformerDetails artistLocal = await decodeSearchArtist(nestedRecord);
        childEntries.add(artistLocal);
      } else if (childrenMap.containsKey(
        SearchCatalogParserKeys.playlistItemNode,
      )) {
        Map nestedRecord =
            childrenMap[SearchCatalogParserKeys.playlistItemNode];
        MediaCollection playlistLocal = await decodeSearchPlaylist(
          nestedRecord,
          mediaOrigin: mediaOrigin,
        );
        childEntries.add(playlistLocal);
      } else if (childrenMap.containsKey(
        SearchCatalogParserKeys.videoRendererNode,
      )) {
        Map nestedRecord =
            childrenMap[SearchCatalogParserKeys.videoRendererNode];
        FileInfo mediaEntry = await decodeSearchVideo(
          nestedRecord,
          mediaOrigin: mediaOrigin,
        );
        childEntries.add(mediaEntry);
      }
    }
    return childEntries;
  }

  static Future<MediaCollection> decodeSearchPlaylist(
    Map collectionRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    MediaCollection mediaCollectionLocal = MediaCollection();
    mediaCollectionLocal.id = ParserHelper.parse<String>(
      collectionRecord,
      SearchCatalogParserKeys.playlistIdPath,
    );
    mediaCollectionLocal.playlistType = ParserHelper.parse<String>(
      collectionRecord,
      SearchCatalogParserKeys.playlistTypePath,
    );
    mediaCollectionLocal.thumbnail =
        ParserHelper.parse<String>(
          collectionRecord,
          SearchCatalogParserKeys.playlistCoverPath,
        ) ??
        '';
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          collectionRecord,
          SearchCatalogParserKeys.playlistTitlePath,
        ) ??
        '';
    mediaCollectionLocal.displayName = mediaCollectionLocal.name;
    mediaCollectionLocal.detail = ParserHelper.parse<String>(
      collectionRecord,
      SearchCatalogParserKeys.playlistSubtitlePath,
    );
    await RecordSyncHelper.reconcileFileGroup(mediaCollectionLocal);
    return mediaCollectionLocal;
  }

  static Future<PerformerDetails> decodeSearchTopCardArtist(
    Map performerRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    PerformerDetails artistLocal = PerformerDetails();
    artistLocal.ytId = ParserHelper.parse<String>(
      performerRecord,
      SearchCatalogParserKeys.topCardBrowseIdPath,
    );
    artistLocal.thumbnail =
        ParserHelper.parse<String>(
          performerRecord,
          SearchCatalogParserKeys.topCardArtistCoverPath,
        ) ??
        '';
    artistLocal.name =
        ParserHelper.parse<String>(
          performerRecord,
          SearchCatalogParserKeys.topCardTitlePath,
        ) ??
        '';
    artistLocal.desc =
        ParserHelper.parse<String>(
          performerRecord,
          SearchCatalogParserKeys.topCardSubtitlePath,
        ) ??
        '';
    await RecordSyncHelper.reconcileArtist(artistLocal);
    return artistLocal;
  }

  static Future<MediaCollection> decodeSearchTopCardPlaylist(
    Map collectionRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    MediaCollection mediaCollectionLocal = MediaCollection();
    mediaCollectionLocal.id = ParserHelper.parse<String>(
      collectionRecord,
      SearchCatalogParserKeys.topCardBrowseIdPath,
    );
    mediaCollectionLocal.name =
        ParserHelper.parse<String>(
          collectionRecord,
          SearchCatalogParserKeys.topCardTitlePath,
        ) ??
        '';
    mediaCollectionLocal.detail = ParserHelper.parse<String>(
      collectionRecord,
      SearchCatalogParserKeys.topCardSubtitlePath,
    );
    mediaCollectionLocal.displayName = mediaCollectionLocal.name;
    await RecordSyncHelper.reconcileFileGroup(mediaCollectionLocal);
    return mediaCollectionLocal;
  }

  static Future<List> decodeSearchTopChildren(
    List childRecords, {
    MediaCollection? mediaCollectionArg,
    MediaSourceInterface? mediaOrigin,
  }) async {
    List childEntries = [];
    for (final childrenMap in childRecords) {
      if (childrenMap.containsKey(SearchCatalogParserKeys.topVideoItemNode)) {
        Map nestedRecord =
            childrenMap[SearchCatalogParserKeys.topVideoItemNode];
        FileInfo mediaEntry = await decodeSearchTopVideo(
          nestedRecord,
          mediaOrigin: mediaOrigin,
        );
        //B面parentId只用于埋点，无其他实际逻辑
        mediaEntry.parentId = mediaCollectionArg?.name;
        childEntries.add(mediaEntry);
      } else if (childrenMap.containsKey(
        SearchCatalogParserKeys.topCardItemNode,
      )) {
        Map nestedRecord = childrenMap[SearchCatalogParserKeys.topCardItemNode];
        String? pageTypeLocal = ParserHelper.parse<String>(
          nestedRecord,
          SearchCatalogParserKeys.topCardPageTypePath,
        );
        if (pageTypeLocal == PerformerDetails.channelSearchPageType) {
          PerformerDetails artistLocal = await decodeSearchTopCardArtist(
            nestedRecord,
          );
          childEntries.add(artistLocal);
        } else if (pageTypeLocal ==
            CollectionType.WEB_PAGE_TYPE_PLAYLIST.name) {
          MediaCollection mediaCollectionLocal =
              await decodeSearchTopCardPlaylist(nestedRecord);
          mediaCollectionLocal.playlistType = pageTypeLocal;
          childEntries.add(mediaCollectionLocal);
        }
      }
    }
    return childEntries;
  }

  static Future<FileInfo> decodeSearchTopVideo(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(
          mediaRecord,
          SearchCatalogParserKeys.topVideoIdPath,
        ) ??
        '';
    mediaEntry.thumbnail =
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          SearchCatalogParserKeys.topVideoTitlePath,
        ) ??
        '';
    mediaEntry.artist =
        ParserHelper.parse<String>(
          mediaRecord,
          SearchCatalogParserKeys.topVideoSubtitlePath,
        ) ??
        ParserHelper.parse<String>(
          mediaRecord,
          SearchCatalogParserKeys.topVideoSubtitle1Path,
        );
    await RecordSyncHelper.reconcileFileInfo(mediaEntry);
    return mediaEntry;
  }

  static Future<FileInfo> decodeSearchVideo(
    Map mediaRecord, {
    MediaSourceInterface? mediaOrigin,
  }) async {
    FileInfo mediaEntry = FileInfo(extension: 'mp4', source: mediaOrigin);
    mediaEntry.fileId =
        ParserHelper.parse<String>(
          mediaRecord,
          SearchCatalogParserKeys.videoIdPath,
        ) ??
        '';
    mediaEntry.thumbnail =
        ParserHelper.parse<String>(
          mediaRecord,
          SearchCatalogParserKeys.videoCoverPath,
        ) ??
        'https://i.ytimg.com/vi/${mediaEntry.fileId}/default.jpg';
    mediaEntry.name =
        ParserHelper.parse<String>(
          mediaRecord,
          SearchCatalogParserKeys.videoTitlePath,
        ) ??
        '';
    mediaEntry.artist = ParserHelper.parse<String>(
      mediaRecord,
      SearchCatalogParserKeys.videoSubtitlePath,
    );
    mediaEntry.uid = ParserHelper.parse<String>(
      mediaRecord,
      SearchCatalogParserKeys.videoUidPath,
    );
    await RecordSyncHelper.reconcileFileInfo(mediaEntry);
    return mediaEntry;
  }
}

class PerformerCatalogParserKeys {
  static List coverPath = [
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
    {ParserHelper.positionField: 2},
    'url',
  ];

  static List tabsPath = ['contents', 'twoColumnBrowseResultsRenderer', 'tabs'];

  static List tabUrlPath = [
    'tabRenderer',
    'endpoint',
    'commandMetadata',
    'webCommandMetadata',
    'url',
  ];

  static List tabTitlePath = ['tabRenderer', 'title'];

  //视频
  static String videosNode = 'videos';
  //发布作品
  static String releasesNode = 'releases';
  //播放列表
  static String playlistsNode = 'playlists';

  static List paramsPath = [
    'tabRenderer',
    'endpoint',
    'browseEndpoint',
    'params',
  ];

  //歌手详情里面的视频和专辑都是richItem
  static String richItemNode = 'richItemRenderer';
  //音乐和专辑是richItem
  static List richItemsPath = [
    'tabRenderer',
    'content',
    'richGridRenderer',
    'contents',
  ];

  //歌手详情里面的视频start-------------
  static List videoRendererVideoIdPath = [
    'content',
    'videoRenderer',
    'videoId',
  ];
  static List videoRendererVideoTitlePath = [
    'content',
    'videoRenderer',
    'title',
    'runs',
    {ParserHelper.positionField: 0},
    'text',
  ];
  static List videoRendererViewCountTextPath = [
    'content',
    'videoRenderer',
    'viewCountText',
    'simpleText',
  ];
  static List videoRendererLengthTextPath = [
    'content',
    'videoRenderer',
    'lengthText',
    'simpleText',
  ];
  static List videoRendererPublishedTimeTextPath = [
    'content',
    'videoRenderer',
    'publishedTimeText',
    'simpleText',
  ];
  static List videoRendererVideoCoverPath = [
    'content',
    'videoRenderer',
    'thumbnail',
    'thumbnails',
    {ParserHelper.positionField: 0},
    'url',
  ];
  //歌手详情里面的视频end-------------

  //歌手详情里面的专辑start-------------
  static List albumIdPath = ['content', 'playlistRenderer', 'playlistId'];
  static List albumTitlePath = [
    'content',
    'playlistRenderer',
    'title',
    'simpleText',
  ];
  static List albumSubtitleRunsPath = [
    'content',
    'playlistRenderer',
    'shortBylineText',
    'runs',
  ];
  static List albumCoverPath = [
    'content',
    'playlistRenderer',
    'thumbnails',
    {ParserHelper.positionField: 0},
    'thumbnails',
    {ParserHelper.positionField: 0},
    'url',
  ];
  //歌手详情里面的专辑end-------------

  //歌手详情里面的播放列表或视频start-------------
  //播放列表的第一层就是lockupViewModel
  //而视频的话上层是richItemRenderer，下一层才是lockupViewModel
  static String lockupViewModelPlaylistItemNode = 'lockupViewModel';
  static List lockupViewModelVideoItemPath = ['content', 'lockupViewModel'];
  static List lockupViewModelPlaylistItemsPath = [
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'contents',
    {ParserHelper.positionField: 0},
    'itemSectionRenderer',
    'contents',
    {ParserHelper.positionField: 0},
    'gridRenderer',
    'items',
  ];
  static List lockupViewModelIdPath = ['contentId'];
  static List lockupViewModelTypePath = ['contentType'];
  static List lockupViewModelTitlePath = [
    'metadata',
    'lockupMetadataViewModel',
    'title',
    'content',
  ];
  static List lockupViewModelSubtitlePath = [
    'content',
    'lockupViewModel',
    'metadata',
    'lockupMetadataViewModel',
    'metadata',
    'contentMetadataViewModel',
    'metadataRows',
    {ParserHelper.positionField: 0},
    'metadataParts',
    {ParserHelper.positionField: 0},
    'text',
    'content',
  ];
  static List lockupViewModelPlaylistCoverPath = [
    'contentImage',
    'collectionThumbnailViewModel',
    'primaryThumbnail',
    'thumbnailViewModel',
    'image',
    'sources',
    {ParserHelper.positionField: 0},
    'url',
  ];
  static List lockupViewModelVideoCoverPath = [
    'content',
    'lockupViewModel',
    'contentImage',
    'thumbnailViewModel',
    'image',
    'sources',
    {ParserHelper.positionField: 0},
    'url',
  ];
  //歌手详情里面的播放列表end-------------
}

class PlaybackSuggestionParserKeys {
  static String lockupViewModelNode = 'lockupViewModel';

  static List resourceListPath = [
    'contents',
    'twoColumnWatchNextResults',
    'secondaryResults',
    'secondaryResults',
    'results',
  ];

  static List videoIdPath = ['contentId'];
  static List videoTypePath = ['contentType'];

  static List titlePath = [
    'metadata',
    'lockupMetadataViewModel',
    'title',
    'content',
  ];

  static List subtitlePath = [
    'metadata',
    'lockupMetadataViewModel',
    'metadata',
    'contentMetadataViewModel',
    'metadataRows',
    {ParserHelper.positionField: 1},
    'metadataParts',
    {ParserHelper.positionField: 0},
    'text',
    'content',
  ];

  static List coverPath = [
    'contentImage',
    'thumbnailViewModel',
    'image',
    'sources',
    {ParserHelper.positionField: 0},
    'url',
  ];
}

class SearchCatalogParserKeys {
  ///最佳搜索(可能没有)start-------------
  //最佳搜索有最佳搜索的卡片和下面带的列表
  //有这个表示有最佳搜索
  static List topUniversalWatchCardRendererPath = [
    'contents',
    'twoColumnSearchResultsRenderer',
    'secondaryContents',
    'secondarySearchContainerRenderer',
    'contents',
    {ParserHelper.matchField: 'universalWatchCardRenderer'},
    {ParserHelper.positionField: 0},
    'universalWatchCardRenderer',
  ];

  //可能是专辑，可能是歌手
  static String topCardNode = 'header';
  static String topCardItemNode = 'watchCardRichHeaderRenderer';
  static List topCardPageTypePath = [
    'titleNavigationEndpoint',
    'commandMetadata',
    'webCommandMetadata',
    'webPageType',
  ];
  static List topCardBrowseIdPath = [
    'titleNavigationEndpoint',
    'browseEndpoint',
    'browseId',
  ];
  static List topCardTitlePath = ['title', 'simpleText'];
  static List topCardSubtitlePath = ['subtitle', 'simpleText'];
  static List topCardAlbumCoverPath = [
    ...topUniversalWatchCardRendererPath,
    'callToAction',
    'watchCardHeroVideoRenderer',
    'heroImage',
    'singleHeroImageRenderer',
    'thumbnail',
    'thumbnails',
    {ParserHelper.positionField: 0},
    'url',
  ];
  static List topCardArtistCoverPath = [
    'avatar',
    'thumbnails',
    {ParserHelper.positionField: 0},
    'url',
  ];

  //最佳搜索下面带的列表
  static List topVideoFileGroupFilterItemsPath = [
    'sections',
    {ParserHelper.matchField: 'watchCardSectionSequenceRenderer'},
  ];
  static List topVideoFileGroupItemsPath = [
    'watchCardSectionSequenceRenderer',
    'lists',
    {ParserHelper.matchField: 'verticalWatchCardListRenderer'},
    {ParserHelper.positionField: 0},
    'verticalWatchCardListRenderer',
    'items',
  ];

  static String topVideoItemNode = 'watchCardCompactVideoRenderer';
  static List topVideoIdPath = [
    'navigationEndpoint',
    'watchEndpoint',
    'videoId',
  ];
  static List topVideoTitlePath = ['title', 'simpleText'];
  static List topVideoSubtitlePath = ['subtitle', 'simpleText'];
  static List topVideoSubtitle1Path = [
    'subtitle',
    'runs',
    {ParserHelper.positionField: 0},
    'text',
  ];

  ///最佳搜索(可能没有)end-------------

  static List resourceListPath = [
    'contents',
    'twoColumnSearchResultsRenderer',
    'primaryContents',
    'sectionListRenderer',
    'contents',
    {ParserHelper.matchField: 'itemSectionRenderer'},
    {ParserHelper.positionField: 0},
    'itemSectionRenderer',
    'contents',
  ];

  static List moreResourceListPath = [
    'onResponseReceivedCommands',
    {ParserHelper.positionField: 0},
    'appendContinuationItemsAction',
    'continuationItems',
    {ParserHelper.matchField: 'itemSectionRenderer'},
    {ParserHelper.positionField: 0},
    'itemSectionRenderer',
    'contents',
  ];

  //翻页参数
  static List continuationPath = [
    'contents',
    'twoColumnSearchResultsRenderer',
    'primaryContents',
    'sectionListRenderer',
    'contents',
    {ParserHelper.matchField: 'continuationItemRenderer'},
    {ParserHelper.positionField: 0},
    'continuationItemRenderer',
    'continuationEndpoint',
    'continuationCommand',
    'token',
  ];

  static List moreContinuationPath = [
    'onResponseReceivedCommands',
    {ParserHelper.positionField: 0},
    'appendContinuationItemsAction',
    'continuationItems',
    {ParserHelper.matchField: 'continuationItemRenderer'},
    {ParserHelper.positionField: 0},
    'continuationItemRenderer',
    'continuationEndpoint',
    'continuationCommand',
    'token',
  ];

  //搜索列表里面的视频start-------------
  static String videoRendererNode = 'videoRenderer';
  static List videoIdPath = ['videoId'];
  static List videoCoverPath = [
    'thumbnail',
    'thumbnails',
    {ParserHelper.positionField: 0},
    'url',
  ];
  static List videoTitlePath = [
    'title',
    'runs',
    {ParserHelper.positionField: 0},
    'text',
  ];
  static List videoSubtitlePath = [
    'ownerText',
    'runs',
    {ParserHelper.positionField: 0},
    'text',
  ];
  static List videoUidPath = [
    'ownerText',
    'runs',
    {ParserHelper.positionField: 0},
    'navigationEndpoint',
    'browseEndpoint',
    'browseId',
  ];
  //搜索列表里面的视频end-------------

  //搜索列表里面的播放列表start-------------
  static String playlistItemNode = 'lockupViewModel';
  static List playlistIdPath = ['contentId'];
  static List playlistTypePath = ['contentType'];
  static List playlistTitlePath = [
    'metadata',
    'lockupMetadataViewModel',
    'title',
    'content',
  ];
  static List playlistSubtitlePath = [
    'metadata',
    'lockupMetadataViewModel',
    'metadata',
    'contentMetadataViewModel',
    'metadataRows',
    {ParserHelper.positionField: 0},
    'metadataParts',
    {ParserHelper.positionField: 0},
    'text',
    'content',
  ];
  static List playlistCoverPath = [
    'contentImage',
    'collectionThumbnailViewModel',
    'primaryThumbnail',
    'thumbnailViewModel',
    'image',
    'sources',
    {ParserHelper.positionField: 0},
    'url',
  ];
  //搜索列表里面的播放列表end-------------

  //搜索列表里面的歌手start-------------
  static String channelRendererNode = 'channelRenderer';
  static List artistBrowseIdPath = ['channelId'];
  static List artistTitlePath = ['title', 'simpleText'];
  static List artistSubtitlePath = ['videoCountText', 'simpleText'];
  static List artistCoverPath = [
    'thumbnail',
    'thumbnails',
    {ParserHelper.positionField: 0},
    'url',
  ];
  //搜索列表里面的歌手end-------------
}
