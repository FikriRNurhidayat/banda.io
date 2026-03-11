import 'package:banda/features/accounts/entities/account.dart';
import 'package:banda/common/entities/controlable.dart';
import 'package:banda/common/entities/entity.dart';
import 'package:banda/features/entries/entities/entry.dart';
import 'package:banda/features/loans/entities/loan_payment.dart';
import 'package:banda/features/tags/entities/party.dart';
import 'package:banda/common/helpers/type_helper.dart';
import 'package:banda/common/types/controller.dart';

class Loan extends Controlable {
  @override
  final String id;
  final LoanType type;
  final LoanStatus status;
  final double amount;
  final double? fee;
  final double remainder;
  final String partyId;
  final String accountId;
  final String entryId;
  final String? additionId;
  final DateTime issuedAt;
  final DateTime? settledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  late final Party party;
  late final Entry entry;
  late final Entry? addition;
  late final Account account;

  static double additionAmount(double fee) {
    return fee * -1;
  }

  static String additionNote(LoanType type) {
    return "${type.label} fee";
  }

  static String entryNote(LoanType type, Party party) {
    return "${type.label} from ${party.name}";
  }

  static double entryAmount(
    LoanType type, {
    required double amount,
    required double? fee,
  }) {
    return amount * (type.isDebt() ? 1 : -1);
  }

  Loan({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    this.fee,
    required this.remainder,
    required this.partyId,
    required this.entryId,
    this.additionId,
    required this.accountId,
    required this.issuedAt,
    this.settledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Iterable<Entry> get entries {
    return [entry, addition].whereType<Entry>();
  }

  Iterable<String> get entryIds {
    return entries.map((entry) => entry.id);
  }

  Loan withEntry(Entry? value) {
    if (value != null) entry = value;
    return this;
  }

  Loan withAddition(Entry? value) {
    if (value != null) addition = value;
    return this;
  }

  Loan withAccount(Account? value) {
    if (value != null) account = value;
    return this;
  }

  Loan withParty(Party? value) {
    if (value != null) party = value;
    return this;
  }

  Loan pay(double paymentAmount) {
    final newRemainder = remainder - paymentAmount;
    return copyWith(
      remainder: newRemainder,
      status: newRemainder <= 0 ? LoanStatus.settled : status,
    );
  }

  revoke(double paymentAmount) {
    final newRemainder = remainder + paymentAmount;
    return copyWith(
      remainder: newRemainder,
      status: newRemainder <= 0 ? LoanStatus.settled : status,
    );
  }

  Loan applyPayment(LoanPayment payment) {
    return pay(payment.amount);
  }

  Loan revokePayment(LoanPayment payment) {
    return revoke(payment.amount);
  }

  double get paid {
    return amount - remainder;
  }

  double get completion {
    return (paid / amount);
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "type": type,
      "status": status,
      "amount": amount,
      "fee": fee,
      "partyId": partyId,
      "accountId": accountId,
      "entryId": entryId,
      "issuedAt": issuedAt,
      "settledAt": settledAt,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }

  Loan copyWith({
    LoanType? type,
    LoanStatus? status,
    double? amount,
    double? fee,
    double? remainder,
    String? partyId,
    String? accountId,
    String? entryId,
    String? additionId,
    DateTime? issuedAt,
    DateTime? settledAt,
  }) {
    return Loan(
      id: id,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      remainder: remainder ?? this.remainder,
      partyId: partyId ?? this.partyId,
      accountId: accountId ?? this.accountId,
      entryId: entryId ?? this.entryId,
      additionId: additionId ?? this.additionId,
      issuedAt: issuedAt ?? this.issuedAt,
      settledAt: settledAt ?? this.settledAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  factory Loan.create({
    required LoanType type,
    required LoanStatus status,
    required double amount,
    required double? fee,
    double? remainder,
    required String partyId,
    required String accountId,
    required String entryId,
    String? additionId,
    required DateTime issuedAt,
    DateTime? settledAt,
  }) {
    return Loan(
      id: Entity.getId(),
      type: type,
      status: status,
      amount: amount,
      fee: fee,
      remainder: remainder ?? amount,
      partyId: partyId,
      accountId: accountId,
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
    return Controller.loan(id);
  }

  static Loan? tryParse(Map<dynamic, dynamic>? row) {
    if (isNull(row)) return null;
    return Loan.parse(row!);
  }

  factory Loan.parse(Map<dynamic, dynamic> row) {
    return Loan(
      id: row["id"],
      type: LoanType.values.firstWhere((e) => e.label == row["kind"]),
      status: LoanStatus.values.firstWhere(
        (e) => e.label == row["status"],
      ),
      amount: row["amount"],
      fee: row["fee"],
      remainder: row["remainder"],
      partyId: row["party_id"],
      accountId: row["account_id"],
      entryId: row["entry_id"],
      additionId: row["addition_id"],
      issuedAt: DateTime.parse(row["issued_at"]),
      settledAt: DateTime.tryParse(row["settled_at"] ?? ""),
      createdAt: DateTime.parse(row["created_at"]),
      updatedAt: DateTime.parse(row["updated_at"]),
    );
  }
}

enum LoanType {
  debt('Debt'),
  receiveable('Receivable');

  bool isDebt() {
    return this == LoanType.debt;
  }

  bool isReceiveable() {
    return this == LoanType.receiveable;
  }

  final String label;
  const LoanType(this.label);
}

enum LoanStatus {
  overdue('Overdue'),
  settled('Settled'),
  active('Active');

  final String label;
  const LoanStatus(this.label);

  bool get isSettled {
    return this == LoanStatus.settled;
  }

  EntryStatus get entryStatus {
    switch (this) {
      case LoanStatus.settled:
        return EntryStatus.done;
      case LoanStatus.overdue:
      case LoanStatus.active:
        return EntryStatus.pending;
    }
  }
}
