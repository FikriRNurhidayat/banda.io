import 'package:banda/features/accounts/entities/account.dart';
import 'package:banda/features/accounts/services/account_service.dart';
import 'package:flutter/material.dart';

class AccountProvider extends ChangeNotifier {
  final AccountService accountService;

  AccountProvider(this.accountService);

  Future<List<Account>> search() {
    return accountService.search();
  }

  Future<void> create({
    required String name,
    required String holderName,
    required double balance,
    required AccountKind? kind,
  }) {
    return accountService
        .create(
          name: name,
          holderName: holderName,
          kind: kind,
          balance: balance,
        )
        .then((_) => notifyListeners());
  }

  Future<void> update(
    String id, {
    required String name,
    required String holderName,
    required double balance,
    required AccountKind? kind,
  }) {
    return accountService
        .update(
          id,
          name: name,
          holderName: holderName,
          kind: kind,
          balance: balance,
        )
        .then((_) => notifyListeners());
  }

  Future<Account?> get(String id) {
    return accountService.get(id);
  }

  Future<void> delete(String id) {
    return accountService.delete(id).then((_) => notifyListeners());
  }

  Future<void> sync(String id) {
    return accountService.sync(id).then((_) => notifyListeners());
  }
}
