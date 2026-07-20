import 'package:bandha/common/entities/entity.dart';
import 'package:bandha/features/tags/entities/category.dart';
import 'package:bandha/features/journals/entities/journal.dart';
import 'package:bandha/common/entities/controlable.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/common/types/controller.dart';
import 'package:bandha/common/types/transaction_type.dart';

class Fund extends Controlable {
  @override
  final String id;
  final String? note;
  final double amount;
  final double balance;
  final FundStatus status;
  final String categoryId;
  final String journalId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? releasedAt;

  late List<Entry> entries;
  late List<Label> labels;
  late Category category;
  late Journal journal;

  static entryLabelName(Fund fund, TransactionType type) {
    return type.label;
  }

  static entryNote(Fund fund, TransactionType type) {
    return type.label;
  }

  static entryAmount(TransactionType type, double amount) {
    return amount * (type.isDeposit ? -1 : 1);
  }

  Fund({
    required this.id,
    this.note,
    required this.amount,
    required this.balance,
    required this.status,
    required this.journalId,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    required this.releasedAt,
  });

  toMap() {
    return {
      id: id,
      note: note,
      amount: amount,
      balance: balance,
      status: status,
      categoryId: categoryId,
      journalId: journalId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      releasedAt: releasedAt,
    };
  }

  List<String> get labelIds {
    return labels.map((label) => label.id).toList();
  }

  factory Fund.create({
    String? note,
    required double amount,
    required double balance,
    required FundStatus status,
    required String categoryId,
    required String journalId,
  }) {
    return Fund(
      id: Entity.getId(),
      note: note,
      amount: amount,
      balance: balance,
      status: status,
      journalId: journalId,
      categoryId: categoryId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      releasedAt: null,
    );
  }

  get canDispense {
    return status != FundStatus.released;
  }

  get canGrow {
    return status != FundStatus.released && balance < amount;
  }

  copyWith({
    String? note,
    double? amount,
    double? balance,
    FundStatus? status,
    String? categoryId,
    String? journalId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? releasedAt,
  }) {
    return Fund(
      id: id,
      note: note ?? this.note,
      amount: amount ?? this.amount,
      balance: balance ?? this.balance,
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
      journalId: journalId ?? this.journalId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      releasedAt: releasedAt ?? this.releasedAt,
    );
  }

  double get progress {
    return (balance.toDouble() / amount.toDouble());
  }

  double get completion {
    return (balance.toDouble() / amount.toDouble()).abs();
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

  Fund withCategory(Category? value) {
    if (value != null) category = value;
    return this;
  }

  Fund withLabels(List<Label>? value) {
    if (value != null) labels = value;
    return this;
  }

  Fund withEntries(List<Entry>? value) {
    if (value != null) entries = value;
    return this;
  }

  Fund withJournal(Journal? value) {
    if (value != null) journal = value;
    return this;
  }

  factory Fund.row(Map<dynamic, dynamic> row) {
    return Fund(
      id: row["id"],
      note: row["note"],
      amount: row["amount"],
      balance: row["balance"],
      status: FundStatus.values.firstWhere(
        (e) => e.label == row["status"],
      ),
      categoryId: row["category_id"],
      journalId: row["journal_id"],
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
