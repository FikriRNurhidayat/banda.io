import 'package:bandha/features/tags/entities/category.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/journals/entities/journal.dart';
import 'package:bandha/common/entities/controlable.dart';
import 'package:bandha/common/entities/entity.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/obligations/entities/obligation_payment.dart';
import 'package:bandha/features/tags/entities/party.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/common/types/controller.dart';

class Obligation extends Controlable {
  @override
  final String id;
  final ObligationStatus status;
  final double amount;
  final String? feeId;
  final double? feeAmount;
  final double remainder;
  final String categoryId;
  final String partyId;
  final String journalId;
  final String entryId;
  final DateTime issuedAt;
  final DateTime? settledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  late final Party party;
  late final Category category;
  late final Entry entry;
  late final Entry? fee;
  late final Journal journal;
  late List<Label> labels;

  static double getFee(double fee) {
    return fee * -1;
  }

  static String getFeeNote(EntryType type) {
    return "Obligation fee";
  }

  static String entryNote(EntryType type, Party party) {
    final preposition = type.isIncome ? "for" : "from";
    return "Obligation $preposition ${party.name}";
  }

  static double entryAmount(EntryType type, {required double amount}) {
    return amount * (type.isIncome ? 1 : -1);
  }

  Obligation({
    required this.id,
    required this.status,
    required this.amount,
    this.feeAmount,
    required this.remainder,
    required this.partyId,
    required this.entryId,
    required this.categoryId,
    this.feeId,
    required this.journalId,
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

  Obligation withEntry(Entry? value) {
    if (value != null) entry = value;
    return this;
  }

  Obligation withFee(Entry? value) {
    fee = value;
    return this;
  }

  Obligation withJournal(Journal? value) {
    if (value != null) journal = value;
    return this;
  }

  Obligation withParty(Party? value) {
    if (value != null) party = value;
    return this;
  }

  Obligation withCategory(Category? value) {
    if (value != null) category = value;
    return this;
  }

  Obligation withLabels(List<Label>? value) {
    if (value != null) labels = value;
    return this;
  }

  Obligation pay(double paymentAmount) {
    final newRemainder = remainder - paymentAmount;
    final isSettled = amount >= 0
        ? newRemainder <= 0
        : newRemainder >= 0;
    return copyWith(
      remainder: newRemainder,
      status: isSettled ? ObligationStatus.settled : status,
    );
  }

  revoke(double paymentAmount) {
    final newRemainder = remainder + paymentAmount;

    final isSettled = amount >= 0
        ? newRemainder <= 0
        : newRemainder >= 0;

    return copyWith(
      remainder: newRemainder,
      status: isSettled ? ObligationStatus.settled : status,
    );
  }

  Obligation applyPayment(ObligationPayment payment) {
    return pay(payment.amount);
  }

  Obligation revokePayment(ObligationPayment payment) {
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
      "journalId": journalId,
      "entryId": entryId,
      "issuedAt": issuedAt,
      "settledAt": settledAt,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }

  Obligation copyWith({
    ObligationStatus? status,
    double? amount,
    double? feeAmount,
    double? remainder,
    String? categoryId,
    String? partyId,
    String? journalId,
    String? entryId,
    String? feeId,
    DateTime? issuedAt,
    DateTime? settledAt,
  }) {
    return Obligation(
      id: id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      entryId: entryId ?? this.entryId,
      feeAmount: feeAmount ?? this.feeAmount,
      feeId: feeId ?? this.feeId,
      partyId: partyId ?? this.partyId,
      remainder: remainder ?? this.remainder,
      status: status ?? this.status,
      journalId: journalId ?? this.journalId,
      issuedAt: issuedAt ?? this.issuedAt,
      settledAt: settledAt ?? this.settledAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  factory Obligation.create({
    required ObligationStatus status,
    required double amount,
    required double? feeAmount,
    double? remainder,
    required String categoryId,
    required String partyId,
    required String journalId,
    required String entryId,
    String? feeId,
    required DateTime issuedAt,
    DateTime? settledAt,
  }) {
    return Obligation(
      id: Entity.getId(),
      status: status,
      amount: amount,
      feeAmount: feeAmount,
      remainder: remainder ?? amount,
      categoryId: categoryId,
      partyId: partyId,
      journalId: journalId,
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
    return Controller.obligation(id);
  }

  static Obligation? tryParse(Map<dynamic, dynamic>? row) {
    if (isNull(row)) return null;
    return Obligation.parse(row!);
  }

  factory Obligation.parse(Map<dynamic, dynamic> row) {
    return Obligation(
      id: row["id"],
      status: ObligationStatus.parse(row["status"]),
      amount: row["amount"],
      feeAmount: row["fee_amount"],
      remainder: row["remainder"],
      categoryId: row["category_id"],
      partyId: row["party_id"],
      journalId: row["journal_id"],
      entryId: row["entry_id"],
      feeId: row["fee_id"],
      issuedAt: DateTime.parse(row["issued_at"]),
      settledAt: DateTime.tryParse(row["settled_at"] ?? ""),
      createdAt: DateTime.parse(row["created_at"]),
      updatedAt: DateTime.parse(row["updated_at"]),
    );
  }
}

enum ObligationStatus {
  overdue('Overdue'),
  settled('Settled'),
  active('Active');

  final String label;
  const ObligationStatus(this.label);

  static ObligationStatus parse(String value) {
    return values.firstWhere((e) => e.label == value);
  }

  bool get isSettled {
    return this == ObligationStatus.settled;
  }

  EntryStatus get entryStatus {
    switch (this) {
      case ObligationStatus.settled:
        return EntryStatus.done;
      case ObligationStatus.overdue:
      case ObligationStatus.active:
        return EntryStatus.pending;
    }
  }
}
