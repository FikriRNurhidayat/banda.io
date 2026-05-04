import 'package:bandha/common/entities/controlable.dart';
import 'package:bandha/common/types/controller.dart';
import 'package:bandha/common/types/expression.dart';

class Allocation extends Controlable {
  @override
  final String id;
  final double baseThreshold;
  final double currentThreshold;
  final double usage;
  final Expression rules;
  final AllocationCycle cycle;
  DateTime? startedAt;
  DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Allocation({
    required this.id,
    required this.baseThreshold,
    required this.currentThreshold,
    required this.usage,
    required this.rules,
    required this.cycle,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Controller toController() {
    throw UnimplementedError();
  }
}

enum AllocationCycle {
  forever('Forever'),
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  yearly('Yearly');

  get isForever {
    return this == AllocationCycle.forever;
  }

  get isDaily {
    return this == AllocationCycle.daily;
  }

  get isWeekly {
    return this == AllocationCycle.weekly;
  }

  get isMonthly {
    return this == AllocationCycle.monthly;
  }

  get isYearly {
    return this == AllocationCycle.yearly;
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
      case AllocationCycle.daily:
        return dateTime.subtract(Duration(days: 1));
      case AllocationCycle.weekly:
        return dateTime.subtract(Duration(days: 7));
      case AllocationCycle.monthly:
        return _nextMonth(dateTime, -1);
      case AllocationCycle.yearly:
        return _nextYear(dateTime, -1);
      default:
        return null;
    }
  }

  next(DateTime dateTime) {
    switch (this) {
      case AllocationCycle.daily:
        return dateTime.add(Duration(days: 1));
      case AllocationCycle.weekly:
        return dateTime.add(Duration(days: 7));
      case AllocationCycle.monthly:
        return _nextMonth(dateTime, 1);
      case AllocationCycle.yearly:
        return _nextYear(dateTime, 1);
      default:
        return null;
    }
  }

  static AllocationCycle? tryParse(String? value) {
    if (value == null) return null;
    try {
      return parse(value);
    } catch (error) {
      return null;
    }
  }

  static AllocationCycle parse(String value) {
    return AllocationCycle.values.firstWhere(
      (cycle) => cycle.label == value,
    );
  }

  final String label;

  const AllocationCycle(this.label);
}
