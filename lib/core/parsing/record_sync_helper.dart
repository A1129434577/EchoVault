import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/persistence/performer_repository.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/core/persistence/media_repository.dart';
import 'package:echo_vault/core/models/performer_details.dart';

class RecordSyncHelper {
  static Future<PerformerDetails> syncArtist(PerformerDetails artistArg) async {
    PerformerDetails? cacheArtistLocal;
    if (artistArg.id != null) {
      cacheArtistLocal = await PerformerRepository.queryArtistInfoFromId(
        artistArg.id!,
      );
    }
    if (cacheArtistLocal != null) {
      artistArg.isFavorite = cacheArtistLocal.isFavorite;
    }
    return artistArg;
  }

  static Future<MediaCollection> syncFileGroup(
    MediaCollection mediaCollectionArg,
  ) async {
    MediaCollection? cacheFileGroupLocal =
        await MediaCollectionRepository.queryFileGroupFromId(
          mediaCollectionArg.id,
        );
    if (cacheFileGroupLocal != null) {
      mediaCollectionArg.isFavorite = cacheFileGroupLocal.isFavorite;
    }
    return mediaCollectionArg;
  }

  static Future<FileInfo> syncFileInfo(FileInfo mediaEntry) async {
    FileInfo? cacheFileInfoLocal = await MediaRepository.queryFileInfoFromId(
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
