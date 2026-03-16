import "package:bandha/features/vaults/entities/vault.dart";
import "package:bandha/features/entries/entities/entry.dart";
import "package:bandha/common/repositories/repository.dart";
import "package:sqlite3/sqlite3.dart";

class VaultRepository extends Repository {
  VaultRepository(super.db);

  sync(String id) async {
    final client = await getClient();
    final ResultSet rows = client.select(
      "SELECT SUM(entries.amount) AS balance FROM entries WHERE entries.vault_id = ? AND entries.status = ?",
      [id, EntryStatus.done.label],
    );

    final balance = (rows.first["balance"] ?? 0);

    client.execute("UPDATE vaults SET balance = ? WHERE id = ?", [
      balance,
      id,
    ]);
  }

  bulkSave(Iterable<Vault> vaults) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO vaults (id, name, holder_name, balance, created_at, updated_at) VALUES ${vaults.map((_) => "(?, ?, ?, ?, ?, ?)").join(", ")} ON CONFLICT DO UPDATE SET name = excluded.name, holder_name = excluded.holder_name, balance = excluded.balance, updated_at = excluded.updated_at",
      vaults
          .map(
            (vault) => [
              vault.id,
              vault.name,
              vault.holderName,
              vault.balance,
              vault.createdAt.toIso8601String(),
              vault.updatedAt.toIso8601String(),
            ],
          )
          .expand((args) => args)
          .toList(),
    );
  }

  save(Vault vault) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO vaults (id, name, holder_name, balance, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET name = excluded.name, holder_name = excluded.holder_name, balance = excluded.balance, updated_at = excluded.updated_at",
      [
        vault.id,
        vault.name,
        vault.holderName,
        vault.balance,
        vault.createdAt.toIso8601String(),
        vault.updatedAt.toIso8601String(),
      ],
    );
  }

  Future<Vault> get(String id) async {
    final client = await getClient();
    final ResultSet rows = client.select(
      "SELECT * FROM vaults WHERE id = ?",
      [id],
    );

    return rows.map((row) => Vault.row(row)).first;
  }

  Future<List<Vault>> search() async {
    final client = await getClient();
    final ResultSet rows = client.select(
      "SELECT * FROM vaults ORDER BY vaults.name, vaults.holder_name;",
    );

    return rows.map((row) => Vault.row(row)).toList();
  }

  delete(String id) async {
    final client = await getClient();
    client.execute("DELETE FROM vaults WHERE id = ?", [id]);
  }
}
