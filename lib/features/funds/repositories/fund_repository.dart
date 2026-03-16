import 'package:bandha/common/repositories/repository.dart';
import 'package:bandha/features/accounts/entities/account.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/funds/entities/fund.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:sqlite3/sqlite3.dart';

class FundRepository extends Repository {
  final WithArgs withArgs;

  FundRepository(super.db, {WithArgs? withArgs})
    : withArgs = withArgs ?? {};

  FundRepository withAccount() {
    withArgs.add("account");
    return FundRepository(db, withArgs: withArgs);
  }

  FundRepository withLabels() {
    withArgs.add("labels");
    return FundRepository(db, withArgs: withArgs);
  }

  save(Fund fund) async {
    final client = await getClient();

    client.execute(
      "INSERT INTO funds (id, note, goal, balance, status, account_id, created_at, updated_at, released_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET note = excluded.note, goal = excluded.goal, balance = excluded.balance, account_id = excluded.account_id, updated_at = excluded.updated_at, status = excluded.status, released_at = excluded.released_at",
      [
        fund.id,
        fund.note,
        fund.goal,
        fund.balance,
        fund.status.label,
        fund.accountId,
        fund.createdAt.toIso8601String(),
        fund.updatedAt.toIso8601String(),
        fund.releasedAt?.toIso8601String(),
      ],
    );
  }

  Future<List<Fund>> search(Filter? spec) async {
    final client = await getClient();
    final rows = client.select("SELECT funds.* FROM funds");
    return entities(rows);
  }

  Future<Fund> get(String id) async {
    final client = await getClient();
    final rows = client.select("SELECT * FROM funds WHERE id = ?", [
      id,
    ]);
    return entities(rows).then((fund) => fund.first);
  }

  sync(String id) async {
    return Repository.work<void>(() async {
      final client = await getClient();
      final ResultSet rows = client.select(
        "SELECT SUM(entries.amount) AS balance FROM fund_transactions JOIN entries ON entries.id = fund_transactions.entry_id WHERE fund_transactions.fund_id = ? AND entries.status = ?",
        [id, EntryStatus.done.label],
      );

      final balance = (rows.first["balance"] ?? 0);

      client.execute("UPDATE funds SET balance = ? WHERE id = ?", [
        balance * -1,
        id,
      ]);
    });
  }

  saveTransaction(Fund fund, Entry entry) async {
    final client = await getClient();
    final now = DateTime.now().toIso8601String();

    client.execute(
      "INSERT INTO fund_transactions (fund_id, entry_id, created_at, updated_at) VALUES (?, ?, ?, ?) ON CONFLICT DO UPDATE SET updated_at = excluded.updated_at",
      [fund.id, entry.id, now, now],
    );
  }

  removeTransaction(Fund fund, Entry entry) async {
    final client = await getClient();
    client.execute(
      "DELETE FROM fund_transactions WHERE fund_id = ? AND entry_id = ?",
      [fund.id, entry.id],
    );

    client.execute("DELETE FROM entries WHERE id = ?", [entry.id]);
  }

  removeTransactions(Fund fund) async {
    final client = await getClient();
    client.execute(
      "DELETE FROM entries WHERE id IN (SELECT fund_transactions.entry_id FROM fund_transactions WHERE fund_transactions.fund_id = ?)",
      [fund.id],
    );
  }

  delete(String id) async {
    final client = await getClient();
    client.execute("DELETE FROM fund WHERE id = ?", [id]);
  }

  saveLabels(String fundId, List<String> labelIds) {
    return setEntityLabels(
      entityId: fundId,
      labelIds: labelIds,
      junctionTable: "fund_labels",
      junctionKey: "fund_id",
    );
  }

  removeLabels(Fund fund) async {
    return resetEntityLabels(
      entityId: fund.id,
      junctionTable: "fund_labels",
      junctionKey: "fund_id",
    );
  }

  populateLabels(List<Map> rows) {
    return super.populateEntityLabels(rows, "fund_labels", "fund_id");
  }

  Future<List<Fund>> entities(List<Map> rows) async {
    if (withArgs.contains("account")) {
      rows = await populateAccount(rows);
    }

    if (withArgs.contains("labels")) {
      rows = await populateLabels(rows);
    }

    return rows
        .map(
          (row) => Fund.row(row)
              .withLabels(Label.tryRows(row["labels"]))
              .withAccount(Account.tryRow(row["account"])),
        )
        .toList();
  }
}
