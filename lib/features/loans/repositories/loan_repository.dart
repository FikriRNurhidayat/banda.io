import 'package:bandha/features/accounts/entities/account.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/loans/entities/loan.dart';
import 'package:bandha/features/tags/entities/party.dart';
import 'package:bandha/common/repositories/repository.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/common/types/pair.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:flutter/material.dart';

class LoanRepository extends Repository {
  WithArgs withArgs;

  LoanRepository(super.db, {WithArgs? withArgs})
    : withArgs = withArgs ?? {};

  LoanRepository withAccount() {
    withArgs.add("account");
    return this;
  }

  LoanRepository withEntries() {
    withArgs.add("entries");
    return this;
  }

  LoanRepository withParty() {
    withArgs.add("party");
    return this;
  }

  save(Loan loan) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO loans (id, kind, status, amount, fee, remainder, party_id, account_id, entry_id, addition_id, issued_at, settled_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET kind = excluded.kind, status = excluded.status, amount = excluded.amount, fee = excluded.fee, remainder = excluded.remainder, party_id = excluded.party_id, account_id = excluded.account_id, entry_id = excluded.entry_id, addition_id = excluded.addition_id, issued_at = excluded.issued_at, settled_at = excluded.settled_at, updated_at = excluded.updated_at",
      [
        loan.id,
        loan.type.label,
        loan.status.label,
        loan.amount,
        loan.fee,
        loan.remainder,
        loan.partyId,
        loan.accountId,
        loan.entryId,
        loan.additionId,
        loan.issuedAt.toIso8601String(),
        loan.settledAt?.toIso8601String(),
        loan.createdAt.toIso8601String(),
        loan.updatedAt.toIso8601String(),
      ],
    );
  }

  Future<Loan> sync(String id) async {
    final client = await getClient();
    final rows = client.select(
      "SELECT SUM(amount) as paid FROM loan_payments WHERE loan_id = ?",
      [id],
    );
    final paid = rows.first["paid"] ?? 0;

    client.execute(
      "UPDATE loans SET remainder = amount - ? WHERE id = ?",
      [paid, id],
    );

    return get(id);
  }

  Future<List<Loan>> search(Filter? specification) async {
    var baseQuery = "SELECT loans.* FROM loans";

    final query = _defineQuery(baseQuery, specification);
    final sqlString = "${query.first} ORDER BY loans.issued_at DESC";
    final sqlArgs = query.second;

    final client = await getClient();
    final loanRows = client.select(sqlString, sqlArgs);

    return await _entities(loanRows);
  }

  Future<Loan> get(String id) async {
    final client = await getClient();
    final rows = client.select("SELECT * FROM loans WHERE id = ?", [
      id,
    ]);
    return _entities(rows).then((loans) => loans.first);
  }

  delete(String id) async {
    final client = await getClient();
    client.execute("DELETE FROM loans WHERE id = ?", [id]);
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
      where["query"].add("(loans.issued_at BETWEEN ? AND ?)");
      where["args"].addAll([
        value.start.toIso8601String(),
        value.end.toIso8601String(),
      ]);
    }

    if (spec.containsKey("account_in")) {
      final value = spec["account_in"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(loans.account_id IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value);
      }
    }

    if (spec.containsKey("type_in")) {
      final value = spec["type_in"] as List<LoanType>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(loans.kind IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value.map((v) => v.label).toList());
      }
    }

    if (spec.containsKey("status_in")) {
      final value = spec["status_in"] as List<LoanStatus>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(loans.status IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value.map((v) => v.label).toList());
      }
    }

    if (spec.containsKey("party_in")) {
      final value = spec["party_in"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(loans.party_id IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value);
      }
    }

    if (spec.containsKey("party_nin")) {
      final value = spec["party_nin"] as List<String>;
      if (value.isNotEmpty) {
        where["query"].add(
          "(loans.party_id NOT IN (${value.map((_) => '?').join(', ')}))",
        );
        where["args"].addAll(value);
      }
    }

    where["sql"] = where["query"].join(" AND ");
    return where;
  }

  Future<List<Loan>> _entities(List<Map> rows) async {
    if (withArgs.contains("entries")) {
      final entryIds = rows
          .map(
            (row) => [
              row["entry_id"] as String,
              row["addition_id"] as String,
            ],
          )
          .expand((id) => id)
          .toList();
      final entryRows = await getAnnotatedEntriesByIds(entryIds);
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
    }

    if (withArgs.contains("account")) {
      final accountIds = rows
          .map((row) => row["account_id"] as String)
          .toList();
      final accountRows = await getAccountByIds(accountIds);
      rows = rows.map((row) {
        return {
          ...row,
          "account": accountRows.firstWhere(
            (accountRow) => accountRow["id"] == row["account_id"],
          ),
        };
      }).toList();
    }

    if (withArgs.contains("party")) {
      final partyIds = rows
          .map((row) => row["party_id"] as String)
          .toList();
      final partyRows = await getPartyByIds(partyIds);
      rows = rows.map((row) {
        return {
          ...row,
          "party": partyRows.firstWhere(
            (partyRow) => partyRow["id"] == row["party_id"],
          ),
        };
      }).toList();
    }

    return rows.map((row) {
      return Loan.parse(row)
          .withAddition(Entry.tryRow(row["addition"]))
          .withEntry(Entry.tryRow(row["entry"]))
          .withParty(Party.tryRow(row["party"]))
          .withAccount(Account.tryRow(row["account"]));
    }).toList();
  }
}
