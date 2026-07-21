import "package:bandha/features/journals/entities/journal.dart";
import "package:bandha/features/assets/entities/asset.dart";
import "package:bandha/features/entries/entities/entry.dart";
import "package:bandha/common/repositories/repository.dart";
import "package:sqlite3/sqlite3.dart";

class JournalRepository extends Repository {
  WithArgs withArgs;

  JournalRepository(super.db, {WithArgs? withArgs})
    : withArgs = withArgs ?? {};

  JournalRepository withAsset() {
    withArgs.add("asset");
    return JournalRepository(db, withArgs: withArgs);
  }

  sync(String id) async {
    final client = await getClient();
    final ResultSet rows = client.select(
      "SELECT SUM(entries.amount) AS balance FROM entries WHERE entries.journal_id = ? AND entries.status = ?",
      [id, EntryStatus.done.label],
    );

    final balance = (rows.first["balance"] ?? 0);

    client.execute("UPDATE journals SET balance = ? WHERE id = ?", [
      balance,
      id,
    ]);

    _syncAssetTotal(id);
  }

  bulkSave(Iterable<Journal> journals) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO journals (id, name, holder_name, balance, asset_id, created_at, updated_at) VALUES ${journals.map((_) => "(?, ?, ?, ?, ?, ?, ?)").join(", ")} ON CONFLICT DO UPDATE SET name = excluded.name, holder_name = excluded.holder_name, balance = excluded.balance, asset_id = excluded.asset_id, updated_at = excluded.updated_at",
      journals
          .map(
            (journal) => [
              journal.id,
              journal.name,
              journal.holderName,
              journal.balance,
              journal.assetId,
              journal.createdAt.toIso8601String(),
              journal.updatedAt.toIso8601String(),
            ],
          )
          .expand((args) => args)
          .toList(),
    );

    for (final assetId in journals.map((j) => j.assetId).toSet()) {
      _syncAssetTotalByAsset(assetId);
    }
  }

  save(Journal journal) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO journals (id, name, holder_name, balance, asset_id, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET name = excluded.name, holder_name = excluded.holder_name, balance = excluded.balance, asset_id = excluded.asset_id, updated_at = excluded.updated_at",
      [
        journal.id,
        journal.name,
        journal.holderName,
        journal.balance,
        journal.assetId,
        journal.createdAt.toIso8601String(),
        journal.updatedAt.toIso8601String(),
      ],
    );

    _syncAssetTotal(journal.id);
  }

  Future<Journal> get(String id) async {
    final client = await getClient();
    final ResultSet rows = client.select(
      "SELECT * FROM journals WHERE id = ?",
      [id],
    );

    return _entities(rows).then((journals) => journals.first);
  }

  Future<List<Journal>> search() async {
    final client = await getClient();
    final ResultSet rows = client.select(
      "SELECT * FROM journals ORDER BY journals.name, journals.holder_name;",
    );

    return _entities(rows);
  }

  delete(String id) async {
    final client = await getClient();
    client.execute("DELETE FROM journals WHERE id = ?", [id]);
    _syncAssetTotal(id);
  }

  _syncAssetTotal(String journalId) async {
    final client = await getClient();
    client.execute(
      "UPDATE assets SET total = (SELECT COALESCE(SUM(balance), 0) FROM journals WHERE asset_id = (SELECT asset_id FROM journals WHERE id = ?)) WHERE id = (SELECT asset_id FROM journals WHERE id = ?)",
      [journalId, journalId],
    );
  }

  _syncAssetTotalByAsset(String assetId) async {
    final client = await getClient();
    client.execute(
      "UPDATE assets SET total = (SELECT COALESCE(SUM(balance), 0) FROM journals WHERE asset_id = ?) WHERE id = ?",
      [assetId, assetId],
    );
  }

  Future<List<Journal>> _entities(List<Map> rows) async {
    if (withArgs.contains("asset")) {
      final assetIds =
          rows.map((row) => row["asset_id"] as String).toList();
      final assetRows = await getAssetByIds(assetIds);

      rows = rows.map((row) {
        return {
          ...row,
          "asset": assetRows.firstWhere(
            (assetRow) => assetRow["id"] == row["asset_id"],
          ),
        };
      }).toList();
    }

    return rows
        .map(
          (row) => Journal.row(row)
              .withAsset(Asset.tryRow(row["asset"])),
        )
        .toList();
  }
}
