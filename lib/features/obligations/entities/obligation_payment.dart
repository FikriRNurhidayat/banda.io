import 'package:bandha/common/entities/entity.dart';
import 'package:bandha/features/journals/entities/journal.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/obligations/entities/obligation.dart';

class ObligationPayment extends Entity {
  final String obligationId;
  final String entryId;
  final String? feeId;
  final double amount;
  final double? feeAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime issuedAt;

  late final Entry? fee;
  late final Entry entry;
  late final Obligation obligation;

  ObligationPayment({
    required this.obligationId,
    required this.entryId,
    this.feeId,
    required this.amount,
    this.feeAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.issuedAt,
  });

  static String feeNote(Obligation obligation) {
    if (obligation.isIncome) {
      return obligation.status.isSettled
          ? "Obligation settlement fee"
          : "Obligation payment fee";
    }

    return obligation.status.isSettled
        ? "Obligation settlement fee"
        : "Obligation payment fee";
  }

  static double entryAmount(Obligation obligation, double amount) {
    return amount * (obligation.isIncome ? -1 : 1);
  }

  static String entryNote(Obligation obligation) {
    if (obligation.isIncome) {
      return obligation.status.isSettled
          ? "Obligation settlement to ${obligation.party.name}"
          : "Obligation payment to ${obligation.party.name}";
    }

    return obligation.status.isSettled
        ? "Obligation settlement from ${obligation.party.name}"
        : "Obligation payment from ${obligation.party.name}";
  }

  factory ObligationPayment.create({
    required double amount,
    double? feeAmount,
    required String obligationId,
    required String entryId,
    String? feeId,
    required DateTime issuedAt,
  }) {
    return ObligationPayment(
      obligationId: obligationId,
      amount: amount,
      feeAmount: feeAmount,
      entryId: entryId,
      feeId: feeId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      issuedAt: issuedAt,
    );
  }

  ObligationPayment withFee(Entry? value) {
    fee = value;
    return this;
  }

  ObligationPayment withEntry(Entry? value) {
    if (value == null) return this;
    entry = value;
    return this;
  }

  ObligationPayment withObligation(Obligation? value) {
    if (value == null) return this;
    obligation = value;
    return this;
  }

  String get journalId {
    return entry.journalId;
  }

  Journal get journal {
    return entry.journal;
  }

  Iterable<Entry> get entries {
    return [entry, fee].whereType<Entry>();
  }

  Iterable<String> get entryIds {
    return entries.map((entry) => entry.id);
  }

  bool get hasFee {
    return fee != null;
  }

  ObligationPayment copyWith({
    double? amount,
    double? feeAmount,
    DateTime? issuedAt,
  }) {
    return ObligationPayment(
      obligationId: obligationId,
      entryId: entryId,
      feeId: feeId,
      amount: amount ?? this.amount,
      feeAmount: feeAmount ?? this.feeAmount,
      issuedAt: issuedAt ?? this.issuedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  factory ObligationPayment.fromRow(Map row) {
    return ObligationPayment(
      obligationId: row["obligation_id"],
      entryId: row["entry_id"],
      feeId: row["fee_id"],
      amount: row["amount"],
      feeAmount: row["fee_amount"],
      createdAt: DateTime.parse(row["created_at"]),
      updatedAt: DateTime.parse(row["updated_at"]),
      issuedAt: DateTime.parse(row["issued_at"]),
    );
  }
}
