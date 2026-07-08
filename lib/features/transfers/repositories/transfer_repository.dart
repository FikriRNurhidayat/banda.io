import 'package:bandha/common/repositories/repository.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/transfers/entities/transfer.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:sqlite3/sqlite3.dart';

class TransferRepository extends Repository {
  WithArgs withArgs;

  TransferRepository(super.db, {WithArgs? withArgs})
    : withArgs = withArgs ?? {};

  TransferRepository withVaults() {
    withArgs.add("vaults");
    return TransferRepository(db, withArgs: withArgs);
  }

  TransferRepository withEntries() {
    withArgs.add("entries");
    return TransferRepository(db, withArgs: withArgs);
  }

  save(Transfer transfer) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO transfers (id, note, debit_amount, credit_amount, fee_amount, debit_id, debit_vault_id, fee_id, credit_id, credit_vault_id, issued_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET note = excluded.note, debit_amount = excluded.debit_amount, credit_amount = excluded.credit_amount, fee_amount = excluded.fee_amount, debit_id = excluded.debit_id, debit_vault_id = excluded.debit_vault_id, fee_id = excluded.fee_id, credit_id = excluded.credit_id, credit_vault_id = excluded.credit_vault_id, issued_at = excluded.issued_at, updated_at = excluded.updated_at",
      [
        transfer.id,
        transfer.note,
        transfer.debitAmount,
        transfer.creditAmount,
        transfer.feeAmount,
        transfer.debitId,
        transfer.debitVaultId,
        transfer.feeId,
        transfer.creditId,
        transfer.creditVaultId,
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
    if (withArgs.contains("vaults")) {
      final vaultIds = rows
          .expand(
            (t) => [
              t["debit_vault_id"] as String,
              t["credit_vault_id"] as String,
            ],
          )
          .toList();
      final vaultRows = await getVaultByIds(vaultIds);

      rows = rows.map((t) {
        return {
          ...t,
          "debit_vault": vaultRows.firstWhere(
            (e) => e["id"] == t["debit_vault_id"],
          ),
          "credit_vault": vaultRows.firstWhere(
            (e) => e["id"] == t["credit_vault_id"],
          ),
        };
      }).toList();
    }

    if (withArgs.contains("entries")) {
      final entryIds = rows
          .expand(
            (t) => [t["debit_id"], t["fee_id"], t["credit_id"]],
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
          "exchange": !isNull(t["fee_id"])
              ? entryRows.firstWhere((e) => e["id"] == t["fee_id"])
              : null,
        };
      }).toList();
    }

    return rows.map((r) {
      return Transfer.fromRow(r)
          .withDebit(Entry.row(r["debit"]))
          .withDebitVault(Vault.row(r["debit_vault"]))
          .withFee(Entry.tryRow(r["exchange"]))
          .withCredit(Entry.row(r["credit"]))
          .withCreditVault(Vault.row(r["credit_vault"]));
    }).toList();
  }
}
