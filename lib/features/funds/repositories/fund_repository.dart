import 'package:bandha/common/repositories/repository.dart';
import 'package:bandha/common/types/transaction_type.dart';
import 'package:bandha/features/tags/entities/category.dart';
import 'package:bandha/features/journals/entities/journal.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/funds/entities/fund.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:sqlite3/sqlite3.dart';

class FundRepository extends Repository {
  final WithArgs withArgs;

  FundRepository(super.db, {WithArgs? withArgs})
    : withArgs = withArgs ?? {};

  FundRepository withJournal() {
    withArgs.add("journal");
    return FundRepository(db, withArgs: withArgs);
  }

  FundRepository withCategory() {
    withArgs.add("category");
    return FundRepository(db, withArgs: withArgs);
  }

  FundRepository withLabels() {
    withArgs.add("labels");
    return FundRepository(db, withArgs: withArgs);
  }

  save(Fund fund) async {
    final client = await getClient();

    client.execute(
      "INSERT INTO funds (id, note, amount, balance, status, category_id, journal_id, created_at, updated_at, released_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET note = excluded.note, amount = excluded.amount, balance = excluded.balance, category_id = excluded.category_id, journal_id = excluded.journal_id, updated_at = excluded.updated_at, status = excluded.status, released_at = excluded.released_at",
      [
        fund.id,
        fund.note,
        fund.amount,
        fund.balance,
        fund.status.label,
        fund.categoryId,
        fund.journalId,
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
        "SELECT SUM(entries.amount) AS balance FROM fund_entries JOIN entries ON entries.id = fund_entries.entry_id WHERE fund_entries.fund_id = ? AND entries.status = ?",
        [id, EntryStatus.done.label],
      );

      final balance = (rows.first["balance"] ?? 0);

      client.execute("UPDATE funds SET balance = ? WHERE id = ?", [
        balance * -1,
        id,
      ]);
    });
  }

  saveTransaction(Fund fund, TransactionType type, Entry entry) async {
    final client = await getClient();
    final now = DateTime.now().toIso8601String();

    client.execute(
      "INSERT INTO fund_entries (fund_id, entry_id, note, created_at, updated_at) VALUES (?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET note = excluded.note, updated_at = excluded.updated_at",
      [fund.id, entry.id, type.label, now, now],
    );
  }

  removeTransaction(Fund fund, Entry entry) async {
    final client = await getClient();
    client.execute(
      "DELETE FROM fund_entries WHERE fund_id = ? AND entry_id = ?",
      [fund.id, entry.id],
    );

    client.execute("DELETE FROM entries WHERE id = ?", [entry.id]);
  }

  removeTransactions(Fund fund) async {
    final client = await getClient();
    client.execute(
      "DELETE FROM entries WHERE id IN (SELECT fund_entries.entry_id FROM fund_entries WHERE fund_entries.fund_id = ?)",
      [fund.id],
    );
  }

  delete(String id) async {
    final client = await getClient();
    client.execute("DELETE FROM funds WHERE id = ?", [id]);
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
    if (withArgs.contains("journal")) {
      rows = await populateJournal(rows);
    }

    if (withArgs.contains("category")) {
      rows = await populateCategory(rows);
    }

    if (withArgs.contains("labels")) {
      rows = await populateLabels(rows);
    }

    return rows
        .map(
          (row) => Fund.row(row)
              .withCategory(Category.tryRow(row["category"]))
              .withLabels(Label.tryRows(row["labels"]))
              .withJournal(Journal.tryRow(row["journal"])),
        )
        .toList();
  }
}
