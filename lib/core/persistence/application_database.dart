import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:echo_vault/core/monetization/advertising_coordinator.dart';

export 'package:sqflite/sqflite.dart';

class ApplicationDatabase {
  static final AsyncMemoizer<Database> _memoizer = AsyncMemoizer();
  static Database? _database;

  static Future<Database> get database async {
    return _memoizer.runOnce(() async {
      var documentsDirectoryPathLocal = await getDatabasesPath();
      String databasePathLocal =
          '$documentsDirectoryPathLocal${Platform.pathSeparator}Database${Platform.pathSeparator}echo_vault.db';
      _database = await openDatabase(
        databasePathLocal,
        version: 3,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      return _database!;
    });
  }

  static Future _onCreate(Database dbArg, int versionArg) async {
    await dbArg.execute('''
        CREATE TABLE ${DatabaseTables.mediaCollection} (
        id TEXT PRIMARY KEY,
        json_content TEXT,
        create_time INTEGER)
        ''');
    await dbArg.execute('''
        CREATE TABLE ${DatabaseTables.files} (
        id TEXT PRIMARY KEY,
        download_status INTEGER,
        is_favorite INTEGER,
        json_content TEXT,
        create_time INTEGER)
        ''');
    await dbArg.execute('''
        CREATE TABLE ${DatabaseTables.performer} (
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
    _database = null;
  }

  ///version为2的时候新增的字段
  static Future _version2Upgrade(Database dbArg) async {}

  ///version为3的时候新增的字段
  static Future _version3Upgrade(Database dbArg) async {
    await dbArg.transaction((txnInputArg) async {
      await txnInputArg.execute(
        'ALTER TABLE ${DatabaseTables.files} ADD COLUMN download_task_id TEXT',
      );
    });
  }
}

class DatabaseTables {
  static const String mediaCollection = 'media_collection';
  static const String files = 'files';
  static const String performer = 'performer';
}
