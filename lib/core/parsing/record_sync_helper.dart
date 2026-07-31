import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/persistence/performer_repository.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/persistence/media_repository.dart';
import 'package:echo_vault/core/models/performer_details.dart';

class RecordSyncHelper {
  static Future<FileInfo> syncFileInfo(FileInfo mediaDetails) async {
    FileInfo? cacheFileInfo = await MediaRepository.queryFileInfoFromId(
      mediaDetails.fileId,
    );
    if (cacheFileInfo != null) {
      mediaDetails.url = cacheFileInfo.url;
      mediaDetails.uid = cacheFileInfo.uid;
      mediaDetails.userName = cacheFileInfo.userName;
      mediaDetails.downloadTaskId = cacheFileInfo.downloadTaskId;
      mediaDetails.downloadStatus = cacheFileInfo.downloadStatus;
      mediaDetails.isFavorite = cacheFileInfo.isFavorite;
      mediaDetails.duration = cacheFileInfo.duration;
    }
    return mediaDetails;
  }

  static Future<PerformerDetails> syncArtist(PerformerDetails artist) async {
    PerformerDetails? cacheArtist;
    if (artist.id != null) {
      cacheArtist = await PerformerRepository.queryArtistInfoFromId(artist.id!);
    }
    if (cacheArtist != null) {
      artist.isFavorite = cacheArtist.isFavorite;
    }
    return artist;
  }

  static Future<MediaCollection> syncFileGroup(
    MediaCollection mediaCollection,
  ) async {
    MediaCollection? cacheFileGroup =
        await MediaCollectionRepository.queryFileGroupFromId(
          mediaCollection.id,
        );
    if (cacheFileGroup != null) {
      mediaCollection.isFavorite = cacheFileGroup.isFavorite;
    }
    return mediaCollection;
  }
}
