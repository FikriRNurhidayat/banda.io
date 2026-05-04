import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/features/vaults/services/vault_service.dart';
import 'package:flutter/material.dart';

class VaultProvider extends ChangeNotifier {
  final VaultService vaultService;

  VaultProvider(this.vaultService);

  Future<List<Vault>> search() {
    return vaultService.search();
  }

  Future<void> create({
    required String name,
    required String holderName,
    required double balance,
  }) {
    return vaultService
        .create(name: name, holderName: holderName, balance: balance)
        .then((_) => notifyListeners());
  }

  Future<void> update(
    String id, {
    required String name,
    required String holderName,
    required double balance,
  }) {
    return vaultService
        .update(
          id,
          name: name,
          holderName: holderName,
          balance: balance,
        )
        .then((_) => notifyListeners());
  }

  Future<Vault?> get(String id) {
    return vaultService.get(id);
  }

  Future<void> delete(String id) {
    return vaultService.delete(id).then((_) => notifyListeners());
  }

  Future<void> sync(String id) {
    return vaultService.sync(id).then((_) => notifyListeners());
  }
}
