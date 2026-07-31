import 'dart:convert';

import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/persistence/application_database.dart';

class MediaRepository {
  static Future<int> removeFileInfo(FileInfo mediaEntry) async {
    Database databaseLocal = await ApplicationDatabase.database;
    int deleteCountLocal = await databaseLocal.delete(
      DatabaseTables.files,
      where: 'id = "${mediaEntry.fileId}"',
    );
    return deleteCountLocal;
  }

  static Future<int> addFileInfo(FileInfo mediaEntry) async {
    int timestampLocal = DateTime.now().millisecondsSinceEpoch;
    String encodedContent = jsonEncode(mediaEntry.toJson());
    Database databaseLocal = await ApplicationDatabase.database;
    int idLocal = await databaseLocal.insert(DatabaseTables.files, {
      'id': mediaEntry.fileId,
      'download_status': mediaEntry.downloadStatus,
      'download_task_id': mediaEntry.downloadTaskId,
      'is_favorite': mediaEntry.isFavorite,
      'json_content': encodedContent,
      'create_time': timestampLocal,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return idLocal;
  }

  static Future<List<FileInfo>> fetchFileInfo({
    int? limitInputArg,
    String? whereArg,
  }) async {
    Database databaseLocal = await ApplicationDatabase.database;
    List<Map<String, Object?>> storedRecords = await databaseLocal.query(
      DatabaseTables.files,
      limit: limitInputArg,
      where: whereArg,
      orderBy: 'create_time desc',
    );
    List<FileInfo> entries = [];
    for (var data in storedRecords) {
      String encodedContent = (data['json_content'])?.toString() ?? '';
      Map<String, dynamic> record = jsonDecode(encodedContent);
      FileInfo mediaEntry = FileInfo.fromJson(record);
      entries.add(mediaEntry);
    }
    return entries;
  }

  static Future<FileInfo?> fetchFileInfoFromId(String fileIdArg) async {
    List<FileInfo> entries = await fetchFileInfo(whereArg: 'id = "$fileIdArg"');
    return entries.firstOrNull;
  }
}
