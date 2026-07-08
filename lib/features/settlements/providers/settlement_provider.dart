import 'package:bandha/features/settlements/entities/settlement.dart';
import 'package:bandha/features/settlements/services/settlement_service.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:flutter/material.dart';

class SettlementProvider extends ChangeNotifier {
  final SettlementService settlementService;

  SettlementProvider(this.settlementService);

  Future<List<Settlement>> search(Filter? spec) async {
    return settlementService.search(spec);
  }

  Future<void> sync(String id) async {
    await settlementService.sync(id);
    notifyListeners();
  }

  Future<void> create({
    required double amount,
    double? fee,
    required DateTime issuedAt,
    DateTime? settledAt,
    required EntryType type,
    required SettlementStatus status,
    required String categoryId,
    required String partyId,
    required String vaultId,
    List<String>? labelIds,
  }) async {
    await settlementService.create(
      amount: amount,
      type: type,
      status: status,
      categoryId: categoryId,
      partyId: partyId,
      vaultId: vaultId,
      labelIds: labelIds,
      fee: fee ?? 0,
      issuedAt: issuedAt,
      settledAt: settledAt,
    );

    notifyListeners();
  }

  Future<void> update(
    String id, {
    required double amount,
    double? fee,
    required DateTime issuedAt,
    DateTime? settledAt,
    required EntryType type,
    required SettlementStatus status,
    required String categoryId,
    required String partyId,
    required String vaultId,
    List<String>? labelIds,
  }) async {
    await settlementService.update(
      id,
      amount: amount,
      type: type,
      status: status,
      categoryId: categoryId,
      partyId: partyId,
      vaultId: vaultId,
      labelIds: labelIds,
      fee: fee,
      issuedAt: issuedAt,
      settledAt: settledAt,
    );

    notifyListeners();
  }

  Future<Settlement?> get(String id) async {
    return settlementService.get(id);
  }

  Future<void> delete(String id) async {
    await settlementService.delete(id);
    notifyListeners();
  }

  debugReminder(String id) {
    return settlementService.debugReminder(id);
  }
}
