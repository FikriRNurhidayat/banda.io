import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/common/services/service.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/features/vaults/repositories/vault_repository.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:bandha/features/tags/repositories/category_repository.dart';

class VaultService extends Service {
  final VaultRepository vaultRepository;
  final EntryRepository entryRepository;
  final CategoryRepository categoryRepository;

  VaultService({
    required this.vaultRepository,
    required this.entryRepository,
    required this.categoryRepository,
  });

  Future<Vault> create({
    required String name,
    required String holderName,
    required double balance,
  }) {
    return work<Vault>(() async {
      final vault = Vault.create(
        name: name,
        holderName: holderName,
        balance: balance,
      );

      await vaultRepository.save(vault);

      if (!isZero(balance)) {
        final category = await categoryRepository.getByName("Adjustment");

        final entry = Entry.readOnly(
          amount: balance,
          status: EntryStatus.done,
          issuedAt: DateTime.now(),
          vaultId: vault.id,
          categoryId: category.id,
        );

        await entryRepository.save(entry);
      }

      return vault;
    });
  }

  update(
    String id, {
    required String name,
    required String holderName,
    required double balance,
  }) {
    return work(() async {
      final vault = await vaultRepository.get(id);

      if (vault.balance != balance) {
        final category = await categoryRepository.getByName("Adjustment");
        final delta = balance - vault.balance;
        final entry = Entry.readOnly(
          amount: delta,
          status: EntryStatus.done,
          issuedAt: DateTime.now(),
          vaultId: vault.id,
          categoryId: category.id,
        );

        await entryRepository.save(entry);
      }

      await vaultRepository.save(
        vault.copyWith(
          name: name,
          holderName: holderName,
          balance: balance,
        ),
      );
    });
  }

  search() {
    return vaultRepository.search();
  }

  get(String id) {
    return vaultRepository.get(id);
  }

  delete(String id) {
    return vaultRepository.delete(id);
  }

  sync(String id) {
    return vaultRepository.sync(id);
  }
}
