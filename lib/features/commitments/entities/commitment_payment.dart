import 'package:bandha/common/entities/entity.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/commitments/entities/commitment.dart';

class CommitmentPayment extends Entity {
  final String commitmentId;
  final String entryId;
  final String? additionId;
  final double amount;
  final double? fee;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime issuedAt;

  late final Entry? addition;
  late final Entry entry;
  late final Commitment commitment;

  CommitmentPayment({
    required this.commitmentId,
    required this.entryId,
    this.additionId,
    required this.amount,
    this.fee,
    required this.createdAt,
    required this.updatedAt,
    required this.issuedAt,
  });

  static double additionAmount(Commitment commitment, double? fee) {
    return (fee ?? 0) * -1;
  }

  static String additionNote(Commitment commitment) {
    if (commitment.isIncome) {
      return commitment.status.isSettled
          ? "Commitment settlement fee"
          : "Commitment payment fee";
    }

    return commitment.status.isSettled
        ? "Commitment settlement fee"
        : "Commitment payment fee";
  }

  static double entryAmount(Commitment commitment, double amount) {
    return amount * (commitment.isIncome ? -1 : 1);
  }

  static String entryNote(Commitment commitment) {
    if (commitment.isIncome) {
      return commitment.status.isSettled
          ? "Commitment settlement to ${commitment.party.name}"
          : "Commitment payment to ${commitment.party.name}";
    }

    return commitment.status.isSettled
        ? "Commitment settlement from ${commitment.party.name}"
        : "Commitment payment from ${commitment.party.name}";
  }

  factory CommitmentPayment.create({
    required double amount,
    double? fee,
    required String commitmentId,
    required String entryId,
    String? additionId,
    required DateTime issuedAt,
  }) {
    return CommitmentPayment(
      commitmentId: commitmentId,
      amount: amount,
      fee: fee,
      entryId: entryId,
      additionId: additionId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      issuedAt: issuedAt,
    );
  }

  CommitmentPayment withAddition(Entry? value) {
    addition = value;
    return this;
  }

  CommitmentPayment withEntry(Entry? value) {
    if (value == null) return this;
    entry = value;
    return this;
  }

  CommitmentPayment withCommitment(Commitment? value) {
    if (value == null) return this;
    commitment = value;
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

  CommitmentPayment copyWith({
    double? amount,
    double? fee,
    DateTime? issuedAt,
  }) {
    return CommitmentPayment(
      commitmentId: commitmentId,
      entryId: entryId,
      additionId: additionId,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      issuedAt: issuedAt ?? this.issuedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  factory CommitmentPayment.fromRow(Map row) {
    return CommitmentPayment(
      commitmentId: row["commitment_id"],
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
