import 'package:bandha/features/commitments/entities/commitment_payment.dart';
import 'package:bandha/features/commitments/services/commitment_payment_service.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:flutter/material.dart';

class CommitmentPaymentProvider extends ChangeNotifier {
  final CommitmentPaymentService paymentService;

  CommitmentPaymentProvider(this.paymentService);

  Future<List<CommitmentPayment>> search(String commitmentId) {
    final Filter filter = {
      "commitment_in": [commitmentId],
    };

    return paymentService.search(filter: filter);
  }

  Future<void> create(
    String commitmentId, {
    required double amount,
    double? fee,
    required String vaultId,
    required DateTime issuedAt,
  }) async {
    await paymentService.create(
      commitmentId,
      amount: amount,
      fee: fee,
      vaultId: vaultId,
      issuedAt: issuedAt,
    );

    notifyListeners();
  }

  Future<void> update(
    String commitmentId,
    String entryId, {
    required double amount,
    double? fee,
    required String vaultId,
    required DateTime issuedAt,
  }) async {
    await paymentService.update(
      commitmentId,
      entryId,
      amount: amount,
      fee: fee,
      vaultId: vaultId,
      issuedAt: issuedAt,
    );

    notifyListeners();
  }

  Future<CommitmentPayment> get(
    String commitmentId,
    String entryId,
  ) async {
    return paymentService.get(commitmentId, entryId);
  }

  Future<void> delete(String commitmentId, String entryId) async {
    await paymentService.delete(commitmentId, entryId);

    notifyListeners();
  }
}
