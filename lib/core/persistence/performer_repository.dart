import 'dart:convert';

import 'package:echo_vault/core/persistence/application_database.dart';
import 'package:echo_vault/core/models/performer_details.dart';

class PerformerRepository {
  static Future<int> insertArtistInfo(PerformerDetails performerDetails) async {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    String content = jsonEncode(performerDetails.toJson());
    Database database = await ApplicationDatabase.database;
    int id = await database.insert(DatabaseTables.artist, {
      'id': performerDetails.id,
      'is_favorite': performerDetails.isFavorite,
      'json_content': content,
      'create_time': timestamp,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  static Future<int> deleteArtistInfo(PerformerDetails performerDetails) async {
    Database database = await ApplicationDatabase.database;
    int deleteCount = await database.delete(
      DatabaseTables.artist,
      where: 'id = "${performerDetails.id}"',
    );
    return deleteCount;
  }

  static Future<PerformerDetails?> queryArtistInfoFromId(
    String artistId,
  ) async {
    List<PerformerDetails> list = await queryArtistInfo(
      where: 'id = "$artistId"',
    );
    return list.firstOrNull;
  }

  static Future<List<PerformerDetails>> queryArtistInfo({
    int? limit,
    String? where,
  }) async {
    Database database = await ApplicationDatabase.database;
    List<Map<String, Object?>> records = await database.query(
      DatabaseTables.artist,
      limit: limit,
      where: where,
      orderBy: 'create_time desc',
    );
    List<PerformerDetails> list = [];
    for (var data in records) {
      String content = (data['json_content'])?.toString() ?? '';
      Map<String, dynamic> map = jsonDecode(content);
      PerformerDetails performerDetails = PerformerDetails.fromJson(map);
      list.add(performerDetails);
    }
    return list;
  }
}
