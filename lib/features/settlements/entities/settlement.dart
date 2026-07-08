import 'package:bandha/features/tags/entities/category.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/common/entities/controlable.dart';
import 'package:bandha/common/entities/entity.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/settlements/entities/settlement_payment.dart';
import 'package:bandha/features/tags/entities/party.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/common/types/controller.dart';

class Settlement extends Controlable {
  @override
  final String id;
  final SettlementStatus status;
  final double amount;
  final String? feeId;
  final double? feeAmount;
  final double remainder;
  final String categoryId;
  final String partyId;
  final String vaultId;
  final String entryId;
  final DateTime issuedAt;
  final DateTime? settledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  late final Party party;
  late final Category category;
  late final Entry entry;
  late final Entry? fee;
  late final Vault vault;
  late List<Label> labels;

  static double getFee(double fee) {
    return fee * -1;
  }

  static String getFeeNote(EntryType type) {
    return "Settlement fee";
  }

  static String entryNote(EntryType type, Party party) {
    final preposition = type.isIncome ? "for" : "from";
    return "Settlement $preposition ${party.name}";
  }

  static double entryAmount(EntryType type, {required double amount}) {
    return amount * (type.isIncome ? 1 : -1);
  }

  Settlement({
    required this.id,
    required this.status,
    required this.amount,
    this.feeAmount,
    required this.remainder,
    required this.partyId,
    required this.entryId,
    required this.categoryId,
    this.feeId,
    required this.vaultId,
    required this.issuedAt,
    this.settledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  get isIncome {
    return amount >= 0;
  }

  get isExpense {
    return amount < 0;
  }

  get entryType {
    return isIncome ? EntryType.income : EntryType.expense;
  }

  Iterable<Entry> get entries {
    return [entry, fee].whereType<Entry>();
  }

  Iterable<String> get entryIds {
    return entries.map((entry) => entry.id);
  }

  get labelIds {
    return labels.map((label) => label.id).toList();
  }

  get hasLabels {
    return labels.isNotEmpty;
  }

  Settlement withEntry(Entry? value) {
    if (value != null) entry = value;
    return this;
  }

  Settlement withFee(Entry? value) {
    fee = value;
    return this;
  }

  Settlement withVault(Vault? value) {
    if (value != null) vault = value;
    return this;
  }

  Settlement withParty(Party? value) {
    if (value != null) party = value;
    return this;
  }

  Settlement withCategory(Category? value) {
    if (value != null) category = value;
    return this;
  }

  Settlement withLabels(List<Label>? value) {
    if (value != null) labels = value;
    return this;
  }

  Settlement pay(double paymentAmount) {
    final newRemainder = remainder - paymentAmount;
    final isSettled = amount >= 0
        ? newRemainder <= 0
        : newRemainder >= 0;
    return copyWith(
      remainder: newRemainder,
      status: isSettled ? SettlementStatus.settled : status,
    );
  }

  revoke(double paymentAmount) {
    final newRemainder = remainder + paymentAmount;

    final isSettled = amount >= 0
        ? newRemainder <= 0
        : newRemainder >= 0;

    return copyWith(
      remainder: newRemainder,
      status: isSettled ? SettlementStatus.settled : status,
    );
  }

  Settlement applyPayment(SettlementPayment payment) {
    return pay(payment.amount);
  }

  Settlement revokePayment(SettlementPayment payment) {
    return revoke(payment.amount);
  }

  double get paid {
    return amount - remainder;
  }

  double get completion {
    return (paid / amount).abs();
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "status": status,
      "amount": amount,
      "fee": feeAmount,
      "partyId": partyId,
      "vaultId": vaultId,
      "entryId": entryId,
      "issuedAt": issuedAt,
      "settledAt": settledAt,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }

  Settlement copyWith({
    SettlementStatus? status,
    double? amount,
    double? feeAmount,
    double? remainder,
    String? categoryId,
    String? partyId,
    String? vaultId,
    String? entryId,
    String? feeId,
    DateTime? issuedAt,
    DateTime? settledAt,
  }) {
    return Settlement(
      id: id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      entryId: entryId ?? this.entryId,
      feeAmount: feeAmount ?? this.feeAmount,
      feeId: feeId ?? this.feeId,
      partyId: partyId ?? this.partyId,
      remainder: remainder ?? this.remainder,
      status: status ?? this.status,
      vaultId: vaultId ?? this.vaultId,
      issuedAt: issuedAt ?? this.issuedAt,
      settledAt: settledAt ?? this.settledAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  factory Settlement.create({
    required SettlementStatus status,
    required double amount,
    required double? feeAmount,
    double? remainder,
    required String categoryId,
    required String partyId,
    required String vaultId,
    required String entryId,
    String? feeId,
    required DateTime issuedAt,
    DateTime? settledAt,
  }) {
    return Settlement(
      id: Entity.getId(),
      status: status,
      amount: amount,
      feeAmount: feeAmount,
      remainder: remainder ?? amount,
      categoryId: categoryId,
      partyId: partyId,
      vaultId: vaultId,
      entryId: entryId,
      feeId: feeId,
      issuedAt: issuedAt,
      settledAt: settledAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Controller toController() {
    return Controller.settlement(id);
  }

  static Settlement? tryParse(Map<dynamic, dynamic>? row) {
    if (isNull(row)) return null;
    return Settlement.parse(row!);
  }

  factory Settlement.parse(Map<dynamic, dynamic> row) {
    return Settlement(
      id: row["id"],
      status: SettlementStatus.parse(row["status"]),
      amount: row["amount"],
      feeAmount: row["fee_amount"],
      remainder: row["remainder"],
      categoryId: row["category_id"],
      partyId: row["party_id"],
      vaultId: row["vault_id"],
      entryId: row["entry_id"],
      feeId: row["fee_id"],
      issuedAt: DateTime.parse(row["issued_at"]),
      settledAt: DateTime.tryParse(row["settled_at"] ?? ""),
      createdAt: DateTime.parse(row["created_at"]),
      updatedAt: DateTime.parse(row["updated_at"]),
    );
  }
}

enum SettlementStatus {
  overdue('Overdue'),
  settled('Settled'),
  active('Active');

  final String label;
  const SettlementStatus(this.label);

  static SettlementStatus parse(String value) {
    return values.firstWhere((e) => e.label == value);
  }

  bool get isSettled {
    return this == SettlementStatus.settled;
  }

  EntryStatus get entryStatus {
    switch (this) {
      case SettlementStatus.settled:
        return EntryStatus.done;
      case SettlementStatus.overdue:
      case SettlementStatus.active:
        return EntryStatus.pending;
    }
  }
}
