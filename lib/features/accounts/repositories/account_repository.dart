import "package:banda/features/accounts/entities/account.dart";
import "package:banda/features/entries/entities/entry.dart";
import "package:banda/common/repositories/repository.dart";
import "package:sqlite3/sqlite3.dart";

class AccountRepository extends Repository {
  AccountRepository(super.db);

  sync(String id) async {
    final client = await getClient();
    final ResultSet rows = client.select(
      "SELECT SUM(entries.amount) AS balance FROM entries WHERE entries.account_id = ? AND entries.status = ?",
      [id, EntryStatus.done.label],
    );

    final balance = (rows.first["balance"] ?? 0);

    client.execute("UPDATE accounts SET balance = ? WHERE id = ?", [
      balance,
      id,
    ]);
  }

  bulkSave(Iterable<Account> accounts) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO accounts (id, name, holder_name, balance, kind, created_at, updated_at) VALUES ${accounts.map((_) => "(?, ?, ?, ?, ?, ?, ?)").join(", ")} ON CONFLICT DO UPDATE SET name = excluded.name, holder_name = excluded.holder_name, kind = excluded.kind, balance = excluded.balance, updated_at = excluded.updated_at",
      accounts
          .map(
            (account) => [
              account.id,
              account.name,
              account.holderName,
              account.balance,
              account.kind?.label,
              account.createdAt.toIso8601String(),
              account.updatedAt.toIso8601String(),
            ],
          )
          .expand((args) => args)
          .toList(),
    );
  }

  save(Account account) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO accounts (id, name, holder_name, balance, kind, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET name = excluded.name, holder_name = excluded.holder_name, kind = excluded.kind, balance = excluded.balance, updated_at = excluded.updated_at",
      [
        account.id,
        account.name,
        account.holderName,
        account.balance,
        account.kind?.label,
        account.createdAt.toIso8601String(),
        account.updatedAt.toIso8601String(),
      ],
    );
  }

  Future<Account> get(String id) async {
    final client = await getClient();
    final ResultSet rows = client.select(
      "SELECT * FROM accounts WHERE id = ?",
      [id],
    );

    return rows.map((row) => Account.row(row)).first;
  }

  Future<List<Account>> search() async {
    final client = await getClient();
    final ResultSet rows = client.select(
      "SELECT * FROM accounts ORDER BY accounts.name, accounts.holder_name;",
    );

    return rows.map((row) => Account.row(row)).toList();
  }

  delete(String id) async {
    final client = await getClient();
    client.execute("DELETE FROM accounts WHERE id = ?", [id]);
  }
}
