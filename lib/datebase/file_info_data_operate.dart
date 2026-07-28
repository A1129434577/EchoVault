import 'dart:convert';

import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/datebase/app_datebase.dart';

class FileInfoDataOperate {
  static Future<int> insertFileInfo(FileInfo fileInfo) async {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    String content = jsonEncode(fileInfo.toJson());
    Database database = await AppDatabase.database;
    int id = await database.insert(
      AppDatabaseTable.media,
      {
        'id': fileInfo.fileId,
        'download_status': fileInfo.downloadStatus,
        'download_task_id': fileInfo.downloadTaskId,
        'is_favorite': fileInfo.isFavorite,
        'json_content': content,
        'create_time': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  static Future<int> deleteFileInfo(FileInfo fileInfo) async {
    Database database = await AppDatabase.database;
    int deleteCount = await database.delete(
      AppDatabaseTable.media,
      where: 'id = "${fileInfo.fileId}"',
    );
    return deleteCount;
  }

  static Future<FileInfo?> queryFileInfoFromId(String fileId) async {
    List<FileInfo> list = await queryFileInfo(where: 'id = "$fileId"');
    return list.firstOrNull;
  }

  static Future<List<FileInfo>> queryFileInfo({int? limit, String? where}) async {
    Database database = await AppDatabase.database;
    List<Map<String, Object?>> dataList = await database.query(
      AppDatabaseTable.media,
      limit: limit,
      where: where,
      orderBy: 'create_time desc',
    );
    List<FileInfo> list = [];
    for (var data in dataList) {
      String content = (data['json_content'])?.toString() ?? '';
      Map<String, dynamic> map = jsonDecode(content);
      FileInfo fileInfo = FileInfo.fromJson(map);
      list.add(fileInfo);
    }
    return list;

  }
}