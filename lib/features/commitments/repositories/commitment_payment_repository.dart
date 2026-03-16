import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/features/tags/entities/category.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/commitments/entities/commitment.dart';
import 'package:bandha/features/commitments/entities/commitment_payment.dart';
import 'package:bandha/common/repositories/repository.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/common/types/pair.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:flutter/material.dart';

class CommitmentPaymentRepository extends Repository {
  WithArgs withArgs;

  CommitmentPaymentRepository(super.db, {WithArgs? withArgs})
    : withArgs = withArgs ?? {};

  CommitmentPaymentRepository withVault() {
    withArgs.add("vault");
    return this;
  }

  CommitmentPaymentRepository withEntries() {
    withArgs.add("entries");
    return this;
  }

  CommitmentPaymentRepository withCommitment() {
    withArgs.add("commitment");
    return this;
  }

  CommitmentPaymentRepository withCategory() {
    withArgs.add("category");
    return this;
  }

  save(CommitmentPayment entity) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO commitment_payments (commitment_id, entry_id, addition_id, amount, fee, issued_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET addition_id = excluded.addition_id, amount = excluded.amount, fee = excluded.fee, entry_id = excluded.entry_id, commitment_id = excluded.commitment_id, issued_at = excluded.issued_at, updated_at = excluded.updated_at",
      [
        entity.commitmentId,
        entity.entryId,
        entity.additionId,
        entity.amount,
        entity.fee,
        entity.issuedAt.toIso8601String(),
        entity.createdAt.toIso8601String(),
        entity.updatedAt.toIso8601String(),
      ],
    );
  }

  Future<List<CommitmentPayment>> search({Filter? filter}) async {
    var baseQuery = "SELECT commitment_payments.* FROM commitment_payments";

    final query = _defineQuery(baseQuery, filter);
    final sqlString =
        "${query.first} ORDER BY commitment_payments.created_at DESC";
    final sqlArgs = query.second;

    final client = await getClient();
    final commitmentRows = client.select(sqlString, sqlArgs);

    return await _entities(commitmentRows);
  }

  Future<List<CommitmentPayment>> getByCommitmentId(String commitmentId) {
    return search(
      filter: {
        "commitment_in": [commitmentId],
      },
    );
  }

  Future<CommitmentPayment> get(String commitmentId, String entryId) async {
    final client = await getClient();
    final rows = client.select(
      "SELECT * FROM commitment_payments WHERE commitment_id = ? AND entry_id = ?",
      [commitmentId, entryId],
    );
    return _entities(rows).then((entity) => entity.first);
  }

  delete(String commitmentId, String entryId) async {
    final client = await getClient();
    client.execute(
      "DELETE FROM commitment_payments WHERE commitment_id = ? AND entry_id = ?",
      [commitmentId, entryId],
    );
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

  _whereQuery(Filter? specification) {
    if (specification == null) return null;

    final Map<String, dynamic> where = {
      "args": <dynamic>[],
      "query": <String>[],
      "sql": null,
    };

    if (specification.containsKey("commitment_in")) {
      final value = specification["commitment_in"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(commitment_payments.commitment_id IN (${value.map((_) => "?").join(", ")}))",
        );
        where["args"].addAll(value);
      }
    }

    if (specification.containsKey("entry_in")) {
      final value = specification["entry_in"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(commitment_payments.entry_id IN (${value.map((_) => "?").join(", ")}))",
        );
        where["args"].addAll(value);
      }
    }

    if (specification.containsKey("created_between")) {
      final value = specification["created_between"] as DateTimeRange;
      where["query"].add("(commitment_payments.created_at BETWEEN ? AND ?)");
      where["args"].addAll([
        value.start.toIso8601String(),
        value.end.toIso8601String(),
      ]);
    }

    if (specification.containsKey("updated_between")) {
      final value = specification["updated_between"] as DateTimeRange;
      where["query"].add("(commitment_payments.updated_at BETWEEN ? AND ?)");
      where["args"].addAll([
        value.start.toIso8601String(),
        value.end.toIso8601String(),
      ]);
    }

    if (specification.containsKey("issued_between")) {
      final value = specification["issued_between"] as DateTimeRange;
      where["query"].add("(commitment_payments.issued_at BETWEEN ? AND ?)");
      where["args"].addAll([
        value.start.toIso8601String(),
        value.end.toIso8601String(),
      ]);
    }

    where["sql"] = where["query"].join(" AND ");
    return where;
  }

  Future<List<CommitmentPayment>> _entities(List<Map> rows) async {
    if (withArgs.contains("entries")) {
      final entryIds = rows
          .map(
            (row) => [
              row["entry_id"],
              row["addition_id"],
            ].whereType<String>(),
          )
          .expand((i) => i)
          .toList();
      final entryRows = await getEntryByIds(entryIds);
      rows = rows.map((row) {
        return {
          ...row,
          "entry": entryRows.firstWhere(
            (entryRow) => entryRow["id"] == row["entry_id"],
          ),
          "addition": !isNull(row["addition_id"])
              ? entryRows.firstWhere(
                  (entryRow) => entryRow["id"] == row["addition_id"],
                )
              : null,
        };
      }).toList();

      if (withArgs.contains("category")) {
        final categoryIds = rows
            .map((row) => row["entry"]["category_id"] as String)
            .toList();
        final categoryRows = await getCategoryByIds(categoryIds);

        rows = rows.map((row) {
          return {
            ...row,
            "category": categoryRows.firstWhere(
              (categoryRow) =>
                  categoryRow["id"] == row["entry"]["category_id"],
            ),
          };
        }).toList();
      }

      if (withArgs.contains("vault")) {
        final vaultIds = rows
            .map((row) => row["entry"]["vault_id"] as String)
            .toList();
        final vaultRows = await getVaultByIds(vaultIds);

        rows = rows.map((row) {
          return {
            ...row,
            "vault": vaultRows.firstWhere(
              (vaultRow) =>
                  vaultRow["id"] == row["entry"]["vault_id"],
            ),
          };
        }).toList();
      }
    }

    if (withArgs.contains("commitment")) {
      final commitmentIds = rows
          .map((row) => row["commitment_id"] as String)
          .toList();
      final commitmentRows = await getCommitmentByIds(commitmentIds);

      rows = rows.map((row) {
        return {
          ...row,
          "commitment": commitmentRows.firstWhere(
            (commitmentRow) => commitmentRow["id"] == row["commitment_id"],
          ),
        };
      }).toList();
    }

    return rows.map((row) {
      final commitment = Commitment.tryParse(row["commitment"]);
      final category = Category.tryRow(row["category"]);
      final vault = Vault.tryRow(row["vault"]);
      final addition = Entry.tryRow(
        row["addition"],
      )?.withCategory(category).withVault(vault);
      final entry = Entry.tryRow(
        row["entry"],
      )?.withCategory(category).withVault(vault);

      return CommitmentPayment.fromRow(
        row,
      ).withAddition(addition).withCommitment(commitment).withEntry(entry);
    }).toList();
  }
}
