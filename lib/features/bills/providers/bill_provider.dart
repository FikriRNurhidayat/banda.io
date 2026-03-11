import 'package:banda/features/bills/entities/bill.dart';
import 'package:banda/features/bills/services/bill_service.dart';
import 'package:flutter/material.dart';

class BillProvider extends ChangeNotifier {
  final BillService billService;

  BillProvider(this.billService);

  Future<List<Bill>> search() {
    return billService.search();
  }

  create({
    String? note,
    required double amount,
    double? fee,
    required BillCycle cycle,
    required BillStatus status,
    required DateTime dueAt,
    required String categoryId,
    required String accountId,
    required List<String> labelIds,
  }) async {
    await billService.create(
      note: note,
      amount: amount,
      fee: fee,
      cycle: cycle,
      status: status,
      dueAt: dueAt,
      categoryId: categoryId,
      accountId: accountId,
      labelIds: labelIds,
    );

    notifyListeners();
  }

  update(
    String id, {
    String? note,
    required double amount,
    double? fee,
    required BillCycle cycle,
    required BillStatus status,
    required DateTime dueAt,
    required String categoryId,
    required String accountId,
    required List<String> labelIds,
  }) async {
    await billService.update(
      id,
      note: note,
      amount: amount,
      fee: fee,
      cycle: cycle,
      status: status,
      dueAt: dueAt,
      categoryId: categoryId,
      accountId: accountId,
      labelIds: labelIds,
    );

    notifyListeners();
  }

  Future<Bill?> get(String id) async {
    return await billService.get(id);
  }

  delete(String id) async {
    await billService.delete(id);

    notifyListeners();
  }

  rollback(String id) async {
    await billService.rollback(id);
    notifyListeners();
  }

  rollover(String id) async {
    await billService.rollover(id);
    notifyListeners();
  }
}
