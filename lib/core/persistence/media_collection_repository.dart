import 'dart:convert';

import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/shared/dialogs/new_collection_dialog.dart';
import 'package:echo_vault/core/persistence/application_database.dart';
import 'package:echo_vault/core/persistence/media_repository.dart';
import 'package:echo_vault/core/models/media_collection.dart';

export 'package:echo_vault/core/models/media_collection.dart';

class MediaCollectionRepository {
  static Future<int> insertFileGroup(MediaCollection mediaCollection) async {
    mediaCollection.createTime ??= DateTime.now().millisecondsSinceEpoch;
    String content = jsonEncode(mediaCollection.toJson());
    Database database = await ApplicationDatabase.database;
    int id = await database.insert(DatabaseTables.mediaGroup, {
      'id': mediaCollection.id,
      'json_content': content,
      'create_time': mediaCollection.createTime,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  static Future<int> deleteFileGroup(MediaCollection musicCollection) async {
    Database database = await ApplicationDatabase.database;
    int deleteCount = await database.delete(
      DatabaseTables.mediaGroup,
      where: 'id = "${musicCollection.id}"',
    );

    return deleteCount;
  }

  static Future<MediaCollection?> queryFileGroupFromId(String? id) async {
    List<MediaCollection> list = await queryFileGroup(
      where: id != null ? 'id = "$id"' : 'id IS null',
    );
    return list.firstOrNull;
  }

  static Future<List<MediaCollection>> queryFileGroup({
    int? limit,
    String? where,
  }) async {
    Database database = await ApplicationDatabase.database;
    List<Map<String, Object?>> records = await database.query(
      DatabaseTables.mediaGroup,
      limit: limit,
      where: where,
      orderBy: 'create_time desc',
    );
    List<MediaCollection> list = [];
    for (var data in records) {
      String content = (data['json_content'])?.toString() ?? '';
      Map<String, dynamic> map = jsonDecode(content);
      MediaCollection musicCollection = MediaCollection.fromJson(map);
      String idsString = musicCollection.childrenIds
          .map((e) {
            return '"$e"';
          })
          .toList()
          .join(',');
      musicCollection.children = await MediaRepository.queryFileInfo(
        where: 'id IN ($idsString)',
      );
      if (musicCollection.id?.startsWith(
            NewCollectionDialog.createPlaylistNamePrefix,
          ) ==
          true) {
        if (musicCollection.children.isNotEmpty) {
          musicCollection.thumbnail =
              (musicCollection.children.first as FileInfo).thumbnail;
        }
      }
      list.add(musicCollection);
    }
    return list;
  }
}
