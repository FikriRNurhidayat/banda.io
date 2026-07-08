import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/common/entities/controlable.dart';
import 'package:bandha/common/entities/entity.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/common/types/controller.dart';

class Transfer extends Controlable {
  @override
  final String id;
  final String? note;
  final double debitAmount;
  final double creditAmount;
  final double? feeAmount;
  final String debitId;
  final String debitVaultId;
  final String? feeId;
  final String creditId;
  final String creditVaultId;
  final DateTime issuedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  late final Entry debit;
  late final Vault debitVault;
  late final Entry? fee;
  late final Vault creditVault;
  late final Entry credit;

  Transfer({
    required this.id,
    this.note,
    required this.debitAmount,
    required this.creditAmount,
    this.feeAmount,
    required this.debitId,
    required this.debitVaultId,
    this.feeId,
    required this.creditId,
    required this.creditVaultId,
    required this.issuedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Iterable<Entry> get credits {
    return [credit, fee].whereType<Entry>();
  }

  Iterable<Entry> get entries {
    return [debit, credit, fee].whereType<Entry>();
  }

  Iterable<String> get entryIds {
    return entries.map((entry) => entry.id);
  }

  Iterable<Vault> get vaults {
    return [debitVault, creditVault].whereType<Vault>();
  }

  Iterable<String> get vaultIds {
    return vaults.map((vault) => vault.id);
  }

  toMap() {
    return {
      "id": id,
      "note": note,
      "creditAmount": creditAmount,
      "debitAmount": debitAmount,
      "feeAmount": feeAmount,
      "debitId": debitId,
      "debitVaultId": debitVaultId,
      "creditId": creditId,
      "creditVaultId": creditVaultId,
      "issuedAt": issuedAt,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }

  static Transfer? tryRow(Map<dynamic, dynamic>? row) {
    if (row == null) return null;
    return Transfer.fromRow(row);
  }

  factory Transfer.fromRow(Map<dynamic, dynamic> row) {
    return Transfer(
      id: row["id"],
      note: row["note"],
      debitAmount: row["debit_amount"],
      creditAmount: row["credit_amount"],
      feeAmount: row["fee_amount"],
      debitId: row["debit_id"],
      debitVaultId: row["debit_vault_id"],
      feeId: row["fee_id"],
      creditId: row["credit_id"],
      creditVaultId: row["credit_vault_id"],
      issuedAt: DateTime.parse(row["issued_at"]),
      createdAt: DateTime.parse(row["created_at"]),
      updatedAt: DateTime.parse(row["updated_at"]),
    );
  }

  factory Transfer.create({
    String? note,
    required double debitAmount,
    required double creditAmount,
    double? feeAmount,
    required String debitId,
    required String debitVaultId,
    String? feeId,
    required String creditId,
    required String creditVaultId,
    required DateTime issuedAt,
  }) {
    return Transfer(
      id: Entity.getId(),
      note: note,
      debitAmount: debitAmount,
      creditAmount: creditAmount,
      feeAmount: feeAmount,
      debitId: debitId,
      debitVaultId: debitVaultId,
      feeId: feeId,
      creditId: creditId,
      creditVaultId: creditVaultId,
      issuedAt: issuedAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Transfer setFeeId(String? feeId) {
    return Transfer(
      id: id,
      note: note,
      debitAmount: debitAmount,
      creditAmount: creditAmount,
      feeAmount: feeAmount,
      debitId: debitId,
      debitVaultId: debitVaultId,
      feeId: feeId,
      creditId: creditId,
      creditVaultId: creditVaultId,
      issuedAt: issuedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Transfer withDebit(Entry? debit) {
    if (debit != null) this.debit = debit;
    return this;
  }

  Transfer withFee(Entry? fee) {
    this.fee = fee;
    return this;
  }

  Transfer withCredit(Entry? credit) {
    if (credit != null) this.credit = credit;
    return this;
  }

  Transfer withDebitVault(Vault? debitVault) {
    if (debitVault != null) this.debitVault = debitVault;
    return this;
  }

  Transfer withCreditVault(Vault? creditVault) {
    if (creditVault != null) {
      this.creditVault = creditVault;
    }
    return this;
  }

  Transfer copyWith({
    String? note,
    double? debitAmount,
    double? creditAmount,
    double? feeAmount,
    String? debitId,
    String? debitVaultId,
    String? feeId,
    String? creditId,
    String? creditVaultId,
    DateTime? issuedAt,
  }) {
    return Transfer(
      id: id,
      note: note ?? this.note,
      debitAmount: debitAmount ?? this.debitAmount,
      creditAmount: creditAmount ?? this.creditAmount,
      feeAmount: feeAmount ?? this.feeAmount,
      debitId: debitId ?? this.debitId,
      debitVaultId: debitVaultId ?? this.debitVaultId,
      feeId: feeId ?? this.feeId,
      creditId: creditId ?? this.creditId,
      creditVaultId: creditVaultId ?? this.creditVaultId,
      issuedAt: issuedAt ?? this.issuedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  get hasFee {
    return feeId != null;
  }

  @override
  Controller toController() {
    return Controller.transfer(id);
  }
}
