import 'dart:io';

import 'package:bandha/common/services/service.dart';
import 'package:bandha/infra/db.dart';

class ToolService extends Service {
  final DatabaseManager dbManager;

  ToolService(this.dbManager);

  resetLedger() async {
    await dbManager.reset();
  }

  backupLedger(String backupPath) async {
    final client = await dbManager.current;
    client.execute("VACUUM INTO '$backupPath'");
  }

  restoreLedger(String backupPath) async {
    final client = await dbManager.current;
    client.dispose();

    final dbPath = await DatabaseManager.getPath();

    final dbFile = File(dbPath);
    if (dbFile.existsSync()) await dbFile.delete();

    final wal = File("$dbPath-wal");
    if (wal.existsSync()) await wal.delete();

    final shm = File("$dbPath-shm");
    if (shm.existsSync()) await shm.delete();

    final backupFile = File(backupPath);
    await backupFile.copy(dbPath);

    dbManager.disconnect();
  }
}
