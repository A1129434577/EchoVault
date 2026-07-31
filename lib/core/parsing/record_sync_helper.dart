import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/persistence/performer_repository.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/persistence/media_repository.dart';
import 'package:echo_vault/core/models/performer_details.dart';

class RecordSyncHelper {
  static Future<PerformerDetails> reconcileArtist(
    PerformerDetails artistArg,
  ) async {
    PerformerDetails? cacheArtistLocal;
    if (artistArg.id != null) {
      cacheArtistLocal = await PerformerRepository.fetchArtistInfoFromId(
        artistArg.id!,
      );
    }
    if (cacheArtistLocal != null) {
      artistArg.isFavorite = cacheArtistLocal.isFavorite;
    }
    return artistArg;
  }

  static Future<MediaCollection> reconcileFileGroup(
    MediaCollection mediaCollectionArg,
  ) async {
    MediaCollection? cacheFileGroupLocal =
        await MediaCollectionRepository.fetchFileGroupFromId(
          mediaCollectionArg.id,
        );
    if (cacheFileGroupLocal != null) {
      mediaCollectionArg.isFavorite = cacheFileGroupLocal.isFavorite;
    }
    return mediaCollectionArg;
  }

  static Future<FileInfo> reconcileFileInfo(FileInfo mediaEntry) async {
    FileInfo? cacheFileInfoLocal = await MediaRepository.fetchFileInfoFromId(
      mediaEntry.fileId,
    );
    if (cacheFileInfoLocal != null) {
      mediaEntry.url = cacheFileInfoLocal.url;
      mediaEntry.uid = cacheFileInfoLocal.uid;
      mediaEntry.userName = cacheFileInfoLocal.userName;
      mediaEntry.downloadTaskId = cacheFileInfoLocal.downloadTaskId;
      mediaEntry.downloadStatus = cacheFileInfoLocal.downloadStatus;
      mediaEntry.isFavorite = cacheFileInfoLocal.isFavorite;
      mediaEntry.duration = cacheFileInfoLocal.duration;
    }
    return mediaEntry;
  }
}
