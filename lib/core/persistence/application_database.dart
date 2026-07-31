import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:echo_vault/core/monetization/advertising_coordinator.dart';

export 'package:sqflite/sqflite.dart';

class ApplicationDatabase {
  static final AsyncMemoizer<Database> _databaseLoader = AsyncMemoizer();
  static Database? _activeDatabase;

  static Future<Database> get database async {
    return _databaseLoader.runOnce(() async {
      var documentsDirectoryPathLocal = await getDatabasesPath();
      String databasePathLocal =
          '$documentsDirectoryPathLocal${Platform.pathSeparator}Database${Platform.pathSeparator}echo_vault.db';
      _activeDatabase = await openDatabase(
        databasePathLocal,
        version: 3,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      return _activeDatabase!;
    });
  }

  static Future _onCreate(Database dbArg, int versionArg) async {
    await dbArg.execute('''
        CREATE TABLE ${DatabaseTables.collectionTable} (
        id TEXT PRIMARY KEY,
        json_content TEXT,
        create_time INTEGER)
        ''');
    await dbArg.execute('''
        CREATE TABLE ${DatabaseTables.mediaTable} (
        id TEXT PRIMARY KEY,
        download_status INTEGER,
        is_favorite INTEGER,
        json_content TEXT,
        create_time INTEGER)
        ''');
    await dbArg.execute('''
        CREATE TABLE ${DatabaseTables.performerTable} (
        id TEXT PRIMARY KEY,
        is_favorite INTEGER,
        json_content TEXT,
        create_time INTEGER)
        ''');
    await _version2Upgrade(dbArg);
    await _version3Upgrade(dbArg);
  }

  ///数据库更新回调
  ///只在数据库相较于上一个版本有升级时回调
  static Future _onUpgrade(
    Database dbArg,
    int oldVersionArg,
    int newVersionArg,
  ) async {
    if (oldVersionArg < 2) {
      await _version2Upgrade(dbArg);
    }
    if (oldVersionArg < 3) {
      await _version3Upgrade(dbArg);
    }
    //升级数据库会导致数据库关闭，将database置空，让其重新打开
    _activeDatabase = null;
  }

  ///version为2的时候新增的字段
  static Future _version2Upgrade(Database dbArg) async {}

  ///version为3的时候新增的字段
  static Future _version3Upgrade(Database dbArg) async {
    await dbArg.transaction((txnInputArg) async {
      await txnInputArg.execute(
        'ALTER TABLE ${DatabaseTables.mediaTable} ADD COLUMN download_task_id TEXT',
      );
    });
  }
}

class DatabaseTables {
  static const String collectionTable = 'media_collection';
  static const String mediaTable = 'files';
  static const String performerTable = 'performer';
}
