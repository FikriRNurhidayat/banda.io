import 'package:bandha/features/tags/entities/category.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/journals/entities/journal.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/obligations/entities/obligation.dart';
import 'package:bandha/features/tags/entities/party.dart';
import 'package:bandha/common/repositories/repository.dart';
import 'package:bandha/common/types/pair.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:flutter/material.dart';

class ObligationRepository extends Repository {
  WithArgs withArgs;

  ObligationRepository(super.db, {WithArgs? withArgs})
    : withArgs = withArgs ?? {};

  ObligationRepository withJournal() {
    withArgs.add("journal");
    return this;
  }

  ObligationRepository withLabels() {
    withArgs.add("labels");
    return this;
  }

  ObligationRepository withEntries() {
    withArgs.add("entries");
    return this;
  }

  ObligationRepository withCategory() {
    withArgs.add("category");
    return this;
  }

  ObligationRepository withParty() {
    withArgs.add("party");
    return this;
  }

  save(Obligation obligation) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO obligations (id, status, amount, fee_amount, remainder, category_id, party_id, journal_id, entry_id, fee_id, issued_at, settled_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET status = excluded.status, amount = excluded.amount, fee_amount = excluded.fee_amount, remainder = excluded.remainder, category_id = excluded.category_id, party_id = excluded.party_id, journal_id = excluded.journal_id, entry_id = excluded.entry_id, fee_id = excluded.fee_id, issued_at = excluded.issued_at, settled_at = excluded.settled_at, updated_at = excluded.updated_at",
      [
        obligation.id,
        obligation.status.label,
        obligation.amount,
        obligation.feeAmount,
        obligation.remainder,
        obligation.categoryId,
        obligation.partyId,
        obligation.journalId,
        obligation.entryId,
        obligation.feeId,
        obligation.issuedAt.toIso8601String(),
        obligation.settledAt?.toIso8601String(),
        obligation.createdAt.toIso8601String(),
        obligation.updatedAt.toIso8601String(),
      ],
    );
  }

  Future<Obligation> sync(String id) async {
    final client = await getClient();
    final rows = client.select(
      "SELECT SUM(amount) as paid FROM obligation_payments WHERE obligation_id = ?",
      [id],
    );
    final paid = rows.first["paid"] ?? 0;

    client.execute(
      "UPDATE obligations SET remainder = amount - ? WHERE id = ?",
      [paid, id],
    );

    return get(id);
  }

  Future<List<Obligation>> search(Filter? specification) async {
    var baseQuery = "SELECT obligations.* FROM obligations";

    final query = _defineQuery(baseQuery, specification);
    final sqlString =
        "${query.first} ORDER BY obligations.issued_at DESC";
    final sqlArgs = query.second;

    final client = await getClient();
    final obligationRows = client.select(sqlString, sqlArgs);

    return await _entities(obligationRows);
  }

  Future<Obligation> get(String id) async {
    final client = await getClient();
    final rows = client.select(
      "SELECT * FROM obligations WHERE id = ?",
      [id],
    );
    return _entities(rows).then((obligations) => obligations.first);
  }

  delete(String id) async {
    final client = await getClient();
    client.execute("DELETE FROM obligations WHERE id = ?", [id]);
  }

  _defineQuery(String baseQuery, Filter? spec) {
    var args = <dynamic>[];

    final where = _whereQuery(spec);

    if (where != null && where["sql"].isNotEmpty) {
      baseQuery = "$baseQuery WHERE ${where["sql"]}";
      args = where["args"];
    }

    return Pair(baseQuery, args);
  }

  _whereQuery(Filter? spec) {
    if (spec == null) return null;

    final Map<String, dynamic> where = {
      "args": <dynamic>[],
      "query": <String>[],
      "sql": null,
    };

    if (spec.containsKey("issued_between")) {
      final value = spec["issued_between"] as DateTimeRange;
      where["query"].add("(obligations.issued_at BETWEEN ? AND ?)");
      where["args"].addAll([
        value.start.toIso8601String(),
        value.end.toIso8601String(),
      ]);
    }

    if (spec.containsKey("journal_in")) {
      final value = spec["journal_in"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(obligations.journal_id IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value);
      }
    }

    if (spec.containsKey("status_in")) {
      final value = spec["status_in"] as List<ObligationStatus>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(obligations.status IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value.map((v) => v.label).toList());
      }
    }

    if (spec.containsKey("category_in")) {
      final value = spec["category_in"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(obligations.category_id IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value);
      }
    }

    if (spec.containsKey("party_in")) {
      final value = spec["party_in"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(obligations.party_id IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value);
      }
    }

    if (spec.containsKey("party_nin")) {
      final value = spec["party_nin"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(obligations.party_id NOT IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value);
      }
    }

    where["sql"] = where["query"].join(" AND ");
    return where;
  }

  Future<List<Obligation>> _entities(List<Map> rows) async {
    if (withArgs.contains("entries")) {
      rows = await populateEntries(rows);
    }

    if (withArgs.contains("labels")) {
      rows = await populateLabels(rows);
    }

    if (withArgs.contains("journal")) {
      rows = await populateJournal(rows);
    }

    if (withArgs.contains("category")) {
      rows = await populateCategory(rows);
    }

    if (withArgs.contains("party")) {
      rows = await populateParty(rows);
    }

    if (withArgs.contains("labels")) {
      rows = await populateLabels(rows);
    }

    return rows.map((row) {
      return Obligation.parse(row)
          .withFee(Entry.tryRow(row["fee"]))
          .withEntry(Entry.tryRow(row["entry"]))
          .withCategory(Category.tryRow(row["category"]))
          .withLabels(Label.tryRows(row["labels"]))
          .withParty(Party.tryRow(row["party"]))
          .withJournal(Journal.tryRow(row["journal"]));
    }).toList();
  }

  saveLabels(String obligationId, Iterable<String> labelIds) {
    return setEntityLabels(
      entityId: obligationId,
      labelIds: labelIds,
      junctionTable: "obligation_labels",
      junctionKey: "obligation_id",
    );
  }

  removeLabels(Obligation obligation) async {
    return resetEntityLabels(
      entityId: obligation.id,
      junctionTable: "obligation_labels",
      junctionKey: "obligation_id",
    );
  }

  populateLabels(List<Map> rows) {
    return super.populateEntityLabels(
      rows,
      "obligation_labels",
      "obligation_id",
    );
  }
}
