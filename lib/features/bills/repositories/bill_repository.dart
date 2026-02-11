import 'package:banda/common/repositories/repository.dart';
import 'package:banda/common/types/pair.dart';
import 'package:banda/common/types/specification.dart';
import 'package:banda/features/accounts/entities/account.dart';
import 'package:banda/features/bills/entities/bill.dart';
import 'package:banda/features/entries/entities/entry.dart';
import 'package:banda/features/tags/entities/category.dart';
import 'package:banda/features/tags/entities/label.dart';

class BillRepository extends Repository {
  WithArgs withArgs;

  BillRepository(super.db, {WithArgs? withArgs}) : withArgs = withArgs ?? {};

  BillRepository withLabels() {
    withArgs.add("labels");
    return BillRepository(db, withArgs: withArgs);
  }

  BillRepository withAccount() {
    withArgs.add("account");
    return BillRepository(db, withArgs: withArgs);
  }

  BillRepository withCategory() {
    withArgs.add("category");
    return BillRepository(db, withArgs: withArgs);
  }

  BillRepository withEntries() {
    withArgs.add("entries");
    return BillRepository(db, withArgs: withArgs);
  }

  saveLabels(Bill bill) async {
    return setEntityLabels(
      entityId: bill.id,
      labelIds: bill.labelIds,
      junctionTable: "bill_labels",
      junctionKey: "bill_id",
    );
  }

  save(Bill bill) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO bills (id, note, amount, fee, cycle, iteration, status, category_id, entry_id, addition_id, account_id, due_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET note = excluded.note, amount = excluded.amount, fee = excluded.fee, cycle = excluded.cycle, iteration = excluded.iteration, status = excluded.status, category_id = excluded.category_id, entry_id = excluded.entry_id, addition_id = excluded.addition_id, account_id = excluded.account_id, due_at = excluded.due_at, updated_at = excluded.updated_at",
      [
        bill.id,
        bill.note,
        bill.amount,
        bill.fee,
        bill.cycle.label,
        bill.iteration,
        bill.status.label,
        bill.categoryId,
        bill.entryId,
        bill.additionId,
        bill.accountId,
        bill.dueAt.toIso8601String(),
        bill.createdAt.toIso8601String(),
        bill.updatedAt.toIso8601String(),
      ],
    );

    return bill;
  }

  delete(String id) async {
    final client = await getClient();
    client.execute("DELETE FROM bills WHERE id = ?", [id]);
  }

  Future<List<Bill>> search({Filter? filter}) async {
    final client = await getClient();
    var baseQuery = "SELECT bills.* FROM bills";

    final query = defineQuery(baseQuery, filter);
    final sqlString = "${query.first} ORDER BY bills.updated_at DESC";
    final sqlArgs = query.second;

    final rows = client.select(sqlString, sqlArgs);

    return await entities(rows);
  }

  Future<Bill?> get(String id) async {
    final client = await getClient();
    final rows = client.select("SELECT bills.* FROM bills WHERE id = ?", [id]);
    return (await entities(rows)).firstOrNull;
  }

  populateLabels(List<Map> rows) {
    return super.populateEntityLabels(rows, "bill_labels", "bill_id");
  }

  populateEntries(List<Map> rows) async {
    final entryIds = rows
        .map((r) => [r["entry_id"], r["addition_id"]])
        .expand((i) => i)
        .whereType<String>()
        .toList();
    var entryRows = await getAnnotatedEntriesByIds(entryIds); 

    return rows.map((r) {
      return {
        ...r,
        "entry": entryRows.firstWhere((e) => e["id"] == r["entry_id"]),
        "addition": r["addition_id"] != null
            ? entryRows.firstWhere((e) => e["id"] == r["addition_id"])
            : null,
      };
    }).toList();
  }

  Future<List<Bill>> entities(List<Map> rows) async {
    if (withArgs.contains("entries")) {
      rows = await populateEntries(rows);
    }

    if (withArgs.contains("labels")) {
      rows = await populateLabels(rows);
    }

    if (withArgs.contains("account")) {
      rows = await populateAccount(rows);
    }

    if (withArgs.contains("category")) {
      rows = await populateCategory(rows);
    }

    return rows.map((r) {
      final entry = Entry.tryRow(
        r["entry"],
      )?.withAnnotations(r["entry"]?["annotations"]);
      final addition = Entry.tryRow(
        r["addition"],
      )?.withAnnotations(r["addition"]?["annotations"]);

      return Bill.row(r)
          .withLabels(Label.tryRows(r["labels"]))
          .withAccount(Account.tryRow(r["account"]))
          .withCategory(Category.tryRow(r["category"]))
          .withEntry(entry)
          .withAddition(addition);
    }).toList();
  }

  Map<String, dynamic>? joinQuery(spec) {
    return null;
  }

  Map<String, dynamic>? whereQuery(spec) {
    return null;
  }

  defineQuery(String baseQuery, Filter? filter) {
    var args = <dynamic>[];

    final join = joinQuery(filter);
    if (join != null && join["sql"].isNotEmpty) {
      baseQuery = "$baseQuery ${join["sql"]}";
    }

    final where = whereQuery(filter);
    if (where != null && where["sql"].isNotEmpty) {
      baseQuery = "$baseQuery WHERE ${where["sql"]}";
      args = where["args"];
    }

    return Pair(baseQuery, args);
  }
}
