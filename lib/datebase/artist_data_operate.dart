import 'dart:convert';

import 'package:echo_vault/datebase/app_datebase.dart';
import 'package:echo_vault/models/artist_info.dart';

class ArtistDataOperate {
  static Future<int> insertArtistInfo(ArtistInfo artistInfo) async {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    String content = jsonEncode(artistInfo.toJson());
    Database database = await AppDatabase.database;
    int id = await database.insert(
      AppDatabaseTable.artist,
      {
        'id': artistInfo.id,
        'is_favorite': artistInfo.isFavorite,
        'json_content': content,
        'create_time': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  static Future<int> deleteArtistInfo(ArtistInfo artistInfo) async {
    Database database = await AppDatabase.database;
    int deleteCount = await database.delete(
      AppDatabaseTable.artist,
      where: 'id = "${artistInfo.id}"',
    );
    return deleteCount;
  }

  static Future<ArtistInfo?> queryArtistInfoFromId(String artistId) async {
    List<ArtistInfo> list = await queryArtistInfo(where: 'id = "$artistId"');
    return list.firstOrNull;
  }

  static Future<List<ArtistInfo>> queryArtistInfo({int? limit, String? where}) async {
    Database database = await AppDatabase.database;
    List<Map<String, Object?>> dataList = await database.query(
      AppDatabaseTable.artist,
      limit: limit,
      where: where,
      orderBy: 'create_time desc',
    );
    List<ArtistInfo> list = [];
    for (var data in dataList) {
      String content = (data['json_content'])?.toString() ?? '';
      Map<String, dynamic> map = jsonDecode(content);
      ArtistInfo artistInfo = ArtistInfo.fromJson(map);
      list.add(artistInfo);
    }
    return list;
  }
}