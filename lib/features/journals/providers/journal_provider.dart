import 'package:bandha/features/journals/entities/journal.dart';
import 'package:bandha/features/journals/services/journal_service.dart';
import 'package:flutter/material.dart';

class JournalProvider extends ChangeNotifier {
  final JournalService journalService;

  JournalProvider(this.journalService);

  Future<List<Journal>> search() {
    return journalService.search();
  }

  Future<void> create({
    required String name,
    required String holderName,
    required double balance,
  }) {
    return journalService
        .create(name: name, holderName: holderName, balance: balance)
        .then((_) => notifyListeners());
  }

  Future<void> update(
    String id, {
    required String name,
    required String holderName,
    required double balance,
  }) {
    return journalService
        .update(
          id,
          name: name,
          holderName: holderName,
          balance: balance,
        )
        .then((_) => notifyListeners());
  }

  Future<Journal?> get(String id) {
    return journalService.get(id);
  }

  Future<void> delete(String id) {
    return journalService.delete(id).then((_) => notifyListeners());
  }

  Future<void> sync(String id) {
    return journalService.sync(id).then((_) => notifyListeners());
  }
}
