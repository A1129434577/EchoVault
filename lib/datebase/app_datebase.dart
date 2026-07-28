import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:echo_vault/ads/ads_manager.dart';

export 'package:sqflite/sqflite.dart';

class AppDatabaseTable{
  static const String mediaGroup = 'file_group';
  static const String media = 'media';
  static const String artist = 'artist';
}

class AppDatabase {
  static final AsyncMemoizer<Database> _memoizer = AsyncMemoizer();
  static Database? _database;

  static Future<Database> get database async {
    return _memoizer.runOnce(() async {
      var documentsDirectoryPath = await getDatabasesPath();
      String databasePath = '$documentsDirectoryPath${Platform.pathSeparator}Database${Platform.pathSeparator}via_time.db';
      _database = await openDatabase(
        databasePath,
        version: 3,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      return _database!;
    });
  }

  static Future _onCreate(Database db, int version) async {
    await db.execute('''
        CREATE TABLE ${AppDatabaseTable.mediaGroup} (
        id TEXT PRIMARY KEY,
        json_content TEXT,
        create_time INTEGER)
        ''');
    await db.execute('''
        CREATE TABLE ${AppDatabaseTable.media} (
        id TEXT PRIMARY KEY,
        download_status INTEGER,
        is_favorite INTEGER,
        json_content TEXT,
        create_time INTEGER)
        ''');
    await db.execute('''
        CREATE TABLE ${AppDatabaseTable.artist} (
        id TEXT PRIMARY KEY,
        is_favorite INTEGER,
        json_content TEXT,
        create_time INTEGER)
        ''');
    await _version2Upgrade(db);
    await _version3Upgrade(db);
  }

  ///数据库更新回调
  ///只在数据库相较于上一个版本有升级时回调
  static Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _version2Upgrade(db);
    }
    if (oldVersion < 3) {
      await _version3Upgrade(db);
    }
    //升级数据库会导致数据库关闭，将database置空，让其重新打开
    _database = null;
  }

  ///version为2的时候新增的字段
  static Future _version2Upgrade(Database db) async {

  }

  ///version为3的时候新增的字段
  static Future _version3Upgrade(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('ALTER TABLE ${AppDatabaseTable.media} ADD COLUMN download_task_id TEXT');
    });
  }
}