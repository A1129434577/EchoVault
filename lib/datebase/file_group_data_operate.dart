import 'dart:convert';

import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/alerts/create_playlist_alert.dart';
import 'package:echo_vault/datebase/app_datebase.dart';
import 'package:echo_vault/datebase/file_info_data_operate.dart';
import 'package:echo_vault/models/file_group.dart';

export 'package:echo_vault/models/file_group.dart';

class FileGroupDataOperate {
  static Future<int> insertFileGroup(FileGroup fileGroup) async {
    fileGroup.createTime ??= DateTime.now().millisecondsSinceEpoch;
    String content = jsonEncode(fileGroup.toJson());
    Database database = await AppDatabase.database;
    int id = await database.insert(
      AppDatabaseTable.mediaGroup,
      {
        'id': fileGroup.id,
        'json_content': content,
        'create_time': fileGroup.createTime,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  static Future<int> deleteFileGroup(FileGroup musicGroup) async {
    Database database = await AppDatabase.database;
    int deleteCount = await database.delete(
      AppDatabaseTable.mediaGroup,
      where: 'id = "${musicGroup.id}"',
    );

    return deleteCount;
  }

  static Future<FileGroup?> queryFileGroupFromId(String? id) async {
    List<FileGroup> list = await queryFileGroup(where: id!=null?'id = "$id"':'id IS null');
    return list.firstOrNull;
  }

  static Future<List<FileGroup>> queryFileGroup({int? limit, String? where}) async {
    Database database = await AppDatabase.database;
    List<Map<String, Object?>> dataList = await database.query(
      AppDatabaseTable.mediaGroup,
      limit: limit,
      where: where,
      orderBy: 'create_time desc',
    );
    List<FileGroup> list = [];
    for (var data in dataList) {
      String content = (data['json_content'])?.toString() ?? '';
      Map<String, dynamic> map = jsonDecode(content);
      FileGroup musicGroup = FileGroup.fromJson(map);
      String idsString = musicGroup.childrenIds.map((e){
        return '"$e"';
      }).toList().join(',');
      musicGroup.children = await FileInfoDataOperate.queryFileInfo(where: 'id IN ($idsString)');
      if(musicGroup.id?.startsWith(CreatePlaylistAlert.createPlaylistNamePrefix)==true) {
        if(musicGroup.children.isNotEmpty) {
          musicGroup.thumbnail = (musicGroup.children.first as FileInfo).thumbnail;
        }
      }
      list.add(musicGroup);
    }
    return list;
  }
}