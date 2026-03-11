import 'package:banda/common/entities/controlable.dart';
import 'package:banda/common/entities/entity.dart';
import 'package:banda/common/types/controller.dart';
import 'package:banda/features/accounts/entities/account.dart';
import 'package:banda/features/entries/entities/entry.dart';
import 'package:banda/features/tags/entities/category.dart';
import 'package:banda/features/tags/entities/label.dart';

class Bill extends Controlable {
  @override
  final String id;
  final String? note;
  final double amount;
  final double? fee;
  final BillCycle cycle;
  final int iteration;
  final BillStatus status;
  final String categoryId;
  final String accountId;
  final String entryId;
  final String? additionId;
  final DateTime dueAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  late final Category category;
  late final Account account;
  late final Entry entry;
  late final Entry? addition;
  late final List<Label> labels;

  Bill({
    required this.id,
    this.note,
    required this.amount,
    this.fee,
    required this.cycle,
    required this.iteration,
    required this.status,
    required this.entryId,
    required this.accountId,
    this.additionId,
    required this.categoryId,
    required this.dueAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Bill.create({
    String? note,
    required double amount,
    double? fee,
    required BillCycle cycle,
    required BillStatus status,
    required String categoryId,
    required String accountId,
    required String entryId,
    required String? additionId,
    required DateTime dueAt,
  }) {
    final now = DateTime.now();

    return Bill(
      id: Entity.getId(),
      note: note,
      amount: amount,
      fee: fee,
      cycle: cycle,
      iteration: 1,
      status: status,
      entryId: entryId,
      accountId: accountId,
      categoryId: categoryId,
      additionId: additionId,
      dueAt: dueAt,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Bill.row(Map row) {
    return Bill(
      id: row["id"],
      note: row["note"],
      amount: row["amount"],
      fee: row["fee"],
      cycle: BillCycle.parse(row["cycle"]),
      iteration: row["iteration"],
      status: BillStatus.parse(row["status"]),
      entryId: row["entry_id"],
      accountId: row["account_id"],
      additionId: row["addition_id"],
      categoryId: row["category_id"],
      dueAt: DateTime.parse(row["due_at"]),
      createdAt: DateTime.parse(row["created_at"]),
      updatedAt: DateTime.parse(row["updated_at"]),
    );
  }

  Bill withNote(String? note) {
    return Bill(
      id: id,
      note: note,
      amount: amount,
      fee: fee,
      cycle: cycle,
      iteration: iteration,
      status: status,
      entryId: entryId,
      accountId: accountId,
      additionId: additionId,
      categoryId: categoryId,
      dueAt: dueAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Bill withFee(double? fee) {
    return Bill(
      id: id,
      note: note,
      amount: amount,
      fee: fee,
      cycle: cycle,
      iteration: iteration,
      status: status,
      entryId: entryId,
      accountId: accountId,
      additionId: additionId,
      categoryId: categoryId,
      dueAt: dueAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Bill withAdditionId(String? additionId) {
    return Bill(
      id: id,
      note: note,
      amount: amount,
      fee: fee,
      cycle: cycle,
      iteration: iteration,
      status: status,
      entryId: entryId,
      accountId: accountId,
      additionId: additionId,
      categoryId: categoryId,
      dueAt: dueAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Bill withCategory(Category? category) {
    if (category != null) {
      this.category = category;
    }

    return this;
  }

  Bill withEntry(Entry? entry) {
    if (entry != null) {
      this.entry = entry;
    }

    return this;
  }

  Bill withAddition(Entry? addition) {
    this.addition = addition;
    return this;
  }

  Bill withAccount(Account? account) {
    if (account != null) {
      this.account = account;
    }

    return this;
  }

  Bill withLabels(List<Label>? labels) {
    if (labels != null) {
      this.labels = labels;
    }
    return this;
  }

  bool get canRollover {
    return status.isPaid;
  }

  bool get canRollback {
    return iteration >= 2;
  }

  get labelIds {
    return labels.map((l) => l.id).toList();
  }

  get hasAddition {
    return addition != null;
  }

  Bill unset(String field) {
    return Bill(
      id: id,
      note: field == "note" ? null : note,
      amount: amount,
      fee: field == "fee" ? null : fee,
      cycle: cycle,
      iteration: iteration,
      status: status,
      entryId: entryId,
      accountId: accountId,
      additionId: field == "additionId" ? null : additionId,
      categoryId: categoryId,
      dueAt: dueAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Bill copyWith({
    String? note,
    double? amount,
    double? fee,
    BillCycle? cycle,
    int? iteration,
    BillStatus? status,
    String? entryId,
    String? accountId,
    String? additionId,
    String? categoryId,
    DateTime? dueAt,
  }) {
    return Bill(
      id: id,
      note: note ?? this.note,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      cycle: cycle ?? this.cycle,
      iteration: iteration ?? this.iteration,
      status: status ?? this.status,
      entryId: entryId ?? this.entryId,
      accountId: accountId ?? this.accountId,
      additionId: additionId ?? this.additionId,
      categoryId: categoryId ?? this.categoryId,
      dueAt: dueAt ?? this.dueAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  DateTime get previousTime {
    return cycle.previous(dueAt);
  }

  DateTime get nextTime {
    return cycle.next(dueAt);
  }

  List<Entry> get entries {
    return [entry, addition].whereType<Entry>().toList();
  }

  List<String> get entryIds {
    return entries.map((entry) => entry.id).toList();
  }

  @override
  Controller toController() {
    return Controller.bill(id);
  }

  toMap() {
    return {
      "id": id,
      "note": note,
      "amount": amount,
      "fee": fee,
      "cycle": cycle,
      "iteration": iteration,
      "status": status,
      "entry_id": entryId,
      "addition_id": additionId,
      "category_id": categoryId,
      "label_ids": labelIds,
      "due_at": dueAt,
    };
  }
}

enum BillStatus {
  paid('Paid'),
  pending('Pending'),
  overdue('Overdue');

  get isPaid {
    return this == BillStatus.paid;
  }

  get isPending {
    return this == BillStatus.pending;
  }

  get isOverdue {
    return this == BillStatus.overdue;
  }

  EntryStatus get entryStatus {
    return isPaid ? EntryStatus.done : EntryStatus.pending;
  }

  static parse(String value) {
    return BillStatus.values.firstWhere((status) => status.label == value);
  }

  final String label;
  const BillStatus(this.label);
}

enum BillCycle {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  yearly('Yearly');

  get isDaily {
    return this == BillCycle.daily;
  }

  get isWeekly {
    return this == BillCycle.weekly;
  }

  get isMonthly {
    return this == BillCycle.monthly;
  }

  get isYearly {
    return this == BillCycle.yearly;
  }

  DateTime _nextMonth(DateTime dateTime, int months) {
    final totalMonths = dateTime.month - 1 + months;
    final newYear = dateTime.year + (totalMonths / 12).floor();
    final newMonth = totalMonths % 12 + 1;

    final lastDay = DateTime(newYear, newMonth + 1, 0).day;
    final day = dateTime.day > lastDay ? lastDay : dateTime.day;

    return DateTime(
      newYear,
      newMonth,
      day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
      dateTime.millisecond,
      dateTime.microsecond,
    );
  }

  DateTime _nextYear(DateTime dateTime, int years) {
    return _nextMonth(dateTime, years * 12);
  }

  previous(DateTime dateTime) {
    switch (this) {
      case BillCycle.daily:
        return dateTime.subtract(Duration(days: 1));
      case BillCycle.weekly:
        return dateTime.subtract(Duration(days: 7));
      case BillCycle.monthly:
        return _nextMonth(dateTime, -1);
      case BillCycle.yearly:
        return _nextYear(dateTime, -1);
    }
  }

  next(DateTime dateTime) {
    switch (this) {
      case BillCycle.daily:
        return dateTime.add(Duration(days: 1));
      case BillCycle.weekly:
        return dateTime.add(Duration(days: 7));
      case BillCycle.monthly:
        return _nextMonth(dateTime, 1);
      case BillCycle.yearly:
        return _nextYear(dateTime, 1);
    }
  }

  static BillCycle? tryParse(String? value) {
    if (value == null) return null;
    try {
      return parse(value);
    } catch (error) {
      return null;
    }
  }

  static BillCycle parse(String value) {
    return BillCycle.values.firstWhere((cycle) => cycle.label == value);
  }

  final String label;

  const BillCycle(this.label);
}
