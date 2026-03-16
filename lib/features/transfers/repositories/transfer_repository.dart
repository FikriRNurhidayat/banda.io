import 'package:bandha/common/repositories/repository.dart';
import 'package:bandha/features/accounts/entities/account.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/transfers/entities/transfer.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:sqlite3/sqlite3.dart';

class TransferRepository extends Repository {
  WithArgs withArgs;

  TransferRepository(super.db, {WithArgs? withArgs})
    : withArgs = withArgs ?? {};

  TransferRepository withAccounts() {
    withArgs.add("accounts");
    return TransferRepository(db, withArgs: withArgs);
  }

  TransferRepository withEntries() {
    withArgs.add("entries");
    return TransferRepository(db, withArgs: withArgs);
  }

  save(Transfer transfer) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO transfers (id, note, amount, fee, debit_id, debit_account_id, exchange_id, credit_id, credit_account_id, issued_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET note = excluded.note, amount = excluded.amount, fee = excluded.fee, debit_id = excluded.debit_id, debit_account_id = excluded.debit_account_id, exchange_id = excluded.exchange_id, credit_id = excluded.credit_id, credit_account_id = excluded.credit_account_id, issued_at = excluded.issued_at, updated_at = excluded.updated_at",
      [
        transfer.id,
        transfer.note,
        transfer.amount,
        transfer.fee,
        transfer.debitId,
        transfer.debitAccountId,
        transfer.exchangeId,
        transfer.creditId,
        transfer.creditAccountId,
        transfer.issuedAt.toIso8601String(),
        transfer.createdAt.toIso8601String(),
        transfer.updatedAt.toIso8601String(),
      ],
    );
  }

  Future<Transfer> get(String id) async {
    final client = await getClient();
    final ResultSet rows = client.select(
      "SELECT * FROM transfers WHERE transfers.id = ?",
      [id],
    );
    return entities(rows).then((rows) => rows.first);
  }

  Future<List<Transfer>> search() async {
    final client = await getClient();
    final ResultSet rows = client.select("SELECT * FROM transfers");
    return entities(rows).then((rows) => rows.toList());
  }

  delete(String id) async {
    final client = await getClient();
    client.execute("DELETE FROM transfers WHERE id = ?", [id]);
  }

  Future<List<Transfer>> entities(List<Map> rows) async {
    if (withArgs.contains("accounts")) {
      final accountIds = rows
          .expand(
            (t) => [
              t["debit_account_id"] as String,
              t["credit_account_id"] as String,
            ],
          )
          .toList();
      final accountRows = await getAccountByIds(accountIds);

      rows = rows.map((t) {
        return {
          ...t,
          "debit_account": accountRows.firstWhere(
            (e) => e["id"] == t["debit_account_id"],
          ),
          "credit_account": accountRows.firstWhere(
            (e) => e["id"] == t["credit_account_id"],
          ),
        };
      }).toList();
    }

    if (withArgs.contains("entries")) {
      final entryIds = rows
          .expand(
            (t) => [t["debit_id"], t["exchange_id"], t["credit_id"]],
          )
          .whereType<String>()
          .toList();
      var entryRows = await getAnnotatedEntriesByIds(entryIds);

      rows = rows.map((t) {
        return {
          ...t,
          "debit": entryRows.firstWhere(
            (e) => e["id"] == t["debit_id"],
          ),
          "credit": entryRows.firstWhere(
            (e) => e["id"] == t["credit_id"],
          ),
          "exchange": !isNull(t["exchange_id"])
              ? entryRows.firstWhere((e) => e["id"] == t["exchange_id"])
              : null,
        };
      }).toList();
    }

    return rows.map((r) {
      return Transfer.fromRow(r)
          .withDebit(Entry.row(r["debit"]))
          .withDebitAccount(Account.row(r["debit_account"]))
          .withExchange(Entry.tryRow(r["exchange"]))
          .withCredit(Entry.row(r["credit"]))
          .withCreditAccount(Account.row(r["credit_account"]));
    }).toList();
  }
}
