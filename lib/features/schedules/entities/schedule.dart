import 'package:bandha/common/entities/controlable.dart';
import 'package:bandha/common/entities/entity.dart';
import 'package:bandha/common/types/controller.dart';
import 'package:bandha/features/accounts/entities/account.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/tags/entities/category.dart';
import 'package:bandha/features/tags/entities/label.dart';

class Schedule extends Controlable {
  @override
  final String id;
  final String? note;
  final double amount;
  final double? fee;
  final ScheduleCycle cycle;
  final int iteration;
  final ScheduleStatus status;
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

  Schedule({
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

  factory Schedule.create({
    String? note,
    required double amount,
    double? fee,
    required ScheduleCycle cycle,
    required ScheduleStatus status,
    required String categoryId,
    required String accountId,
    required String entryId,
    required String? additionId,
    required DateTime dueAt,
  }) {
    final now = DateTime.now();

    return Schedule(
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

  factory Schedule.row(Map row) {
    return Schedule(
      id: row["id"],
      note: row["note"],
      amount: row["amount"],
      fee: row["fee"],
      cycle: ScheduleCycle.parse(row["cycle"]),
      iteration: row["iteration"],
      status: ScheduleStatus.parse(row["status"]),
      entryId: row["entry_id"],
      accountId: row["account_id"],
      additionId: row["addition_id"],
      categoryId: row["category_id"],
      dueAt: DateTime.parse(row["due_at"]),
      createdAt: DateTime.parse(row["created_at"]),
      updatedAt: DateTime.parse(row["updated_at"]),
    );
  }

  Schedule withNote(String? note) {
    return Schedule(
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

  Schedule withFee(double? fee) {
    return Schedule(
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

  Schedule withAdditionId(String? additionId) {
    return Schedule(
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

  Schedule withCategory(Category? category) {
    if (category != null) {
      this.category = category;
    }

    return this;
  }

  Schedule withEntry(Entry? entry) {
    if (entry != null) {
      this.entry = entry;
    }

    return this;
  }

  Schedule withAddition(Entry? addition) {
    this.addition = addition;
    return this;
  }

  Schedule withAccount(Account? account) {
    if (account != null) {
      this.account = account;
    }

    return this;
  }

  Schedule withLabels(List<Label>? labels) {
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

  Schedule unset(String field) {
    return Schedule(
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

  Schedule copyWith({
    String? note,
    double? amount,
    double? fee,
    ScheduleCycle? cycle,
    int? iteration,
    ScheduleStatus? status,
    String? entryId,
    String? accountId,
    String? additionId,
    String? categoryId,
    DateTime? dueAt,
  }) {
    return Schedule(
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
    return Controller.schedule(id);
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

enum ScheduleStatus {
  paid('Paid'),
  pending('Pending'),
  overdue('Overdue');

  get isPaid {
    return this == ScheduleStatus.paid;
  }

  get isPending {
    return this == ScheduleStatus.pending;
  }

  get isOverdue {
    return this == ScheduleStatus.overdue;
  }

  EntryStatus get entryStatus {
    return isPaid ? EntryStatus.done : EntryStatus.pending;
  }

  static parse(String value) {
    return ScheduleStatus.values.firstWhere((status) => status.label == value);
  }

  final String label;
  const ScheduleStatus(this.label);
}

enum ScheduleCycle {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  yearly('Yearly');

  get isDaily {
    return this == ScheduleCycle.daily;
  }

  get isWeekly {
    return this == ScheduleCycle.weekly;
  }

  get isMonthly {
    return this == ScheduleCycle.monthly;
  }

  get isYearly {
    return this == ScheduleCycle.yearly;
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
      case ScheduleCycle.daily:
        return dateTime.subtract(Duration(days: 1));
      case ScheduleCycle.weekly:
        return dateTime.subtract(Duration(days: 7));
      case ScheduleCycle.monthly:
        return _nextMonth(dateTime, -1);
      case ScheduleCycle.yearly:
        return _nextYear(dateTime, -1);
    }
  }

  next(DateTime dateTime) {
    switch (this) {
      case ScheduleCycle.daily:
        return dateTime.add(Duration(days: 1));
      case ScheduleCycle.weekly:
        return dateTime.add(Duration(days: 7));
      case ScheduleCycle.monthly:
        return _nextMonth(dateTime, 1);
      case ScheduleCycle.yearly:
        return _nextYear(dateTime, 1);
    }
  }

  static ScheduleCycle? tryParse(String? value) {
    if (value == null) return null;
    try {
      return parse(value);
    } catch (error) {
      return null;
    }
  }

  static ScheduleCycle parse(String value) {
    return ScheduleCycle.values.firstWhere((cycle) => cycle.label == value);
  }

  final String label;

  const ScheduleCycle(this.label);
}
