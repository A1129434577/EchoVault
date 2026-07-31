import 'dart:convert';

import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/shared/dialogs/new_collection_dialog.dart';
import 'package:echo_vault/core/persistence/application_database.dart';
import 'package:echo_vault/core/persistence/media_repository.dart';
import 'package:echo_vault/core/models/media_collection.dart';

export 'package:echo_vault/core/models/media_collection.dart';

class MediaCollectionRepository {
  static Future<int> removeFileGroup(MediaCollection musicCollectionArg) async {
    Database databaseLocal = await ApplicationDatabase.database;
    int deleteCountLocal = await databaseLocal.delete(
      DatabaseTables.mediaCollection,
      where: 'id = "${musicCollectionArg.id}"',
    );

    return deleteCountLocal;
  }

  static Future<int> addFileGroup(MediaCollection mediaCollectionArg) async {
    mediaCollectionArg.createTime ??= DateTime.now().millisecondsSinceEpoch;
    String encodedContent = jsonEncode(mediaCollectionArg.toJson());
    Database databaseLocal = await ApplicationDatabase.database;
    int idLocal = await databaseLocal.insert(DatabaseTables.mediaCollection, {
      'id': mediaCollectionArg.id,
      'json_content': encodedContent,
      'create_time': mediaCollectionArg.createTime,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return idLocal;
  }

  static Future<List<MediaCollection>> fetchFileGroup({
    int? limitInputArg,
    String? whereArg,
  }) async {
    Database databaseLocal = await ApplicationDatabase.database;
    List<Map<String, Object?>> storedRecords = await databaseLocal.query(
      DatabaseTables.mediaCollection,
      limit: limitInputArg,
      where: whereArg,
      orderBy: 'create_time desc',
    );
    List<MediaCollection> entries = [];
    for (var data in storedRecords) {
      String encodedContent = (data['json_content'])?.toString() ?? '';
      Map<String, dynamic> record = jsonDecode(encodedContent);
      MediaCollection musicCollectionLocal = MediaCollection.fromJson(record);
      String idsStringLocal = musicCollectionLocal.childrenIds
          .map((entry) {
            return '"$entry"';
          })
          .toList()
          .join(',');
      musicCollectionLocal.children = await MediaRepository.fetchFileInfo(
        whereArg: 'id IN ($idsStringLocal)',
      );
      if (musicCollectionLocal.id?.startsWith(
            NewCollectionDialog.createPlaylistNamePrefix,
          ) ==
          true) {
        if (musicCollectionLocal.children.isNotEmpty) {
          musicCollectionLocal.thumbnail =
              (musicCollectionLocal.children.first as FileInfo).thumbnail;
        }
      }
      entries.add(musicCollectionLocal);
    }
    return entries;
  }

  static Future<MediaCollection?> fetchFileGroupFromId(String? idArg) async {
    List<MediaCollection> entries = await fetchFileGroup(
      whereArg: idArg != null ? 'id = "$idArg"' : 'id IS null',
    );
    return entries.firstOrNull;
  }
}
