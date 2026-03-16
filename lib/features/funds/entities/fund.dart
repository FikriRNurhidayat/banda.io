import 'package:bandha/common/entities/entity.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/common/entities/controlable.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/common/types/controller.dart';
import 'package:bandha/common/types/transaction_type.dart';

class Fund extends Controlable {
  @override
  final String id;
  final String? note;
  final double goal;
  final double balance;
  final FundStatus status;
  final String vaultId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? releasedAt;

  late List<Entry> entries;
  late List<Label> labels;
  late Vault vault;

  static entryNote(Fund fund, TransactionType type) {
    return type.isDeposit
        ? "Deposit to ${fund.note}"
        : "Withdraw from ${fund.note}";
  }

  static entryAmount(TransactionType type, double amount) {
    return amount * (type.isDeposit ? -1 : 1);
  }

  Fund({
    required this.id,
    this.note,
    required this.goal,
    required this.balance,
    required this.status,
    required this.vaultId,
    required this.createdAt,
    required this.updatedAt,
    required this.releasedAt,
  });

  toMap() {
    return {
      id: id,
      note: note,
      goal: goal,
      balance: balance,
      status: status,
      vaultId: vaultId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      releasedAt: releasedAt,
    };
  }

  get labelIds {
    return labels.map((label) => label.id).toList();
  }

  factory Fund.create({
    String? note,
    required double goal,
    required double balance,
    required FundStatus status,
    required String vaultId,
  }) {
    return Fund(
      id: Entity.getId(),
      note: note,
      goal: goal,
      balance: balance,
      status: status,
      vaultId: vaultId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      releasedAt: null,
    );
  }

  get canDispense {
    return status != FundStatus.released;
  }

  get canGrow {
    return status != FundStatus.released && balance < goal;
  }

  copyWith({
    String? note,
    double? goal,
    double? balance,
    FundStatus? status,
    String? vaultId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? releasedAt,
  }) {
    return Fund(
      id: id,
      note: note ?? this.note,
      goal: goal ?? this.goal,
      balance: balance ?? this.balance,
      status: status ?? this.status,
      vaultId: vaultId ?? this.vaultId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      releasedAt: releasedAt ?? this.releasedAt,
    );
  }

  double getProgress() {
    return (balance.toDouble() / goal.toDouble());
  }

  Fund applyDelta(EntryType type, double delta) {
    return copyWith(
      balance: balance + (delta * (type == EntryType.income ? -1 : 1)),
    );
  }

  Fund applyEntry(Entry entry) {
    return copyWith(balance: balance + (entry.amount * -1));
  }

  Fund revokeEntry(Entry entry) {
    return copyWith(balance: balance + entry.amount);
  }

  Fund withLabels(List<Label>? value) {
    if (value != null) labels = value;
    return this;
  }

  Fund withEntries(List<Entry>? value) {
    if (value != null) entries = value;
    return this;
  }

  Fund withVault(Vault? value) {
    if (value != null) vault = value;
    return this;
  }

  factory Fund.row(Map<dynamic, dynamic> row) {
    return Fund(
      id: row["id"],
      note: row["note"],
      goal: row["goal"],
      balance: row["balance"],
      status: FundStatus.values.firstWhere((e) => e.label == row["status"]),
      vaultId: row["vault_id"],
      createdAt: DateTime.parse(row["created_at"]),
      updatedAt: DateTime.parse(row["updated_at"]),
      releasedAt: DateTime.tryParse(row["released_at"] ?? ""),
    );
  }

  @override
  Controller toController() {
    return Controller.fund(id);
  }
}

enum FundStatus {
  active('Active'),
  released('Released');

  final String label;
  const FundStatus(this.label);

  get isReleased {
    return FundStatus.released == this;
  }
}
