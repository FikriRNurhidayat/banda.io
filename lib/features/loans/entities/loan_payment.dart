import 'package:banda/common/entities/entity.dart';
import 'package:banda/features/accounts/entities/account.dart';
import 'package:banda/features/entries/entities/entry.dart';
import 'package:banda/features/loans/entities/loan.dart';

class LoanPayment extends Entity {
  final String loanId;
  final String entryId;
  final String? additionId;
  final double amount;
  final double? fee;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime issuedAt;

  late final Entry? addition;
  late final Entry entry;
  late final Loan loan;

  LoanPayment({
    required this.loanId,
    required this.entryId,
    this.additionId,
    required this.amount,
    this.fee,
    required this.createdAt,
    required this.updatedAt,
    required this.issuedAt,
  });

  static double additionAmount(Loan loan, double? fee) {
    return (fee ?? 0) * -1;
  }

  static String additionNote(Loan loan) {
    if (loan.type.isDebt()) {
      return loan.status.isSettled
          ? "Loan settlement fee"
          : "Loan payment fee";
    }

    return loan.status.isSettled
        ? "Loan settlement fee"
        : "Loan payment fee";
  }

  static double entryAmount(Loan loan, double amount) {
    return amount * (loan.type.isDebt() ? -1 : 1);
  }

  static String entryNote(Loan loan) {
    if (loan.type.isDebt()) {
      return loan.status.isSettled
          ? "Loan settlement to ${loan.party.name}"
          : "Loan payment to ${loan.party.name}";
    }

    return loan.status.isSettled
        ? "Loan settlement from ${loan.party.name}"
        : "Loan payment from ${loan.party.name}";
  }

  factory LoanPayment.create({
    required double amount,
    double? fee,
    required String loanId,
    required String entryId,
    String? additionId,
    required DateTime issuedAt,
  }) {
    return LoanPayment(
      loanId: loanId,
      amount: amount,
      fee: fee,
      entryId: entryId,
      additionId: additionId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      issuedAt: issuedAt,
    );
  }

  LoanPayment withAddition(Entry? value) {
    addition = value;
    return this;
  }

  LoanPayment withEntry(Entry? value) {
    if (value == null) return this;
    entry = value;
    return this;
  }

  LoanPayment withLoan(Loan? value) {
    if (value == null) return this;
    loan = value;
    return this;
  }

  String get accountId {
    return entry.accountId;
  }

  Account get account {
    return entry.account;
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

  LoanPayment copyWith({
    double? amount,
    double? fee,
    DateTime? issuedAt,
  }) {
    return LoanPayment(
      loanId: loanId,
      entryId: entryId,
      additionId: additionId,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      issuedAt: issuedAt ?? this.issuedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  factory LoanPayment.fromRow(Map row) {
    return LoanPayment(
      loanId: row["loan_id"],
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
