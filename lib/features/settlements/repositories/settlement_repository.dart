import 'package:bandha/features/tags/entities/category.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/settlements/entities/settlement.dart';
import 'package:bandha/features/tags/entities/party.dart';
import 'package:bandha/common/repositories/repository.dart';
import 'package:bandha/common/types/pair.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:flutter/material.dart';

class SettlementRepository extends Repository {
  WithArgs withArgs;

  SettlementRepository(super.db, {WithArgs? withArgs})
    : withArgs = withArgs ?? {};

  SettlementRepository withVault() {
    withArgs.add("vault");
    return this;
  }

  SettlementRepository withLabels() {
    withArgs.add("labels");
    return this;
  }

  SettlementRepository withEntries() {
    withArgs.add("entries");
    return this;
  }

  SettlementRepository withCategory() {
    withArgs.add("category");
    return this;
  }

  SettlementRepository withParty() {
    withArgs.add("party");
    return this;
  }

  save(Settlement settlement) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO settlements (id, status, amount, fee_amount, remainder, category_id, party_id, vault_id, entry_id, fee_id, issued_at, settled_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET status = excluded.status, amount = excluded.amount, fee_amount = excluded.fee_amount, remainder = excluded.remainder, category_id = excluded.category_id, party_id = excluded.party_id, vault_id = excluded.vault_id, entry_id = excluded.entry_id, fee_id = excluded.fee_id, issued_at = excluded.issued_at, settled_at = excluded.settled_at, updated_at = excluded.updated_at",
      [
        settlement.id,
        settlement.status.label,
        settlement.amount,
        settlement.feeAmount,
        settlement.remainder,
        settlement.categoryId,
        settlement.partyId,
        settlement.vaultId,
        settlement.entryId,
        settlement.feeId,
        settlement.issuedAt.toIso8601String(),
        settlement.settledAt?.toIso8601String(),
        settlement.createdAt.toIso8601String(),
        settlement.updatedAt.toIso8601String(),
      ],
    );
  }

  Future<Settlement> sync(String id) async {
    final client = await getClient();
    final rows = client.select(
      "SELECT SUM(amount) as paid FROM settlement_payments WHERE settlement_id = ?",
      [id],
    );
    final paid = rows.first["paid"] ?? 0;

    client.execute(
      "UPDATE settlements SET remainder = amount - ? WHERE id = ?",
      [paid, id],
    );

    return get(id);
  }

  Future<List<Settlement>> search(Filter? specification) async {
    var baseQuery = "SELECT settlements.* FROM settlements";

    final query = _defineQuery(baseQuery, specification);
    final sqlString =
        "${query.first} ORDER BY settlements.issued_at DESC";
    final sqlArgs = query.second;

    final client = await getClient();
    final settlementRows = client.select(sqlString, sqlArgs);

    return await _entities(settlementRows);
  }

  Future<Settlement> get(String id) async {
    final client = await getClient();
    final rows = client.select(
      "SELECT * FROM settlements WHERE id = ?",
      [id],
    );
    return _entities(rows).then((settlements) => settlements.first);
  }

  delete(String id) async {
    final client = await getClient();
    client.execute("DELETE FROM settlements WHERE id = ?", [id]);
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
      where["query"].add("(settlements.issued_at BETWEEN ? AND ?)");
      where["args"].addAll([
        value.start.toIso8601String(),
        value.end.toIso8601String(),
      ]);
    }

    if (spec.containsKey("vault_in")) {
      final value = spec["vault_in"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(settlements.vault_id IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value);
      }
    }

    if (spec.containsKey("status_in")) {
      final value = spec["status_in"] as List<SettlementStatus>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(settlements.status IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value.map((v) => v.label).toList());
      }
    }

    if (spec.containsKey("category_in")) {
      final value = spec["category_in"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(settlements.category_id IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value);
      }
    }

    if (spec.containsKey("party_in")) {
      final value = spec["party_in"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(settlements.party_id IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value);
      }
    }

    if (spec.containsKey("party_nin")) {
      final value = spec["party_nin"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(settlements.party_id NOT IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value);
      }
    }

    where["sql"] = where["query"].join(" AND ");
    return where;
  }

  Future<List<Settlement>> _entities(List<Map> rows) async {
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
      return Settlement.parse(row)
          .withFee(Entry.tryRow(row["fee"]))
          .withEntry(Entry.tryRow(row["entry"]))
          .withCategory(Category.tryRow(row["category"]))
          .withLabels(Label.tryRows(row["labels"]))
          .withParty(Party.tryRow(row["party"]))
          .withVault(Vault.tryRow(row["vault"]));
    }).toList();
  }

  saveLabels(String settlementId, Iterable<String> labelIds) {
    return setEntityLabels(
      entityId: settlementId,
      labelIds: labelIds,
      junctionTable: "settlement_labels",
      junctionKey: "settlement_id",
    );
  }

  removeLabels(Settlement settlement) async {
    return resetEntityLabels(
      entityId: settlement.id,
      junctionTable: "settlement_labels",
      junctionKey: "settlement_id",
    );
  }

  populateLabels(List<Map> rows) {
    return super.populateEntityLabels(
      rows,
      "settlement_labels",
      "settlement_id",
    );
  }
}
