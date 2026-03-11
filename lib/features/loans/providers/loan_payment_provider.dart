import 'package:banda/features/loans/entities/loan_payment.dart';
import 'package:banda/features/loans/services/loan_payment_service.dart';
import 'package:banda/common/types/specification.dart';
import 'package:flutter/material.dart';

class LoanPaymentProvider extends ChangeNotifier {
  final LoanPaymentService paymentService;

  LoanPaymentProvider(this.paymentService);

  Future<List<LoanPayment>> search(String loanId) {
    final Filter filter = {
      "loan_in": [loanId],
    };

    return paymentService.search(filter: filter);
  }

  Future<void> create(
    String loanId, {
    required double amount,
    double? fee,
    required String accountId,
    required DateTime issuedAt,
  }) async {
    await paymentService.create(
      loanId,
      amount: amount,
      fee: fee,
      accountId: accountId,
      issuedAt: issuedAt,
    );

    notifyListeners();
  }

  Future<void> update(
    String loanId,
    String entryId, {
    required double amount,
    double? fee,
    required String accountId,
    required DateTime issuedAt,
  }) async {
    await paymentService.update(
      loanId,
      entryId,
      amount: amount,
      fee: fee,
      accountId: accountId,
      issuedAt: issuedAt,
    );

    notifyListeners();
  }

  Future<LoanPayment> get(String loanId, String entryId) async {
    return paymentService.get(loanId, entryId);
  }

  Future<void> delete(String loanId, String entryId) async {
    await paymentService.delete(loanId, entryId);

    notifyListeners();
  }
}
