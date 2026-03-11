import 'package:banda/features/accounts/entities/account.dart';
import 'package:banda/features/tags/entities/category.dart';
import 'package:banda/common/entities/controlable.dart';
import 'package:banda/common/entities/entity.dart';
import 'package:banda/features/tags/entities/label.dart';
import 'package:banda/common/types/controller.dart';
import 'package:banda/common/types/controller_type.dart';
import 'package:banda/common/types/transaction_type.dart';

class Entry extends Entity {
  final String id;
  final String? note;
  final double amount;
  final EntryStatus status;
  final DateTime issuedAt;
  final bool readonly;
  final String accountId;
  final String categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Controller? controller;

  List<Label> labels = [];
  late Category category;
  late Account account;
  Map<String, dynamic>? annotations = {};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Account && id == other.id);

  @override
  int get hashCode => id.hashCode;

  Entry({
    required this.id,
    this.note,
    required this.amount,
    required this.status,
    required this.issuedAt,
    required this.readonly,
    required this.accountId,
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

  Entry withAnnotations(Map<String, dynamic>? annotations) {
    if (annotations != null) this.annotations = annotations;
    return this;
  }

  Entry withLabels(List<Label>? labels) {
    if (labels != null) this.labels = labels;
    return this;
  }

  Entry withAccount(Account? account) {
    if (account != null) this.account = account;
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
    String? accountId,
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
      accountId: accountId ?? this.accountId,
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
      "accountId": accountId,
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
    required String accountId,
    required String categoryId,
    Controller? controller,
  }) {
    return Entry.create(
      note: note,
      amount: amount,
      status: status,
      issuedAt: issuedAt,
      readonly: false,
      accountId: accountId,
      categoryId: categoryId,
      controller: controller,
    );
  }

  factory Entry.readOnly({
    String? note,
    required double amount,
    required EntryStatus status,
    required DateTime issuedAt,
    required String accountId,
    required String categoryId,
    Controller? controller,
  }) {
    return Entry.create(
      note: note,
      amount: amount,
      status: status,
      issuedAt: issuedAt,
      readonly: true,
      accountId: accountId,
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
    required String accountId,
    required String categoryId,
    Controller? controller,
  }) {
    return Entry(
      id: Entity.getId(),
      note: note,
      amount: amount,
      status: status,
      readonly: readonly,
      accountId: accountId,
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
      accountId: row["account_id"],
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
