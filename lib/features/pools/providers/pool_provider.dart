import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/pools/entities/pool.dart';
import 'package:bandha/features/pools/services/pool_service.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:bandha/common/types/transaction_type.dart';
import 'package:flutter/material.dart';

class PoolProvider extends ChangeNotifier {
  final PoolService poolService;

  PoolProvider(this.poolService);

  Future<List<Pool>> search(Filter? specification) async {
    return await poolService.search(specification);
  }

  Future<void> deleteTransaction({
    required String poolId,
    required String entryId,
  }) async {
    await poolService.deleteTransaction(
      poolId: poolId,
      entryId: entryId,
    );
    notifyListeners();
  }

  Future<void> updateTransaction(
    String poolId,
    String entryId, {
    required double amount,
    required TransactionType type,
    required DateTime issuedAt,
    List<String>? labelIds,
  }) async {
    await poolService.updateTransaction(
      poolId,
      entryId,
      amount: amount,
      type: type,
      issuedAt: issuedAt,
      labelIds: labelIds,
    );

    notifyListeners();
  }

  Future<void> createTransaction(
    String poolId, {
    required double amount,
    required TransactionType type,
    required DateTime issuedAt,
    List<String>? labelIds,
  }) async {
    await poolService.createTransaction(
      poolId,
      amount: amount,
      type: type,
      issuedAt: issuedAt,
      labelIds: labelIds,
    );

    notifyListeners();
  }

  Future<List<Entry>> searchTransactions({
    required String poolId,
    Filter? specification,
  }) async {
    return await poolService.searchTransactions(
      poolId: poolId,
      specification: specification,
    );
  }

  Future<void> create({
    String? note,
    required double goal,
    required String categoryId,
    required String vaultId,
    List<String>? labelIds,
  }) async {
    await poolService.create(
      note: note,
      goal: goal,
      categoryId: categoryId,
      vaultId: vaultId,
      labelIds: labelIds,
    );

    notifyListeners();
  }

  Future<void> retract(String id) async {
    await poolService.retract(id);
    notifyListeners();
  }

  Future<void> release(String id) async {
    await poolService.release(id);
    notifyListeners();
  }

  Future<void> update(
    String id, {
    String? note,
    required double goal,
    String? categoryId,
    List<String>? labelIds,
  }) async {
    await poolService.update(
      id,
      note: note,
      goal: goal,
      categoryId: categoryId,
      labelIds: labelIds,
    );

    notifyListeners();
  }

  Future<Pool?> get(String id) async {
    return await poolService.get(id);
  }

  Future<void> delete(String id) async {
    await poolService.delete(id);
    notifyListeners();
  }

  Future<void> sync(String id) async {
    await poolService.sync(id);
    notifyListeners();
  }
}
