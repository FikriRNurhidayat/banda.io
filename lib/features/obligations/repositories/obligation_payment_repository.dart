import 'package:bandha/features/journals/entities/journal.dart';
import 'package:bandha/features/tags/entities/category.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/obligations/entities/obligation.dart';
import 'package:bandha/features/obligations/entities/obligation_payment.dart';
import 'package:bandha/common/repositories/repository.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/common/types/pair.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:flutter/material.dart';

class ObligationPaymentRepository extends Repository {
  WithArgs withArgs;

  ObligationPaymentRepository(super.db, {WithArgs? withArgs})
    : withArgs = withArgs ?? {};

  ObligationPaymentRepository withJournal() {
    withArgs.add("journal");
    return this;
  }

  ObligationPaymentRepository withEntries() {
    withArgs.add("entries");
    return this;
  }

  ObligationPaymentRepository withObligation() {
    withArgs.add("obligation");
    return this;
  }

  ObligationPaymentRepository withCategory() {
    withArgs.add("category");
    return this;
  }

  save(ObligationPayment entity) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO obligation_payments (obligation_id, entry_id, fee_id, amount, fee, issued_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET fee_id = excluded.fee_id, amount = excluded.amount, fee = excluded.fee, entry_id = excluded.entry_id, obligation_id = excluded.obligation_id, issued_at = excluded.issued_at, updated_at = excluded.updated_at",
      [
        entity.obligationId,
        entity.entryId,
        entity.feeId,
        entity.amount,
        entity.fee,
        entity.issuedAt.toIso8601String(),
        entity.createdAt.toIso8601String(),
        entity.updatedAt.toIso8601String(),
      ],
    );
  }

  Future<List<ObligationPayment>> search({Filter? filter}) async {
    var baseQuery =
        "SELECT obligation_payments.* FROM obligation_payments";

    final query = _defineQuery(baseQuery, filter);
    final sqlString =
        "${query.first} ORDER BY obligation_payments.created_at DESC";
    final sqlArgs = query.second;

    final client = await getClient();
    final obligationRows = client.select(sqlString, sqlArgs);

    return await _entities(obligationRows);
  }

  Future<List<ObligationPayment>> getByObligationId(
    String obligationId,
  ) {
    return search(
      filter: {
        "obligation_in": [obligationId],
      },
    );
  }

  Future<ObligationPayment> get(
    String obligationId,
    String entryId,
  ) async {
    final client = await getClient();
    final rows = client.select(
      "SELECT * FROM obligation_payments WHERE obligation_id = ? AND entry_id = ?",
      [obligationId, entryId],
    );
    return _entities(rows).then((entity) => entity.first);
  }

  delete(String obligationId, String entryId) async {
    final client = await getClient();
    client.execute(
      "DELETE FROM obligation_payments WHERE obligation_id = ? AND entry_id = ?",
      [obligationId, entryId],
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

    if (specification.containsKey("obligation_in")) {
      final value = specification["obligation_in"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(obligation_payments.obligation_id IN (${value.map((_) => "?").join(", ")}))",
        );
        where["args"].addAll(value);
      }
    }

    if (specification.containsKey("entry_in")) {
      final value = specification["entry_in"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(obligation_payments.entry_id IN (${value.map((_) => "?").join(", ")}))",
        );
        where["args"].addAll(value);
      }
    }

    if (specification.containsKey("created_between")) {
      final value = specification["created_between"] as DateTimeRange;
      where["query"].add(
        "(obligation_payments.created_at BETWEEN ? AND ?)",
      );
      where["args"].addAll([
        value.start.toIso8601String(),
        value.end.toIso8601String(),
      ]);
    }

    if (specification.containsKey("updated_between")) {
      final value = specification["updated_between"] as DateTimeRange;
      where["query"].add(
        "(obligation_payments.updated_at BETWEEN ? AND ?)",
      );
      where["args"].addAll([
        value.start.toIso8601String(),
        value.end.toIso8601String(),
      ]);
    }

    if (specification.containsKey("issued_between")) {
      final value = specification["issued_between"] as DateTimeRange;
      where["query"].add(
        "(obligation_payments.issued_at BETWEEN ? AND ?)",
      );
      where["args"].addAll([
        value.start.toIso8601String(),
        value.end.toIso8601String(),
      ]);
    }

    where["sql"] = where["query"].join(" AND ");
    return where;
  }

  Future<List<ObligationPayment>> _entities(List<Map> rows) async {
    if (withArgs.contains("entries")) {
      final entryIds = rows
          .map(
            (row) => [
              row["entry_id"],
              row["fee_id"],
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
          "fee": !isNull(row["fee_id"])
              ? entryRows.firstWhere(
                  (entryRow) => entryRow["id"] == row["fee_id"],
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

      if (withArgs.contains("journal")) {
        final journalIds = rows
            .map((row) => row["entry"]["journal_id"] as String)
            .toList();
        final journalRows = await getJournalByIds(journalIds);

        rows = rows.map((row) {
          return {
            ...row,
            "journal": journalRows.firstWhere(
              (journalRow) => journalRow["id"] == row["entry"]["journal_id"],
            ),
          };
        }).toList();
      }
    }

    if (withArgs.contains("obligation")) {
      final obligationIds = rows
          .map((row) => row["obligation_id"] as String)
          .toList();
      final obligationRows = await getObligationByIds(obligationIds);

      rows = rows.map((row) {
        return {
          ...row,
          "obligation": obligationRows.firstWhere(
            (obligationRow) =>
                obligationRow["id"] == row["obligation_id"],
          ),
        };
      }).toList();
    }

    return rows.map((row) {
      final obligation = Obligation.tryParse(row["obligation"]);
      final category = Category.tryRow(row["category"]);
      final journal = Journal.tryRow(row["journal"]);
      final fee = Entry.tryRow(
        row["fee"],
      )?.withCategory(category).withJournal(journal);
      final entry = Entry.tryRow(
        row["entry"],
      )?.withCategory(category).withJournal(journal);

      return ObligationPayment.fromRow(row)
          .withFee(fee)
          .withObligation(obligation)
          .withEntry(entry);
    }).toList();
  }
}
