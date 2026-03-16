import 'package:bandha/common/repositories/repository.dart';
import 'package:bandha/common/types/pair.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:bandha/features/accounts/entities/account.dart';
import 'package:bandha/features/schedules/entities/schedule.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/tags/entities/category.dart';
import 'package:bandha/features/tags/entities/label.dart';

class ScheduleRepository extends Repository {
  WithArgs withArgs;

  ScheduleRepository(super.db, {WithArgs? withArgs}) : withArgs = withArgs ?? {};

  ScheduleRepository withLabels() {
    withArgs.add("labels");
    return ScheduleRepository(db, withArgs: withArgs);
  }

  ScheduleRepository withAccount() {
    withArgs.add("account");
    return ScheduleRepository(db, withArgs: withArgs);
  }

  ScheduleRepository withCategory() {
    withArgs.add("category");
    return ScheduleRepository(db, withArgs: withArgs);
  }

  ScheduleRepository withEntries() {
    withArgs.add("entries");
    return ScheduleRepository(db, withArgs: withArgs);
  }

  saveLabels(Schedule schedule) async {
    return setEntityLabels(
      entityId: schedule.id,
      labelIds: schedule.labelIds,
      junctionTable: "schedule_labels",
      junctionKey: "schedule_id",
    );
  }

  save(Schedule schedule) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO schedules (id, note, amount, fee, cycle, iteration, status, category_id, entry_id, addition_id, account_id, due_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET note = excluded.note, amount = excluded.amount, fee = excluded.fee, cycle = excluded.cycle, iteration = excluded.iteration, status = excluded.status, category_id = excluded.category_id, entry_id = excluded.entry_id, addition_id = excluded.addition_id, account_id = excluded.account_id, due_at = excluded.due_at, updated_at = excluded.updated_at",
      [
        schedule.id,
        schedule.note,
        schedule.amount,
        schedule.fee,
        schedule.cycle.label,
        schedule.iteration,
        schedule.status.label,
        schedule.categoryId,
        schedule.entryId,
        schedule.additionId,
        schedule.accountId,
        schedule.dueAt.toIso8601String(),
        schedule.createdAt.toIso8601String(),
        schedule.updatedAt.toIso8601String(),
      ],
    );

    return schedule;
  }

  delete(String id) async {
    final client = await getClient();
    client.execute("DELETE FROM schedules WHERE id = ?", [id]);
  }

  Future<List<Schedule>> search({Filter? filter}) async {
    final client = await getClient();
    var baseQuery = "SELECT schedules.* FROM schedules";

    final query = defineQuery(baseQuery, filter);
    final sqlString = "${query.first} ORDER BY schedules.updated_at DESC";
    final sqlArgs = query.second;

    final rows = client.select(sqlString, sqlArgs);

    return await entities(rows);
  }

  Future<Schedule?> get(String id) async {
    final client = await getClient();
    final rows = client.select("SELECT schedules.* FROM schedules WHERE id = ?", [id]);
    return (await entities(rows)).firstOrNull;
  }

  populateLabels(List<Map> rows) {
    return super.populateEntityLabels(rows, "schedule_labels", "schedule_id");
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

  Future<List<Schedule>> entities(List<Map> rows) async {
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

      return Schedule.row(r)
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
