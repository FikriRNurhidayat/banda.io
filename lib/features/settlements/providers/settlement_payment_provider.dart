import 'package:bandha/features/settlements/entities/settlement_payment.dart';
import 'package:bandha/features/settlements/services/settlement_payment_service.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:flutter/material.dart';

class SettlementPaymentProvider extends ChangeNotifier {
  final SettlementPaymentService paymentService;

  SettlementPaymentProvider(this.paymentService);

  Future<List<SettlementPayment>> search(String settlementId) {
    final Filter filter = {
      "settlement_in": [settlementId],
    };

    return paymentService.search(filter: filter);
  }

  Future<void> create(
    String settlementId, {
    required double amount,
    double? fee,
    required String vaultId,
    required DateTime issuedAt,
  }) async {
    await paymentService.create(
      settlementId,
      amount: amount,
      fee: fee,
      vaultId: vaultId,
      issuedAt: issuedAt,
    );

    notifyListeners();
  }

  Future<void> update(
    String settlementId,
    String entryId, {
    required double amount,
    double? fee,
    required String vaultId,
    required DateTime issuedAt,
  }) async {
    await paymentService.update(
      settlementId,
      entryId,
      amount: amount,
      fee: fee,
      vaultId: vaultId,
      issuedAt: issuedAt,
    );

    notifyListeners();
  }

  Future<SettlementPayment> get(
    String settlementId,
    String entryId,
  ) async {
    return paymentService.get(settlementId, entryId);
  }

  Future<void> delete(String settlementId, String entryId) async {
    await paymentService.delete(settlementId, entryId);

    notifyListeners();
  }
}
