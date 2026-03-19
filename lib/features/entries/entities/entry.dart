import 'package:bandha/features/tags/types/read_only_label.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/features/tags/entities/category.dart';
import 'package:bandha/common/entities/controlable.dart';
import 'package:bandha/common/entities/entity.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/common/types/controller.dart';
import 'package:bandha/common/types/controller_type.dart';
import 'package:bandha/common/types/transaction_type.dart';

class Entry extends Entity {
  final String id;
  final String? note;
  final double amount;
  final EntryStatus status;
  final DateTime issuedAt;
  final bool readonly;
  final String vaultId;
  final String categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Controller? controller;

  List<Label> labels = [];
  late Category category;
  late Vault vault;
  Map<String, dynamic>? annotations = {};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Vault && id == other.id);

  @override
  int get hashCode => id.hashCode;

  Entry({
    required this.id,
    this.note,
    required this.amount,
    required this.status,
    required this.issuedAt,
    required this.readonly,
    required this.vaultId,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    this.controller,
    this.annotations,
  });

  Entry annotate(String name, dynamic value) {
    annotations ??= {};
    annotations![name] = value is String ? value : value.toString();
    return this;
  }

  static compute(EntryType type, double amount) {
    return amount * (type == EntryType.income ? 1 : -1);
  }

  get transactionType {
    if (isIncome()) {
      return TransactionType.withdrawal;
    }

    return TransactionType.deposit;
  }

  get entryType {
    if (isIncome()) {
      return EntryType.income;
    }

    return EntryType.expense;
  }

  isDone() {
    return status == EntryStatus.done;
  }

  isExpense() {
    return amount < 0;
  }

  isIncome() {
    return amount >= 0;
  }

  get labelIds {
    return labels.map((l) => l.id).toList();
  }

  get isDisbursement {
    return labels.any(
      (label) =>
          label.readOnly &&
          label.name == ReadOnlyLabel.disbursement.label,
    );
  }

  get isFee {
    return labels.any(
      (label) =>
          label.readOnly && label.name == ReadOnlyLabel.fee.label,
    );
  }

  get isWithdraw {
    return labels.any(
      (label) =>
          label.readOnly && label.name == ReadOnlyLabel.withdraw.label,
    );
  }

  get isDeposit {
    return labels.any(
      (label) =>
          label.readOnly && label.name == ReadOnlyLabel.deposit.label,
    );
  }

  get isCommitment {
    return labels.any(
      (label) =>
          label.readOnly &&
          label.name == ReadOnlyLabel.commitment.label,
    );
  }

  get isDebit {
    return labels.any(
      (label) =>
          label.readOnly && label.name == ReadOnlyLabel.debit.label,
    );
  }

  get isCredit {
    return labels.any(
      (label) =>
          label.readOnly && label.name == ReadOnlyLabel.credit.label,
    );
  }

  get isReleased {
    return labels.any(
      (label) =>
          label.readOnly && label.name == ReadOnlyLabel.released.label,
    );
  }

  get isRetracted {
    return labels.any(
      (label) =>
          label.readOnly && label.name == ReadOnlyLabel.retracted.label,
    );
  }

  get hasReadOnlyLabels {
    return labels.any((label) => label.readOnly);
  }

  get readOnlyLabels {
    return labels.where((label) => label.readOnly);
  }

  get hasWritableLabels {
    return labels.any((label) => !label.readOnly);
  }

  get writableLabels {
    return labels.where((label) => !label.readOnly);
  }

  Entry withAnnotations(Map<String, dynamic>? annotations) {
    if (annotations != null) this.annotations = annotations;
    return this;
  }

  Entry withLabels(List<Label>? labels) {
    if (labels != null) this.labels = labels;
    return this;
  }

  Entry withVault(Vault? vault) {
    if (vault != null) this.vault = vault;
    return this;
  }

  Entry withCategory(Category? category) {
    if (category != null) this.category = category;
    return this;
  }

  Entry controlledBy(Controlable controlable) {
    return copyWith(controller: controlable.toController());
  }

  Entry copyWith({
    String? id,
    String? note,
    double? amount,
    EntryStatus? status,
    DateTime? issuedAt,
    bool? readonly,
    String? vaultId,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Controller? controller,
  }) {
    return Entry(
      id: id ?? this.id,
      note: note ?? this.note,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      readonly: readonly ?? this.readonly,
      vaultId: vaultId ?? this.vaultId,
      categoryId: categoryId ?? this.categoryId,
      issuedAt: issuedAt ?? this.issuedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      controller: controller ?? this.controller,
      annotations: annotations,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "note": note,
      "amount": amount,
      "status": status,
      "issuedAt": issuedAt,
      "readonly": readonly,
      "vaultId": vaultId,
      "categoryId": categoryId,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
      "labelIds": labels.map((label) => label.id).toList(),
    };
  }

  factory Entry.writeable({
    required String note,
    required double amount,
    required EntryStatus status,
    required DateTime issuedAt,
    required String vaultId,
    required String categoryId,
    Controller? controller,
  }) {
    return Entry.create(
      note: note,
      amount: amount,
      status: status,
      issuedAt: issuedAt,
      readonly: false,
      vaultId: vaultId,
      categoryId: categoryId,
      controller: controller,
    );
  }

  factory Entry.readOnly({
    String? note,
    required double amount,
    required EntryStatus status,
    required DateTime issuedAt,
    required String vaultId,
    required String categoryId,
    Controller? controller,
  }) {
    return Entry.create(
      note: note,
      amount: amount,
      status: status,
      issuedAt: issuedAt,
      readonly: true,
      vaultId: vaultId,
      categoryId: categoryId,
      controller: controller,
    );
  }

  factory Entry.create({
    String? note,
    required double amount,
    required EntryStatus status,
    required DateTime issuedAt,
    required bool readonly,
    required String vaultId,
    required String categoryId,
    Controller? controller,
  }) {
    return Entry(
      id: Entity.getId(),
      note: note,
      amount: amount,
      status: status,
      readonly: readonly,
      vaultId: vaultId,
      categoryId: categoryId,
      issuedAt: issuedAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      controller: controller,
    );
  }

  static Entry? tryRow(Map? row) {
    if (row == null) return null;
    return Entry.row(row);
  }

  factory Entry.row(Map row) {
    final controller = row["controller_id"] != null
        ? Controller(
            ControllerType.fromLabel(row["controller_type"]),
            row["controller_id"],
          )
        : null;

    return Entry(
      id: row["id"],
      note: row["note"],
      amount: row["amount"],
      status: EntryStatus.values.firstWhere(
        (e) => e.label == row["status"],
        orElse: () => EntryStatus.unknown,
      ),
      issuedAt: DateTime.parse(row["issued_at"]),
      readonly: row["readonly"] == 1,
      vaultId: row["vault_id"],
      categoryId: row["category_id"],
      createdAt: DateTime.parse(row["created_at"]),
      updatedAt: DateTime.parse(row["updated_at"]),
      controller: controller,
    );
  }
}

enum EntryType {
  income('Income'),
  expense('Expense');

  final String label;
  const EntryType(this.label);

  get isIncome {
    return this == EntryType.income;
  }

  get isExpense {
    return this == EntryType.expense;
  }
}

enum EntryStatus {
  pending('Pending'),
  done('Done'),
  unknown('Unknown');

  isPending() {
    return this == EntryStatus.pending;
  }

  isDone() {
    return this == EntryStatus.done;
  }

  final String label;
  const EntryStatus(this.label);
}
