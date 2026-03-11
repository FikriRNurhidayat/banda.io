import 'package:banda/features/accounts/entities/account.dart';
import 'package:banda/common/entities/controlable.dart';
import 'package:banda/common/entities/entity.dart';
import 'package:banda/features/entries/entities/entry.dart';
import 'package:banda/common/types/controller.dart';

class Transfer extends Controlable {
  @override
  final String id;
  final String? note;
  final double amount;
  final double? fee;
  final String debitId;
  final String debitAccountId;
  final String? exchangeId;
  final String creditId;
  final String creditAccountId;
  final DateTime issuedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  late final Entry debit;
  late final Account debitAccount;
  late final Entry? exchange;
  late final Account creditAccount;
  late final Entry credit;

  Transfer({
    required this.id,
    this.note,
    required this.amount,
    this.fee,
    required this.debitId,
    required this.debitAccountId,
    this.exchangeId,
    required this.creditId,
    required this.creditAccountId,
    required this.issuedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Iterable<Entry> get credits {
    return [credit, exchange].whereType<Entry>();
  }

  Iterable<Entry> get entries {
    return [debit, credit, exchange].whereType<Entry>();
  }

  Iterable<String> get entryIds {
    return entries.map((entry) => entry.id);
  }

  Iterable<Account> get accounts {
    return [debitAccount, creditAccount].whereType<Account>();
  }

  Iterable<String> get accountIds {
    return accounts.map((account) => account.id);
  }

  toMap() {
    return {
      "id": id,
      "note": note,
      "amount": amount,
      "fee": fee,
      "debitId": debitId,
      "debitAccountId": debitAccountId,
      "creditId": creditId,
      "creditAccountId": creditAccountId,
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
      amount: row["amount"],
      fee: row["fee"],
      debitId: row["debit_id"],
      debitAccountId: row["debit_account_id"],
      exchangeId: row["exchange_id"],
      creditId: row["credit_id"],
      creditAccountId: row["credit_account_id"],
      issuedAt: DateTime.parse(row["issued_at"]),
      createdAt: DateTime.parse(row["created_at"]),
      updatedAt: DateTime.parse(row["updated_at"]),
    );
  }

  factory Transfer.create({
    String? note,
    required double amount,
    double? fee,
    required String debitId,
    required String debitAccountId,
    String? exchangeId,
    required String creditId,
    required String creditAccountId,
    required DateTime issuedAt,
  }) {
    return Transfer(
      id: Entity.getId(),
      note: note,
      amount: amount,
      fee: fee,
      debitId: debitId,
      debitAccountId: debitAccountId,
      exchangeId: exchangeId,
      creditId: creditId,
      creditAccountId: creditAccountId,
      issuedAt: issuedAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Transfer setExchangeId(String? exchangeId) {
    return Transfer(
      id: id,
      note: note,
      amount: amount,
      fee: fee,
      debitId: debitId,
      debitAccountId: debitAccountId,
      exchangeId: exchangeId,
      creditId: creditId,
      creditAccountId: creditAccountId,
      issuedAt: issuedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Transfer withDebit(Entry? debit) {
    if (debit != null) this.debit = debit;
    return this;
  }

  Transfer withExchange(Entry? exchange) {
    this.exchange = exchange;
    return this;
  }

  Transfer withCredit(Entry? credit) {
    if (credit != null) this.credit = credit;
    return this;
  }

  Transfer withDebitAccount(Account? debitAccount) {
    if (debitAccount != null) this.debitAccount = debitAccount;
    return this;
  }

  Transfer withCreditAccount(Account? creditAccount) {
    if (creditAccount != null) {
      this.creditAccount = creditAccount;
    }
    return this;
  }

  Transfer copyWith({
    String? note,
    double? amount,
    double? fee,
    String? debitId,
    String? debitAccountId,
    String? exchangeId,
    String? creditId,
    String? creditAccountId,
    DateTime? issuedAt,
  }) {
    return Transfer(
      id: id,
      note: note ?? this.note,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      debitId: debitId ?? this.debitId,
      debitAccountId: debitAccountId ?? this.debitAccountId,
      exchangeId: exchangeId ?? this.exchangeId,
      creditId: creditId ?? this.creditId,
      creditAccountId: creditAccountId ?? this.creditAccountId,
      issuedAt: issuedAt ?? this.issuedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  get hasExchange {
    return exchangeId != null;
  }

  @override
  Controller toController() {
    return Controller.transfer(id);
  }
}
