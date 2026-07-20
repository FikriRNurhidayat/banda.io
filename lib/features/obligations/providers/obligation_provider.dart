import 'package:bandha/features/obligations/entities/obligation.dart';
import 'package:bandha/features/obligations/services/obligation_service.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:flutter/material.dart';

class ObligationProvider extends ChangeNotifier {
  final ObligationService obligationService;

  ObligationProvider(this.obligationService);

  Future<List<Obligation>> search(Filter? spec) async {
    return obligationService.search(spec);
  }

  Future<void> sync(String id) async {
    await obligationService.sync(id);
    notifyListeners();
  }

  Future<void> create({
    required double amount,
    double? fee,
    required DateTime issuedAt,
    DateTime? settledAt,
    required EntryType type,
    required ObligationStatus status,
    required String categoryId,
    required String partyId,
    required String journalId,
    List<String>? labelIds,
  }) async {
    await obligationService.create(
      amount: amount,
      type: type,
      status: status,
      categoryId: categoryId,
      partyId: partyId,
      journalId: journalId,
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
    required ObligationStatus status,
    required String categoryId,
    required String partyId,
    required String journalId,
    List<String>? labelIds,
  }) async {
    await obligationService.update(
      id,
      amount: amount,
      type: type,
      status: status,
      categoryId: categoryId,
      partyId: partyId,
      journalId: journalId,
      labelIds: labelIds,
      fee: fee,
      issuedAt: issuedAt,
      settledAt: settledAt,
    );

    notifyListeners();
  }

  Future<Obligation?> get(String id) async {
    return obligationService.get(id);
  }

  Future<void> delete(String id) async {
    await obligationService.delete(id);
    notifyListeners();
  }

  debugReminder(String id) {
    return obligationService.debugReminder(id);
  }
}
