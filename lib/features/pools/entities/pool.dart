import 'package:bandha/common/entities/entity.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/common/entities/controlable.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/common/types/controller.dart';
import 'package:bandha/common/types/transaction_type.dart';

class Pool extends Controlable {
  @override
  final String id;
  final String? note;
  final double goal;
  final double balance;
  final PoolStatus status;
  final String vaultId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? releasedAt;

  late List<Entry> entries;
  late List<Label> labels;
  late Vault vault;

  static entryNote(Pool pool, TransactionType type) {
    return type.isDeposit
        ? "Deposit"
        : "Withdraw";
  }

  static entryAmount(TransactionType type, double amount) {
    return amount * (type.isDeposit ? -1 : 1);
  }

  Pool({
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

  factory Pool.create({
    String? note,
    required double goal,
    required double balance,
    required PoolStatus status,
    required String vaultId,
  }) {
    return Pool(
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
    return status != PoolStatus.released;
  }

  get canGrow {
    return status != PoolStatus.released && balance < goal;
  }

  copyWith({
    String? note,
    double? goal,
    double? balance,
    PoolStatus? status,
    String? vaultId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? releasedAt,
  }) {
    return Pool(
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

  Pool applyDelta(EntryType type, double delta) {
    return copyWith(
      balance: balance + (delta * (type == EntryType.income ? -1 : 1)),
    );
  }

  Pool applyEntry(Entry entry) {
    return copyWith(balance: balance + (entry.amount * -1));
  }

  Pool revokeEntry(Entry entry) {
    return copyWith(balance: balance + entry.amount);
  }

  Pool withLabels(List<Label>? value) {
    if (value != null) labels = value;
    return this;
  }

  Pool withEntries(List<Entry>? value) {
    if (value != null) entries = value;
    return this;
  }

  Pool withVault(Vault? value) {
    if (value != null) vault = value;
    return this;
  }

  factory Pool.row(Map<dynamic, dynamic> row) {
    return Pool(
      id: row["id"],
      note: row["note"],
      goal: row["goal"],
      balance: row["balance"],
      status: PoolStatus.values.firstWhere((e) => e.label == row["status"]),
      vaultId: row["vault_id"],
      createdAt: DateTime.parse(row["created_at"]),
      updatedAt: DateTime.parse(row["updated_at"]),
      releasedAt: DateTime.tryParse(row["released_at"] ?? ""),
    );
  }

  @override
  Controller toController() {
    return Controller.pool(id);
  }
}

enum PoolStatus {
  active('Active'),
  released('Released');

  final String label;
  const PoolStatus(this.label);

  get isReleased {
    return PoolStatus.released == this;
  }
}
