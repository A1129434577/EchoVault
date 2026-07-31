import 'dart:convert';

import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/persistence/application_database.dart';

class MediaRepository {
  static Future<int> insertFileInfo(FileInfo mediaDetails) async {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    String content = jsonEncode(mediaDetails.toJson());
    Database database = await ApplicationDatabase.database;
    int id = await database.insert(DatabaseTables.media, {
      'id': mediaDetails.fileId,
      'download_status': mediaDetails.downloadStatus,
      'download_task_id': mediaDetails.downloadTaskId,
      'is_favorite': mediaDetails.isFavorite,
      'json_content': content,
      'create_time': timestamp,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  static Future<int> deleteFileInfo(FileInfo mediaDetails) async {
    Database database = await ApplicationDatabase.database;
    int deleteCount = await database.delete(
      DatabaseTables.media,
      where: 'id = "${mediaDetails.fileId}"',
    );
    return deleteCount;
  }

  static Future<FileInfo?> queryFileInfoFromId(String fileId) async {
    List<FileInfo> list = await queryFileInfo(where: 'id = "$fileId"');
    return list.firstOrNull;
  }

  static Future<List<FileInfo>> queryFileInfo({
    int? limit,
    String? where,
  }) async {
    Database database = await ApplicationDatabase.database;
    List<Map<String, Object?>> records = await database.query(
      DatabaseTables.media,
      limit: limit,
      where: where,
      orderBy: 'create_time desc',
    );
    List<FileInfo> list = [];
    for (var data in records) {
      String content = (data['json_content'])?.toString() ?? '';
      Map<String, dynamic> map = jsonDecode(content);
      FileInfo mediaDetails = FileInfo.fromJson(map);
      list.add(mediaDetails);
    }
    return list;
  }
}
