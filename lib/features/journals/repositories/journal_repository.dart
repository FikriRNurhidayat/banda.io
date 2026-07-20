import "package:bandha/features/journals/entities/journal.dart";
import "package:bandha/features/entries/entities/entry.dart";
import "package:bandha/common/repositories/repository.dart";
import "package:sqlite3/sqlite3.dart";

class JournalRepository extends Repository {
  JournalRepository(super.db);

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
  }

  bulkSave(Iterable<Journal> journals) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO journals (id, name, holder_name, balance, created_at, updated_at) VALUES ${journals.map((_) => "(?, ?, ?, ?, ?, ?)").join(", ")} ON CONFLICT DO UPDATE SET name = excluded.name, holder_name = excluded.holder_name, balance = excluded.balance, updated_at = excluded.updated_at",
      journals
          .map(
            (journal) => [
              journal.id,
              journal.name,
              journal.holderName,
              journal.balance,
              journal.createdAt.toIso8601String(),
              journal.updatedAt.toIso8601String(),
            ],
          )
          .expand((args) => args)
          .toList(),
    );
  }

  save(Journal journal) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO journals (id, name, holder_name, balance, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET name = excluded.name, holder_name = excluded.holder_name, balance = excluded.balance, updated_at = excluded.updated_at",
      [
        journal.id,
        journal.name,
        journal.holderName,
        journal.balance,
        journal.createdAt.toIso8601String(),
        journal.updatedAt.toIso8601String(),
      ],
    );
  }

  Future<Journal> get(String id) async {
    final client = await getClient();
    final ResultSet rows = client.select(
      "SELECT * FROM journals WHERE id = ?",
      [id],
    );

    return rows.map((row) => Journal.row(row)).first;
  }

  Future<List<Journal>> search() async {
    final client = await getClient();
    final ResultSet rows = client.select(
      "SELECT * FROM journals ORDER BY journals.name, journals.holder_name;",
    );

    return rows.map((row) => Journal.row(row)).toList();
  }

  delete(String id) async {
    final client = await getClient();
    client.execute("DELETE FROM journals WHERE id = ?", [id]);
  }
}
