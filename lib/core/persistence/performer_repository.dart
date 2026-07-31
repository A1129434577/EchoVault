import 'dart:convert';

import 'package:echo_vault/core/persistence/application_database.dart';
import 'package:echo_vault/core/models/performer_details.dart';

class PerformerRepository {
  static Future<int> removeArtistInfo(PerformerDetails performerProfile) async {
    Database databaseLocal = await ApplicationDatabase.database;
    int deleteCountLocal = await databaseLocal.delete(
      DatabaseTables.performerTable,
      where: 'id = "${performerProfile.id}"',
    );
    return deleteCountLocal;
  }

  static Future<int> addArtistInfo(PerformerDetails performerProfile) async {
    int timestampLocal = DateTime.now().millisecondsSinceEpoch;
    String encodedContent = jsonEncode(performerProfile.toJson());
    Database databaseLocal = await ApplicationDatabase.database;
    int idLocal = await databaseLocal.insert(DatabaseTables.performerTable, {
      'id': performerProfile.id,
      'is_favorite': performerProfile.isFavorite,
      'json_content': encodedContent,
      'create_time': timestampLocal,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return idLocal;
  }

  static Future<List<PerformerDetails>> fetchArtistInfo({
    int? limitInputArg,
    String? whereArg,
  }) async {
    Database databaseLocal = await ApplicationDatabase.database;
    List<Map<String, Object?>> storedRecords = await databaseLocal.query(
      DatabaseTables.performerTable,
      limit: limitInputArg,
      where: whereArg,
      orderBy: 'create_time desc',
    );
    List<PerformerDetails> entries = [];
    for (var data in storedRecords) {
      String encodedContent = (data['json_content'])?.toString() ?? '';
      Map<String, dynamic> record = jsonDecode(encodedContent);
      PerformerDetails performerProfile = PerformerDetails.fromJson(record);
      entries.add(performerProfile);
    }
    return entries;
  }

  static Future<PerformerDetails?> fetchArtistInfoFromId(
    String artistIdArg,
  ) async {
    List<PerformerDetails> entries = await fetchArtistInfo(
      whereArg: 'id = "$artistIdArg"',
    );
    return entries.firstOrNull;
  }
}
