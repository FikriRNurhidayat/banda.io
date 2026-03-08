import 'package:banda/features/loans/entities/loan.dart';
import 'package:banda/features/loans/services/loan_service.dart';
import 'package:banda/common/types/specification.dart';
import 'package:flutter/material.dart';

class LoanProvider extends ChangeNotifier {
  final LoanService loanService;

  LoanProvider(this.loanService);

  Future<List<Loan>> search(Filter? spec) async {
    return loanService.search(spec);
  }

  Future<void> sync(String id) async {
    await loanService.sync(id);
    notifyListeners();
  }

  Future<void> create({
    required double amount,
    double? fee,
    required DateTime issuedAt,
    DateTime? settledAt,
    required LoanType type,
    required LoanStatus status,
    required String partyId,
    required String accountId,
  }) async {
    await loanService.create(
      amount: amount,
      type: type,
      status: status,
      partyId: partyId,
      accountId: accountId,
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
    required LoanType type,
    required LoanStatus status,
    required String partyId,
    required String accountId,
  }) async {
    await loanService.update(
      id,
      amount: amount,
      type: type,
      status: status,
      partyId: partyId,
      accountId: accountId,
      fee: fee,
      issuedAt: issuedAt,
      settledAt: settledAt,
    );

    notifyListeners();
  }

  Future<Loan?> get(String id) async {
    return loanService.get(id);
  }

  Future<void> delete(String id) async {
    await loanService.delete(id);
    notifyListeners();
  }

  debugReminder(String id) {
    return loanService.debugReminder(id);
  }
}
