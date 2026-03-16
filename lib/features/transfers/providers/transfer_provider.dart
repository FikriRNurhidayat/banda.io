import 'package:bandha/features/transfers/entities/transfer.dart';
import 'package:bandha/features/transfers/services/transfer_service.dart';
import 'package:flutter/material.dart';

class TransferProvider extends ChangeNotifier {
  final TransferService transferService;

  TransferProvider(this.transferService);

  Future<List<Transfer>> search() async {
    return transferService.search();
  }

  Future<Transfer?> get(String id) async {
    return transferService.get(id);
  }

  Future<void> create({
    required double amount,
    required DateTime issuedAt,
    required String debitVaultId,
    required String creditVaultId,
    double? fee,
  }) {
    return transferService
        .create(
          amount: amount,
          issuedAt: issuedAt,
          fee: fee,
          debitVaultId: debitVaultId,
          creditVaultId: creditVaultId,
        )
        .then((_) => notifyListeners());
  }

  Future<void> update({
    required String id,
    required double amount,
    required DateTime issuedAt,
    required String debitVaultId,
    required String creditVaultId,
    double? fee,
  }) {
    return transferService
        .update(
          id: id,
          amount: amount,
          fee: fee,
          issuedAt: issuedAt,
          debitVaultId: debitVaultId,
          creditVaultId: creditVaultId,
        )
        .then((_) => notifyListeners());
  }

  Future<void> remove(String id) {
    return transferService.delete(id).then((_) => notifyListeners());
  }
}
