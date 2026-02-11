import 'dart:io';

import 'package:banda/infra/db_migration_files.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

class DB {
  static final DB _instance = DB._internal();
  static Database? _db;
  factory DB() => _instance;

  DB._internal();

  static beginTransaction() {
    _db!.execute("BEGIN TRANSACTION");
  }

  static commit() {
    _db!.execute("COMMIT");
  }

  static rollback() {
    _db!.execute("ROLLBACK");
  }

  static Future<String> getDir() async {
    final appDir = await getApplicationSupportDirectory();
    final dbDir = Directory(join(appDir.parent.path, 'databases'));
    if (!dbDir.existsSync()) dbDir.createSync(recursive: true);
    return dbDir.path;
  }

  static Future<String> getPath() async {
    return join(await DB.getDir(), "bandha.db");
  }

  static Future<void> reset() async {
    final db = _db!;

    db.execute("PRAGMA writable_schema = 1");
    db.execute("PRAGMA foreign_keys = OFF");
    final tables = db.select(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
    );

    for (var table in tables) {
      final tableName = table["name"] as String;
      try {
        db.execute("DROP TABLE IF EXISTS $tableName;");
      } catch (error, stackTrace) {
        if (kDebugMode) {
          print(error);
          print(stackTrace);
        }
      }
    }

    db.execute("PRAGMA foreign_keys = ON");
    db.execute("PRAGMA writable_schema = 0");
    db.execute("VACUUM");
    db.execute('PRAGMA user_version = 0;');

    await setup(db);
  }

  static disconnect() async {
    _db = null;
  }

  static Future<Database> connect() async {
    final dbPath = await DB.getPath();
    _db = sqlite3.open(dbPath);
    return await setup(_db!);
  }

  static reconnect() async {
    await disconnect();
    await connect();
  }

  Future<Database> get connection async {
    if (_db != null) return _db!;
    return connect();
  }

  static getMigrationVersion(Database db) {
    final rows = db.select('PRAGMA user_version;');
    if (rows.isEmpty) return 0;
    return rows.first["user_version"] ?? 0;
  }

  static setup(Database db) async {
    final currentVersion = getMigrationVersion(db);
    if (kDebugMode) {
      print("CURRENT VERSION $currentVersion");
    }

    db.createFunction(
      functionName: 'regexp',
      function: (args) {
        final pattern = args[0] as String;
        final value = args[1] as String?;
        return value != null && RegExp(pattern).hasMatch(value) ? 1 : 0;
      },
    );

    db.createFunction(
      functionName: 'uuid',
      function: (args) {
        return Uuid().v4();
      },
    );

    for (final dbMigrationFile in dbMigrationFiles) {
      final dbMigrationName = basename(dbMigrationFile);
      final version = int.tryParse(dbMigrationName.split("_").first);

      if (version == null) {
        continue;
      }

      if (currentVersion >= version) {
        continue;
      }

      final sql = await rootBundle.loadString(dbMigrationFile);

      try {
        final statements = sql.split(";");
        for (var s in statements) {
          final statement = s.trim();
          db.execute(statement);
        }

        db.execute("PRAGMA user_version = $version;");
        if (kDebugMode) {
          print("VERSION $version MIGRATED");
        }
      } catch (error, stackTrace) {
        if (kDebugMode) {
          print(error);
          print(stackTrace);
        }

        break;
      }
    }

    return db;
  }
}
