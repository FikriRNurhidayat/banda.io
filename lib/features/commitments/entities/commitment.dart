import 'package:bandha/features/tags/entities/category.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/common/entities/controlable.dart';
import 'package:bandha/common/entities/entity.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/commitments/entities/commitment_payment.dart';
import 'package:bandha/features/tags/entities/party.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/common/types/controller.dart';

class Commitment extends Controlable {
  @override
  final String id;
  final CommitmentStatus status;
  final double amount;
  final double? fee;
  final double remainder;
  final String categoryId;
  final String partyId;
  final String vaultId;
  final String entryId;
  final String? additionId;
  final DateTime issuedAt;
  final DateTime? settledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  late final Party party;
  late final Category category;
  late final Entry entry;
  late final Entry? addition;
  late final Vault vault;

  static double additionAmount(double fee) {
    return fee * -1;
  }

  static String additionNote(EntryType type) {
    return "Commitment fee";
  }

  static String entryNote(EntryType type, Party party) {
    final preposition = type.isIncome ? "for" : "from";
    return "Commitment $preposition ${party.name}";
  }

  static double entryAmount(EntryType type, {required double amount}) {
    return amount * (type.isIncome ? 1 : -1);
  }

  Commitment({
    required this.id,
    required this.status,
    required this.amount,
    this.fee,
    required this.remainder,
    required this.partyId,
    required this.entryId,
    required this.categoryId,
    this.additionId,
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
    return [entry, addition].whereType<Entry>();
  }

  Iterable<String> get entryIds {
    return entries.map((entry) => entry.id);
  }

  Commitment withEntry(Entry? value) {
    if (value != null) entry = value;
    return this;
  }

  Commitment withAddition(Entry? value) {
    addition = value;
    return this;
  }

  Commitment withVault(Vault? value) {
    if (value != null) vault = value;
    return this;
  }

  Commitment withParty(Party? value) {
    if (value != null) party = value;
    return this;
  }

  Commitment withCategory(Category? value) {
    if (value != null) category = value;
    return this;
  }

  Commitment pay(double paymentAmount) {
    final newRemainder = remainder - paymentAmount;
    final isSettled = amount >= 0
        ? newRemainder <= 0
        : newRemainder >= 0;
    return copyWith(
      remainder: newRemainder,
      status: isSettled ? CommitmentStatus.settled : status,
    );
  }

  revoke(double paymentAmount) {
    final newRemainder = remainder + paymentAmount;

    final isSettled = amount >= 0
        ? newRemainder <= 0
        : newRemainder >= 0;

    return copyWith(
      remainder: newRemainder,
      status: isSettled ? CommitmentStatus.settled : status,
    );
  }

  Commitment applyPayment(CommitmentPayment payment) {
    return pay(payment.amount);
  }

  Commitment revokePayment(CommitmentPayment payment) {
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
      "fee": fee,
      "partyId": partyId,
      "vaultId": vaultId,
      "entryId": entryId,
      "issuedAt": issuedAt,
      "settledAt": settledAt,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }

  Commitment copyWith({
    CommitmentStatus? status,
    double? amount,
    double? fee,
    double? remainder,
    String? categoryId,
    String? partyId,
    String? vaultId,
    String? entryId,
    String? additionId,
    DateTime? issuedAt,
    DateTime? settledAt,
  }) {
    return Commitment(
      id: id,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      remainder: remainder ?? this.remainder,
      categoryId: categoryId ?? this.categoryId,
      partyId: partyId ?? this.partyId,
      vaultId: vaultId ?? this.vaultId,
      entryId: entryId ?? this.entryId,
      additionId: additionId ?? this.additionId,
      issuedAt: issuedAt ?? this.issuedAt,
      settledAt: settledAt ?? this.settledAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  factory Commitment.create({
    required CommitmentStatus status,
    required double amount,
    required double? fee,
    double? remainder,
    required String categoryId,
    required String partyId,
    required String vaultId,
    required String entryId,
    String? additionId,
    required DateTime issuedAt,
    DateTime? settledAt,
  }) {
    return Commitment(
      id: Entity.getId(),
      status: status,
      amount: amount,
      fee: fee,
      remainder: remainder ?? amount,
      categoryId: categoryId,
      partyId: partyId,
      vaultId: vaultId,
      entryId: entryId,
      additionId: additionId,
      issuedAt: issuedAt,
      settledAt: settledAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Controller toController() {
    return Controller.commitment(id);
  }

  static Commitment? tryParse(Map<dynamic, dynamic>? row) {
    if (isNull(row)) return null;
    return Commitment.parse(row!);
  }

  factory Commitment.parse(Map<dynamic, dynamic> row) {
    return Commitment(
      id: row["id"],
      status: CommitmentStatus.values.firstWhere(
        (e) => e.label == row["status"],
      ),
      amount: row["amount"],
      fee: row["fee"],
      remainder: row["remainder"],
      categoryId: row["category_id"],
      partyId: row["party_id"],
      vaultId: row["vault_id"],
      entryId: row["entry_id"],
      additionId: row["addition_id"],
      issuedAt: DateTime.parse(row["issued_at"]),
      settledAt: DateTime.tryParse(row["settled_at"] ?? ""),
      createdAt: DateTime.parse(row["created_at"]),
      updatedAt: DateTime.parse(row["updated_at"]),
    );
  }
}

enum CommitmentStatus {
  overdue('Overdue'),
  settled('Settled'),
  active('Active');

  final String label;
  const CommitmentStatus(this.label);

  bool get isSettled {
    return this == CommitmentStatus.settled;
  }

  EntryStatus get entryStatus {
    switch (this) {
      case CommitmentStatus.settled:
        return EntryStatus.done;
      case CommitmentStatus.overdue:
      case CommitmentStatus.active:
        return EntryStatus.pending;
    }
  }
}
