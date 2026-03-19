import 'package:bandha/common/repositories/repository.dart';
import 'package:bandha/common/types/transaction_type.dart';
import 'package:bandha/features/tags/entities/category.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/pools/entities/pool.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:sqlite3/sqlite3.dart';

class PoolRepository extends Repository {
  final WithArgs withArgs;

  PoolRepository(super.db, {WithArgs? withArgs})
    : withArgs = withArgs ?? {};

  PoolRepository withVault() {
    withArgs.add("vault");
    return PoolRepository(db, withArgs: withArgs);
  }

  PoolRepository withCategory() {
    withArgs.add("category");
    return PoolRepository(db, withArgs: withArgs);
  }

  PoolRepository withLabels() {
    withArgs.add("labels");
    return PoolRepository(db, withArgs: withArgs);
  }

  save(Pool pool) async {
    final client = await getClient();

    client.execute(
      "INSERT INTO pools (id, note, goal, balance, status, category_id, vault_id, created_at, updated_at, released_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET note = excluded.note, goal = excluded.goal, balance = excluded.balance, category_id = excluded.category_id, vault_id = excluded.vault_id, updated_at = excluded.updated_at, status = excluded.status, released_at = excluded.released_at",
      [
        pool.id,
        pool.note,
        pool.goal,
        pool.balance,
        pool.status.label,
        pool.categoryId,
        pool.vaultId,
        pool.createdAt.toIso8601String(),
        pool.updatedAt.toIso8601String(),
        pool.releasedAt?.toIso8601String(),
      ],
    );
  }

  Future<List<Pool>> search(Filter? spec) async {
    final client = await getClient();
    final rows = client.select("SELECT pools.* FROM pools");
    return entities(rows);
  }

  Future<Pool> get(String id) async {
    final client = await getClient();
    final rows = client.select("SELECT * FROM pools WHERE id = ?", [
      id,
    ]);
    return entities(rows).then((pool) => pool.first);
  }

  sync(String id) async {
    return Repository.work<void>(() async {
      final client = await getClient();
      final ResultSet rows = client.select(
        "SELECT SUM(entries.amount) AS balance FROM pool_transactions JOIN entries ON entries.id = pool_transactions.entry_id WHERE pool_transactions.pool_id = ? AND entries.status = ?",
        [id, EntryStatus.done.label],
      );

      final balance = (rows.first["balance"] ?? 0);

      client.execute("UPDATE pools SET balance = ? WHERE id = ?", [
        balance * -1,
        id,
      ]);
    });
  }

  saveTransaction(Pool pool, TransactionType type, Entry entry) async {
    final client = await getClient();
    final now = DateTime.now().toIso8601String();

    client.execute(
      "INSERT INTO pool_transactions (pool_id, entry_id, kind, created_at, updated_at) VALUES (?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET kind = excluded.kind, updated_at = excluded.updated_at",
      [pool.id, entry.id, type.label, now, now],
    );
  }

  removeTransaction(Pool pool, Entry entry) async {
    final client = await getClient();
    client.execute(
      "DELETE FROM pool_transactions WHERE pool_id = ? AND entry_id = ?",
      [pool.id, entry.id],
    );

    client.execute("DELETE FROM entries WHERE id = ?", [entry.id]);
  }

  removeTransactions(Pool pool) async {
    final client = await getClient();
    client.execute(
      "DELETE FROM entries WHERE id IN (SELECT pool_transactions.entry_id FROM pool_transactions WHERE pool_transactions.pool_id = ?)",
      [pool.id],
    );
  }

  delete(String id) async {
    final client = await getClient();
    client.execute("DELETE FROM pool WHERE id = ?", [id]);
  }

  saveLabels(String poolId, List<String> labelIds) {
    return setEntityLabels(
      entityId: poolId,
      labelIds: labelIds,
      junctionTable: "pool_labels",
      junctionKey: "pool_id",
    );
  }

  removeLabels(Pool pool) async {
    return resetEntityLabels(
      entityId: pool.id,
      junctionTable: "pool_labels",
      junctionKey: "pool_id",
    );
  }

  populateLabels(List<Map> rows) {
    return super.populateEntityLabels(rows, "pool_labels", "pool_id");
  }

  Future<List<Pool>> entities(List<Map> rows) async {
    if (withArgs.contains("vault")) {
      rows = await populateVault(rows);
    }

    if (withArgs.contains("category")) {
      rows = await populateCategory(rows);
    }

    if (withArgs.contains("labels")) {
      rows = await populateLabels(rows);
    }

    return rows
        .map(
          (row) => Pool.row(row)
              .withCategory(Category.tryRow(row["category"]))
              .withLabels(Label.tryRows(row["labels"]))
              .withVault(Vault.tryRow(row["vault"])),
        )
        .toList();
  }
}
