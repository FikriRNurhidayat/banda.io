import 'package:bandha/features/obligations/entities/obligation_payment.dart';
import 'package:bandha/features/obligations/services/obligation_payment_service.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:flutter/material.dart';

class ObligationPaymentProvider extends ChangeNotifier {
  final ObligationPaymentService paymentService;

  ObligationPaymentProvider(this.paymentService);

  Future<List<ObligationPayment>> search(String obligationId) {
    final Filter filter = {
      "obligation_in": [obligationId],
    };

    return paymentService.search(filter: filter);
  }

  Future<void> create(
    String obligationId, {
    required double amount,
    double? fee,
    required String journalId,
    required DateTime issuedAt,
  }) async {
    await paymentService.create(
      obligationId,
      amount: amount,
      fee: fee,
      journalId: journalId,
      issuedAt: issuedAt,
    );

    notifyListeners();
  }

  Future<void> update(
    String obligationId,
    String entryId, {
    required double amount,
    double? fee,
    required String journalId,
    required DateTime issuedAt,
  }) async {
    await paymentService.update(
      obligationId,
      entryId,
      amount: amount,
      fee: fee,
      journalId: journalId,
      issuedAt: issuedAt,
    );

    notifyListeners();
  }

  Future<ObligationPayment> get(
    String obligationId,
    String entryId,
  ) async {
    return paymentService.get(obligationId, entryId);
  }

  Future<void> delete(String obligationId, String entryId) async {
    await paymentService.delete(obligationId, entryId);

    notifyListeners();
  }
}
