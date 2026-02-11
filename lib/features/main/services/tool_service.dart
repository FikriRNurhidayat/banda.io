import 'dart:io';

import 'package:banda/common/services/service.dart';
import 'package:banda/infra/db.dart';
import 'package:sqlite3/sqlite3.dart';

class ToolService extends Service {
  final Database db;

  ToolService(this.db);

  backupLedger(String backupPath) {
    db.execute("VACUUM INTO '$backupPath'");
  }

  restoreLedger(String backupPath) async {
    db.dispose();

    final dbPath = await DB.getPath();

    final dbFile = File(dbPath);
    if (dbFile.existsSync()) await dbFile.delete();

    final wal = File("$dbPath-wal");
    if (wal.existsSync()) await wal.delete();

    final shm = File("$dbPath-shm");
    if (shm.existsSync()) await shm.delete();

    final backupFile = File(backupPath);
    await backupFile.copy(dbPath);
  }
}
