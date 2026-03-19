import 'package:bandha/features/tags/entities/category.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/commitments/entities/commitment.dart';
import 'package:bandha/features/tags/entities/party.dart';
import 'package:bandha/common/repositories/repository.dart';
import 'package:bandha/common/types/pair.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:flutter/material.dart';

class CommitmentRepository extends Repository {
  WithArgs withArgs;

  CommitmentRepository(super.db, {WithArgs? withArgs})
    : withArgs = withArgs ?? {};

  CommitmentRepository withVault() {
    withArgs.add("vault");
    return this;
  }

  CommitmentRepository withLabels() {
    withArgs.add("labels");
    return this;
  }

  CommitmentRepository withEntries() {
    withArgs.add("entries");
    return this;
  }

  CommitmentRepository withCategory() {
    withArgs.add("category");
    return this;
  }

  CommitmentRepository withParty() {
    withArgs.add("party");
    return this;
  }

  save(Commitment commitment) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO commitments (id, status, amount, fee, remainder, category_id, party_id, vault_id, entry_id, addition_id, issued_at, settled_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET status = excluded.status, amount = excluded.amount, fee = excluded.fee, remainder = excluded.remainder, category_id = excluded.category_id, party_id = excluded.party_id, vault_id = excluded.vault_id, entry_id = excluded.entry_id, addition_id = excluded.addition_id, issued_at = excluded.issued_at, settled_at = excluded.settled_at, updated_at = excluded.updated_at",
      [
        commitment.id,
        commitment.status.label,
        commitment.amount,
        commitment.fee,
        commitment.remainder,
        commitment.categoryId,
        commitment.partyId,
        commitment.vaultId,
        commitment.entryId,
        commitment.additionId,
        commitment.issuedAt.toIso8601String(),
        commitment.settledAt?.toIso8601String(),
        commitment.createdAt.toIso8601String(),
        commitment.updatedAt.toIso8601String(),
      ],
    );
  }

  Future<Commitment> sync(String id) async {
    final client = await getClient();
    final rows = client.select(
      "SELECT SUM(amount) as paid FROM commitment_payments WHERE commitment_id = ?",
      [id],
    );
    final paid = rows.first["paid"] ?? 0;

    client.execute(
      "UPDATE commitments SET remainder = amount - ? WHERE id = ?",
      [paid, id],
    );

    return get(id);
  }

  Future<List<Commitment>> search(Filter? specification) async {
    var baseQuery = "SELECT commitments.* FROM commitments";

    final query = _defineQuery(baseQuery, specification);
    final sqlString =
        "${query.first} ORDER BY commitments.issued_at DESC";
    final sqlArgs = query.second;

    final client = await getClient();
    final commitmentRows = client.select(sqlString, sqlArgs);

    return await _entities(commitmentRows);
  }

  Future<Commitment> get(String id) async {
    final client = await getClient();
    final rows = client.select(
      "SELECT * FROM commitments WHERE id = ?",
      [id],
    );
    return _entities(rows).then((commitments) => commitments.first);
  }

  delete(String id) async {
    final client = await getClient();
    client.execute("DELETE FROM commitments WHERE id = ?", [id]);
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
      where["query"].add("(commitments.issued_at BETWEEN ? AND ?)");
      where["args"].addAll([
        value.start.toIso8601String(),
        value.end.toIso8601String(),
      ]);
    }

    if (spec.containsKey("vault_in")) {
      final value = spec["vault_in"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(commitments.vault_id IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value);
      }
    }

    if (spec.containsKey("status_in")) {
      final value = spec["status_in"] as List<CommitmentStatus>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(commitments.status IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value.map((v) => v.label).toList());
      }
    }

    if (spec.containsKey("category_in")) {
      final value = spec["category_in"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(commitments.category_id IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value);
      }
    }

    if (spec.containsKey("party_in")) {
      final value = spec["party_in"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(commitments.party_id IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value);
      }
    }

    if (spec.containsKey("party_nin")) {
      final value = spec["party_nin"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(commitments.party_id NOT IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value);
      }
    }

    where["sql"] = where["query"].join(" AND ");
    return where;
  }

  Future<List<Commitment>> _entities(List<Map> rows) async {
    if (withArgs.contains("entries")) {
      rows = await populateEntries(rows);
    }

    if (withArgs.contains("labels")) {
      rows = await populateLabels(rows);
    }

    if (withArgs.contains("vault")) {
      rows = await populateVault(rows);
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
      return Commitment.parse(row)
          .withAddition(Entry.tryRow(row["addition"]))
          .withEntry(Entry.tryRow(row["entry"]))
          .withCategory(Category.tryRow(row["category"]))
          .withLabels(Label.tryRows(row["labels"]))
          .withParty(Party.tryRow(row["party"]))
          .withVault(Vault.tryRow(row["vault"]));
    }).toList();
  }

  saveLabels(String commitmentId, Iterable<String> labelIds) {
    return setEntityLabels(
      entityId: commitmentId,
      labelIds: labelIds,
      junctionTable: "commitment_labels",
      junctionKey: "commitment_id",
    );
  }

  removeLabels(Commitment commitment) async {
    return resetEntityLabels(
      entityId: commitment.id,
      junctionTable: "commitment_labels",
      junctionKey: "commitment_id",
    );
  }

  populateLabels(List<Map> rows) {
    return super.populateEntityLabels(
      rows,
      "commitment_labels",
      "commitment_id",
    );
  }
}
