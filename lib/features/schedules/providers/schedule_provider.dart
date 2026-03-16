import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/schedules/entities/schedule.dart';
import 'package:bandha/features/schedules/services/schedule_service.dart';
import 'package:flutter/material.dart';

class ScheduleProvider extends ChangeNotifier {
  final ScheduleService scheduleService;

  ScheduleProvider(this.scheduleService);

  Future<List<Schedule>> search() {
    return scheduleService.search();
  }

  create({
    String? note,
    required double amount,
    double? fee,
    required EntryType type,
    required ScheduleCycle cycle,
    required ScheduleStatus status,
    required DateTime dueAt,
    required String categoryId,
    required String vaultId,
    required List<String> labelIds,
  }) async {
    await scheduleService.create(
      note: note,
      type: type,
      amount: amount,
      fee: fee,
      cycle: cycle,
      status: status,
      dueAt: dueAt,
      categoryId: categoryId,
      vaultId: vaultId,
      labelIds: labelIds,
    );

    notifyListeners();
  }

  update(
    String id, {
    String? note,
    required double amount,
    double? fee,
    required EntryType type,
    required ScheduleCycle cycle,
    required ScheduleStatus status,
    required DateTime dueAt,
    required String categoryId,
    required String vaultId,
    required List<String> labelIds,
  }) async {
    await scheduleService.update(
      id,
      note: note,
      type: type,
      amount: amount,
      fee: fee,
      cycle: cycle,
      status: status,
      dueAt: dueAt,
      categoryId: categoryId,
      vaultId: vaultId,
      labelIds: labelIds,
    );

    notifyListeners();
  }

  Future<Schedule?> get(String id) async {
    return await scheduleService.get(id);
  }

  delete(String id) async {
    await scheduleService.delete(id);

    notifyListeners();
  }

  rollback(String id) async {
    await scheduleService.rollback(id);
    notifyListeners();
  }

  rollover(String id) async {
    await scheduleService.rollover(id);
    notifyListeners();
  }
}
