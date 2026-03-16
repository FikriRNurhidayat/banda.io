import 'package:bandha/common/entities/controlable.dart';
import 'package:bandha/features/accounts/entities/account.dart';
import 'package:bandha/features/tags/entities/category.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/common/repositories/repository.dart';
import 'package:bandha/common/types/pair.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart';

class EntryRepository extends Repository {
  WithArgs withArgs;

  EntryRepository(super.db, {WithArgs? withArgs})
    : withArgs = withArgs ?? {};

  EntryRepository withAnnotations() {
    return EntryRepository(db, withArgs: {...withArgs, "annotations"});
  }

  EntryRepository withLabels() {
    return EntryRepository(db, withArgs: {...withArgs, "labels"});
  }

  EntryRepository withAccount() {
    return EntryRepository(db, withArgs: {...withArgs, "account"});
  }

  EntryRepository withCategory() {
    return EntryRepository(db, withArgs: {...withArgs, "category"});
  }

  bulkSave(Iterable<Entry> entries) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO entries (id, note, amount, readonly, status, category_id, account_id, controller_id, controller_type, issued_at, created_at, updated_at) VALUES ${entries.map((_) => "(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)").join(", ")} ON CONFLICT DO UPDATE SET note = excluded.note, amount = excluded.amount, readonly = excluded.readonly, status = excluded.status, issued_at = excluded.issued_at, category_id = excluded.category_id, account_id = excluded.account_id, controller_id = excluded.controller_id, controller_type = excluded.controller_type, updated_at = excluded.updated_at",
      entries
          .map(
            (entry) => [
              entry.id,
              entry.note,
              entry.amount,
              entry.readonly ? 1 : 0,
              entry.status.label,
              entry.categoryId,
              entry.accountId,
              entry.controller?.id,
              entry.controller?.type.label,
              entry.issuedAt.toIso8601String(),
              entry.createdAt.toIso8601String(),
              entry.updatedAt.toIso8601String(),
            ],
          )
          .expand((i) => i)
          .toList(),
    );

    if (_include("annotations")) {
      await _saveAnnotations(entries);
    }

    if (_include("labels")) {
      await _saveLabels(entries);
    }
  }

  save(Entry entry) async {
    return bulkSave([entry]);
  }

  saveAnnotations(
    String entryId,
    Map<String, dynamic>? annotations,
  ) async {
    final client = await getClient();
    client.execute("DELETE FROM entry_annotations WHERE entry_id = ?", [
      entryId,
    ]);

    if (annotations == null || annotations.isEmpty) {
      return;
    }

    final arguments = annotations.entries
        .map(
          (annotation) => [entryId, annotation.key, annotation.value],
        )
        .expand((i) => i)
        .toList();

    client.execute(
      "INSERT INTO entry_annotations (entry_id, name, value) VALUES ${annotations.entries.map((_) => "(?, ?, ?)").join(", ")} ON CONFLICT (entry_id, name) DO UPDATE SET value = excluded.value",
      arguments,
    );
  }

  saveLabels(String entryId, List<String> labelIds) {
    return setEntityLabels(
      entityId: entryId,
      labelIds: labelIds,
      junctionTable: "entry_labels",
      junctionKey: "entry_id",
    );
  }

  removeLabels(Entry entry) async {
    return resetEntityLabels(
      entityId: entry.id,
      junctionTable: "entry_labels",
      junctionKey: "entry_id",
    );
  }

  Future<Entry> get(String id) async {
    final client = await getClient();
    final ResultSet entryRows = client.select(
      "SELECT entries.* FROM entries WHERE id = ?",
      [id],
    );

    return entities(entryRows).then((entries) => entries.first);
  }

  Future<void> deleteByController(Controlable controlable) async {
    final client = await getClient();
    final controller = controlable.toController();
    client.execute(
      "DELETE FROM entries WHERE controller_id = ? AND controller_type = ?",
      [controller.id, controller.type.label],
    );
  }

  Future<void> deleteByIds(Iterable<String> ids) async {
    if (ids.isEmpty) {
      return;
    }

    final client = await getClient();

    client.execute(
      "DELETE FROM entries WHERE id IN (${ids.map((_) => "?").join(", ")})",
      ids.toList(),
    );
  }

  Future<List<Entry>> controlledBy(Controlable controlable) async {
    final controller = controlable.toController();

    return await search({
      "controller_id_is": controller.id,
      "controller_type_is": controller.type.label,
    });
  }

  Future<List<Entry>> search(Filter? filter) async {
    var baseQuery = "SELECT entries.* FROM entries";

    final query = defineQuery(baseQuery, filter);
    final sqlString = "${query.first} ORDER BY entries.issued_at DESC";
    final sqlArgs = query.second;

    final client = await getClient();
    final ResultSet entryRows = client.select(sqlString, sqlArgs);

    return await entities(entryRows);
  }

  delete(String id) async {
    final client = await getClient();
    client.execute("DELETE FROM entries WHERE entries.id = ?", [id]);
  }

  populateLabels(List<Map> rows) {
    return super.populateEntityLabels(rows, "entry_labels", "entry_id");
  }

  Future<List<Entry>> entities(List<Map> entryRows) async {
    if (withArgs.contains("annotations")) {
      final entryIds = entryRows.map((e) => e["id"] as String).toList();
      final annotationRows = await getAnnotations(entryIds);
      entryRows = entryRows.map((entry) {
        final annotations = <String, dynamic>{};

        for (var annotation in annotationRows.where(
          (annotation) => annotation["entry_id"] == entry["id"],
        )) {
          annotations[annotation["name"] as String] =
              annotation["value"];
        }

        return {...entry, "annotations": annotations};
      }).toList();
    }

    if (withArgs.contains("labels")) {
      entryRows = await populateLabels(entryRows);
    }

    if (withArgs.contains("account")) {
      entryRows = await populateAccount(entryRows);
    }

    if (withArgs.contains("category")) {
      entryRows = await populateCategory(entryRows);
    }

    return entryRows.map((e) {
      return Entry.row(e)
          .withLabels(Label.tryRows(e["labels"]))
          .withAccount(Account.tryRow(e["account"]))
          .withCategory(Category.tryRow(e["category"]))
          .withAnnotations(e["annotations"]);
    }).toList();
  }

  Pair<String, List<dynamic>> defineQuery(String baseQuery, Map? spec) {
    var args = <dynamic>[];

    final join = joinQuery(spec);
    if (join != null && join["sql"].isNotEmpty) {
      baseQuery = "$baseQuery ${join["sql"]}";
    }

    final where = whereQuery(spec);
    if (where != null && where["sql"].isNotEmpty) {
      baseQuery = "$baseQuery WHERE ${where["sql"]}";
      args = where["args"];
    }

    return Pair(baseQuery, args);
  }

  joinQuery(Map? spec) {
    if (spec == null) return null;

    final Map<String, dynamic> join = {
      "query": <String>[],
      "sql": null,
    };

    if (spec.containsKey("label_in")) {
      final value = spec["label_in"] as List<String>;
      if (value.isNotEmpty) {
        join["query"].add(
          "INNER JOIN entry_labels ON entry_labels.entry_id = entries.id",
        );
      }
    }

    if (spec.containsKey("fund_in")) {
      final value = spec["fund_in"] as List<String>;
      if (value.isNotEmpty) {
        join["query"].add(
          "INNER JOIN fund_transactions ON fund_transactions.entry_id = entries.id",
        );
      }
    }

    join["sql"] = join["query"].join(" ");

    return join;
  }

  whereQuery(Map? filter) {
    if (filter == null) return null;

    final Map<String, dynamic> where = {
      "args": <dynamic>[],
      "query": <String>[],
      "sql": null,
    };

    if (filter.containsKey("note_regex")) {
      final value = filter["note_regex"];
      if (value.isNotEmpty) {
        where["query"].add("REGEXP(?, entries.note)");
        where["args"].add(filter["note_regex"]);
      }
    }

    if (filter.containsKey("amount_lt")) {
      final value = filter["amount_lt"] as double;
      where["query"].add("entries.amount < ?");
      where["args"].add(value);
    }

    if (filter.containsKey("amount_lte")) {
      final value = filter["amount_lte"] as double;
      where["query"].add("entries.amount <= ?");
      where["args"].add(value);
    }

    if (filter.containsKey("amount_gt")) {
      final value = filter["amount_gt"] as double;
      where["query"].add("entries.amount > ?");
      where["args"].add(value);
    }

    if (filter.containsKey("amount_gte")) {
      final value = filter["amount_gte"] as double;
      where["query"].add("entries.amount >= ?");
      where["args"].add(value);
    }

    if (filter.containsKey("issued_between")) {
      final value = filter["issued_between"] as DateTimeRange;
      where["query"].add("(entries.issued_at BETWEEN ? AND ?)");
      where["args"].addAll([
        value.start.toIso8601String(),
        value.end.toIso8601String(),
      ]);
    }

    if (filter.containsKey("account_in")) {
      final value = filter["account_in"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(entries.account_id IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value);
      }
    }

    if (filter.containsKey("status_in")) {
      final value = filter["status_in"] as List<EntryStatus>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(entries.status IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value.map((v) => v.label).toList());
      }
    }

    if (filter.containsKey("category_in")) {
      final value = filter["category_in"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(entries.category_id IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value);
      }
    }

    if (filter.containsKey("category_ne")) {
      final value = filter["category_ne"] as String?;

      if (value != null && value.isNotEmpty) {
        where["query"].add("(entries.category_id != ?)");
        where["args"].add(value);
      }
    }

    if (filter.containsKey("label_in")) {
      final value = filter["label_in"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(entry_labels.label_id IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value);
      }
    }

    if (filter.containsKey("fund_in")) {
      final value = filter["fund_in"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(fund_transactions.fund_id IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value);
      }
    }

    if (filter.containsKey("controller_id_is")) {
      final value = filter["controller_id_is"] as String?;
      if (value != null) {
        where["query"].add("(entries.controller_id = ?)");
        where["args"].add(value);
      }
    }

    if (filter.containsKey("controller_type_is")) {
      final value = filter["controller_type_is"] as String?;
      if (value != null) {
        where["query"].add("(entries.controller_type = ?)");
        where["args"].add(value);
      }
    }

    where["sql"] = where["query"].join(" AND ");
    return where;
  }

  _saveAnnotations(Iterable<Entry> entries) async {
    final client = await getClient();
    final args = entries
        .where(
          (e) => e.annotations != null && e.annotations!.isNotEmpty,
        )
        .expand(
          (e) =>
              e.annotations!.entries.map((a) => [e.id, a.key, a.value]),
        );

    if (args.isEmpty) {
      return;
    }

    client.execute(
      "DELETE FROM entry_annotations WHERE entry_id IN (${entries.map((_) => "?").join(", ")})",
      entries.map((entry) => entry.id).toList(),
    );

    client.execute(
      "INSERT INTO entry_annotations (entry_id, name, value) VALUES ${args.map((_) => "(?, ?, ?)").join(", ")} ON CONFLICT (entry_id, name) DO UPDATE SET value = excluded.value",
      args.expand((a) => a).toList(),
    );
  }

  _saveLabels(Iterable<Entry> entries) async {
    final client = await getClient();
    final args = entries
        .where((e) => e.labelIds.isNotEmpty)
        .expand((e) => e.labelIds.map((labelId) => [e.id, labelId]));

    if (args.isEmpty) {
      return;
    }

    client.execute(
      "DELETE FROM entry_labels WHERE entry_id IN (${entries.map((_) => "?").join(", ")})",
      entries.map((entry) => entry.id).toList(),
    );

    client.execute(
      "INSERT INTO entry_labels (entry_id, label_id) VALUES ${args.map((_) => "(?, ?)").join(", ")} ON CONFLICT (entry_id, label_id) DO NOTHING",
      args.expand((a) => a).toList(),
    );
  }

  _include(String value) {
    return withArgs.contains(value);
  }
}
