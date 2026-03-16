import 'package:bandha/features/commitments/entities/commitment.dart';
import 'package:bandha/features/commitments/services/commitment_service.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:flutter/material.dart';

class CommitmentProvider extends ChangeNotifier {
  final CommitmentService commitmentService;

  CommitmentProvider(this.commitmentService);

  Future<List<Commitment>> search(Filter? spec) async {
    return commitmentService.search(spec);
  }

  Future<void> sync(String id) async {
    await commitmentService.sync(id);
    notifyListeners();
  }

  Future<void> create({
    required double amount,
    double? fee,
    required DateTime issuedAt,
    DateTime? settledAt,
    required EntryType type,
    required CommitmentStatus status,
    required String categoryId,
    required String partyId,
    required String vaultId,
  }) async {
    await commitmentService.create(
      amount: amount,
      type: type,
      status: status,
      categoryId: categoryId,
      partyId: partyId,
      vaultId: vaultId,
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
    required CommitmentStatus status,
    required String categoryId,
    required String partyId,
    required String vaultId,
  }) async {
    await commitmentService.update(
      id,
      amount: amount,
      type: type,
      status: status,
      categoryId: categoryId,
      partyId: partyId,
      vaultId: vaultId,
      fee: fee,
      issuedAt: issuedAt,
      settledAt: settledAt,
    );

    notifyListeners();
  }

  Future<Commitment?> get(String id) async {
    return commitmentService.get(id);
  }

  Future<void> delete(String id) async {
    await commitmentService.delete(id);
    notifyListeners();
  }

  debugReminder(String id) {
    return commitmentService.debugReminder(id);
  }
}
