import 'package:banda/features/entries/entities/entry.dart';
import 'package:banda/features/funds/entities/fund.dart';
import 'package:banda/features/funds/services/fund_service.dart';
import 'package:banda/common/types/specification.dart';
import 'package:banda/common/types/transaction_type.dart';
import 'package:flutter/material.dart';

class FundProvider extends ChangeNotifier {
  final FundService fundService;

  FundProvider(this.fundService);

  Future<List<Fund>> search(Filter? specification) async {
    return await fundService.search(specification);
  }

  Future<void> deleteTransaction({
    required String fundId,
    required String entryId,
  }) async {
    await fundService.deleteTransaction(fundId: fundId, entryId: entryId);
    notifyListeners();
  }

  Future<void> updateTransaction(
    String fundId,
    String entryId, {
    required double amount,
    required TransactionType type,
    required DateTime issuedAt,
    List<String>? labelIds,
  }) async {
    await fundService.updateTransaction(
      fundId,
      entryId,
      amount: amount,
      type: type,
      issuedAt: issuedAt,
    );

    notifyListeners();
  }

  Future<void> createTransaction(
    String fundId, {
    required double amount,
    required TransactionType type,
    required DateTime issuedAt,
    List<String>? labelIds,
  }) async {
    await fundService.createTransaction(
      fundId,
      amount: amount,
      type: type,
      issuedAt: issuedAt,
    );

    notifyListeners();
  }

  Future<List<Entry>> searchTransactions({
    required String fundId,
    Filter? specification,
  }) async {
    return await fundService.searchTransactions(
      fundId: fundId,
      specification: specification,
    );
  }

  Future<void> create({
    String? note,
    required double goal,
    required String accountId,
    List<String>? labelIds,
  }) async {
    await fundService.create(
      note: note,
      goal: goal,
      accountId: accountId,
      labelIds: labelIds,
    );

    notifyListeners();
  }

  Future<void> retract(String id) async {
    await fundService.retract(id);
    notifyListeners();
  }

  Future<void> release(String id) async {
    await fundService.release(id);
    notifyListeners();
  }

  Future<void> update(
    String id, {
    String? note,
    required double goal,
    List<String>? labelIds,
  }) async {
    await fundService.update(id, note: note, goal: goal, labelIds: labelIds);

    notifyListeners();
  }

  Future<Fund?> get(String id) async {
    return await fundService.get(id);
  }

  Future<void> delete(String id) async {
    await fundService.delete(id);
    notifyListeners();
  }

  Future<void> sync(String id) async {
    await fundService.sync(id);
    notifyListeners();
  }
}
