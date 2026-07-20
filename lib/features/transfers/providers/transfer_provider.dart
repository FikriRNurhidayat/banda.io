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
    required double debitAmount,
    required double creditAmount,
    required DateTime issuedAt,
    required String debitJournalId,
    required String creditJournalId,
    String? note,
    double? fee,
  }) {
    return transferService
        .create(
          debitAmount: debitAmount,
          creditAmount: creditAmount,
          issuedAt: issuedAt,
          fee: fee,
          debitJournalId: debitJournalId,
          creditJournalId: creditJournalId,
          note: note,
        )
        .then((_) => notifyListeners());
  }

  Future<void> update({
    required String id,
    required double debitAmount,
    required double creditAmount,
    required DateTime issuedAt,
    required String debitJournalId,
    required String creditJournalId,
    String? note,
    double? fee,
  }) {
    return transferService
        .update(
          id: id,
          debitAmount: debitAmount,
          creditAmount: creditAmount,
          fee: fee,
          issuedAt: issuedAt,
          debitJournalId: debitJournalId,
          creditJournalId: creditJournalId,
          note: note,
        )
        .then((_) => notifyListeners());
  }

  Future<void> remove(String id) {
    return transferService.delete(id).then((_) => notifyListeners());
  }
}
