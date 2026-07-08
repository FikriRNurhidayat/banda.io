import 'package:bandha/common/entities/entity.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/settlements/entities/settlement.dart';

class SettlementPayment extends Entity {
  final String settlementId;
  final String entryId;
  final String? additionId;
  final double amount;
  final double? fee;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime issuedAt;

  late final Entry? addition;
  late final Entry entry;
  late final Settlement settlement;

  SettlementPayment({
    required this.settlementId,
    required this.entryId,
    this.additionId,
    required this.amount,
    this.fee,
    required this.createdAt,
    required this.updatedAt,
    required this.issuedAt,
  });

  static double additionAmount(Settlement settlement, double? fee) {
    return (fee ?? 0) * -1;
  }

  static String additionNote(Settlement settlement) {
    if (settlement.isIncome) {
      return settlement.status.isSettled
          ? "Settlement settlement fee"
          : "Settlement payment fee";
    }

    return settlement.status.isSettled
        ? "Settlement settlement fee"
        : "Settlement payment fee";
  }

  static double entryAmount(Settlement settlement, double amount) {
    return amount * (settlement.isIncome ? -1 : 1);
  }

  static String entryNote(Settlement settlement) {
    if (settlement.isIncome) {
      return settlement.status.isSettled
          ? "Settlement settlement to ${settlement.party.name}"
          : "Settlement payment to ${settlement.party.name}";
    }

    return settlement.status.isSettled
        ? "Settlement settlement from ${settlement.party.name}"
        : "Settlement payment from ${settlement.party.name}";
  }

  factory SettlementPayment.create({
    required double amount,
    double? fee,
    required String settlementId,
    required String entryId,
    String? additionId,
    required DateTime issuedAt,
  }) {
    return SettlementPayment(
      settlementId: settlementId,
      amount: amount,
      fee: fee,
      entryId: entryId,
      additionId: additionId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      issuedAt: issuedAt,
    );
  }

  SettlementPayment withAddition(Entry? value) {
    addition = value;
    return this;
  }

  SettlementPayment withEntry(Entry? value) {
    if (value == null) return this;
    entry = value;
    return this;
  }

  SettlementPayment withSettlement(Settlement? value) {
    if (value == null) return this;
    settlement = value;
    return this;
  }

  String get vaultId {
    return entry.vaultId;
  }

  Vault get vault {
    return entry.vault;
  }

  Iterable<Entry> get entries {
    return [entry, addition].whereType<Entry>();
  }

  Iterable<String> get entryIds {
    return entries.map((entry) => entry.id);
  }

  bool get hasAddition {
    return addition != null;
  }

  SettlementPayment copyWith({
    double? amount,
    double? fee,
    DateTime? issuedAt,
  }) {
    return SettlementPayment(
      settlementId: settlementId,
      entryId: entryId,
      additionId: additionId,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      issuedAt: issuedAt ?? this.issuedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  factory SettlementPayment.fromRow(Map row) {
    return SettlementPayment(
      settlementId: row["settlement_id"],
      entryId: row["entry_id"],
      additionId: row["addition_id"],
      amount: row["amount"],
      fee: row["fee"],
      createdAt: DateTime.parse(row["created_at"]),
      updatedAt: DateTime.parse(row["updated_at"]),
      issuedAt: DateTime.parse(row["issued_at"]),
    );
  }
}
