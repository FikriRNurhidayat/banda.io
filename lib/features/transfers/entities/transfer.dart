import 'package:bandha/features/journals/entities/journal.dart';
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
  final String debitJournalId;
  final String? feeId;
  final String creditId;
  final String creditJournalId;
  final DateTime issuedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  late final Entry debit;
  late final Journal debitJournal;
  late final Entry? fee;
  late final Journal creditJournal;
  late final Entry credit;

  Transfer({
    required this.id,
    this.note,
    required this.debitAmount,
    required this.creditAmount,
    this.feeAmount,
    required this.debitId,
    required this.debitJournalId,
    this.feeId,
    required this.creditId,
    required this.creditJournalId,
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

  Iterable<Journal> get journals {
    return [debitJournal, creditJournal].whereType<Journal>();
  }

  Iterable<String> get journalIds {
    return journals.map((journal) => journal.id);
  }

  toMap() {
    return {
      "id": id,
      "note": note,
      "creditAmount": creditAmount,
      "debitAmount": debitAmount,
      "feeAmount": feeAmount,
      "debitId": debitId,
      "debitJournalId": debitJournalId,
      "creditId": creditId,
      "creditJournalId": creditJournalId,
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
      debitJournalId: row["debit_journal_id"],
      feeId: row["fee_id"],
      creditId: row["credit_id"],
      creditJournalId: row["credit_journal_id"],
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
    required String debitJournalId,
    String? feeId,
    required String creditId,
    required String creditJournalId,
    required DateTime issuedAt,
  }) {
    return Transfer(
      id: Entity.getId(),
      note: note,
      debitAmount: debitAmount,
      creditAmount: creditAmount,
      feeAmount: feeAmount,
      debitId: debitId,
      debitJournalId: debitJournalId,
      feeId: feeId,
      creditId: creditId,
      creditJournalId: creditJournalId,
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
      debitJournalId: debitJournalId,
      feeId: feeId,
      creditId: creditId,
      creditJournalId: creditJournalId,
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

  Transfer withDebitJournal(Journal? debitJournal) {
    if (debitJournal != null) this.debitJournal = debitJournal;
    return this;
  }

  Transfer withCreditJournal(Journal? creditJournal) {
    if (creditJournal != null) {
      this.creditJournal = creditJournal;
    }
    return this;
  }

  Transfer copyWith({
    String? note,
    double? debitAmount,
    double? creditAmount,
    double? feeAmount,
    String? debitId,
    String? debitJournalId,
    String? feeId,
    String? creditId,
    String? creditJournalId,
    DateTime? issuedAt,
  }) {
    return Transfer(
      id: id,
      note: note ?? this.note,
      debitAmount: debitAmount ?? this.debitAmount,
      creditAmount: creditAmount ?? this.creditAmount,
      feeAmount: feeAmount ?? this.feeAmount,
      debitId: debitId ?? this.debitId,
      debitJournalId: debitJournalId ?? this.debitJournalId,
      feeId: feeId ?? this.feeId,
      creditId: creditId ?? this.creditId,
      creditJournalId: creditJournalId ?? this.creditJournalId,
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
