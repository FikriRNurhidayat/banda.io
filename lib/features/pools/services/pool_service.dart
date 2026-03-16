import 'package:bandha/common/services/service.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/pools/entities/pool.dart';
import 'package:bandha/features/vaults/repositories/vault_repository.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/tags/repositories/category_repository.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:bandha/features/tags/repositories/label_repository.dart';
import 'package:bandha/features/pools/repositories/pool_repository.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:bandha/common/types/transaction_type.dart';
import 'package:bandha/features/tags/types/read_only_category.dart';

class PoolService extends Service {
  final PoolRepository poolRepository;
  final CategoryRepository categoryRepository;
  final EntryRepository entryRepository;
  final VaultRepository vaultRepository;
  final LabelRepository labelRepository;

  PoolService({
    required this.poolRepository,
    required this.categoryRepository,
    required this.entryRepository,
    required this.vaultRepository,
    required this.labelRepository,
  });

  sync(String id) {
    return poolRepository.sync(id);
  }

  retract(String id) {
    return work(() async {
      final now = DateTime.now();
      final category = await categoryRepository.getByName(ReadOnlyCategory.pool.label);
      final pool = await poolRepository.withVault().get(id);

      await poolRepository.save(pool.copyWith(releasedAt: null, status: PoolStatus.active));

      final entry = Entry.readOnly(
        note: "Retracted from ${pool.note}",
        amount: pool.balance * -1,
        status: EntryStatus.done,
        issuedAt: now,
        vaultId: pool.vaultId,
        categoryId: category.id,
      );

      await entryRepository.save(entry.controlledBy(pool));
      await vaultRepository.save(pool.vault.applyEntry(entry));
    });
  }

  release(String id) {
    return work(() async {
      final now = DateTime.now();
      final category = await categoryRepository.getByName(ReadOnlyCategory.pool.label);
      final pool = await poolRepository.withVault().get(id);
      await poolRepository.save(pool.copyWith(releasedAt: now, status: PoolStatus.released));

      final entry = Entry.readOnly(
        note: "Released from ${pool.note}",
        amount: pool.balance,
        status: EntryStatus.done,
        issuedAt: now,
        vaultId: pool.vaultId,
        categoryId: category.id,
      );

      await entryRepository.save(entry.controlledBy(pool));
      await vaultRepository.save(pool.vault.applyEntry(entry));
    });
  }

  Future<Pool> create({String? note, required double goal, required String vaultId, List<String>? labelIds}) async {
    return await work<Pool>(() async {
      final pool = Pool.create(note: note, goal: goal, balance: 0, vaultId: vaultId, status: PoolStatus.active);

      await poolRepository.save(pool);
      if (labelIds != null) {
        await poolRepository.saveLabels(pool.id, labelIds);
      }

      return pool;
    });
  }

  update(String id, {String? note, required double goal, List<String>? labelIds}) async {
    return await work(() async {
      final pool = await poolRepository.get(id);
      await poolRepository.save(pool.copyWith(note: note, goal: goal));
      if (labelIds != null) {
        await poolRepository.saveLabels(pool.id, labelIds);
      }
    });
  }

  delete(String id) {
    return work(() async {
      final pool = await poolRepository.withVault().get(id);
      final vault = pool.vault;
      await poolRepository.removeTransactions(pool);
      await poolRepository.delete(pool.id);
      await vaultRepository.sync(vault.id);
    });
  }

  search(Filter? specification) {
    return poolRepository.withLabels().withVault().search(specification);
  }

  get(String id) {
    return poolRepository.withLabels().withVault().get(id);
  }

  searchTransactions({required String poolId, Filter? specification}) {
    return entryRepository.withLabels().withVault().search({
      "pool_in": [poolId],
      ...?specification,
    });
  }

  createTransaction(
    String poolId, {
    required TransactionType type,
    required double amount,
    required DateTime issuedAt,
    List<String>? labelIds,
  }) async {
    return await work(() async {
      final category = await categoryRepository.getByName(ReadOnlyCategory.pool.label);
      final pool = await poolRepository.withLabels().withVault().get(poolId);

      final labels = <Label>[];

      if (pool.labels.isNotEmpty) {
        labels.addAll(pool.labels);
      }

      if (labelIds != null && labelIds.isNotEmpty) {
        labels.addAll(await labelRepository.getByIds(labelIds));
      }

      final entry = Entry.readOnly(
        note: Pool.entryNote(pool, type),
        amount: Pool.entryAmount(type, amount),
        status: EntryStatus.done,
        issuedAt: issuedAt,
        vaultId: pool.vaultId,
        categoryId: category.id,
      ).controlledBy(pool).withLabels(labels).withVault(pool.vault).withCategory(category);

      await entryRepository.save(entry);
      await entryRepository.saveLabels(entry.id, entry.labelIds);
      await vaultRepository.save(pool.vault.applyEntry(entry));
      await poolRepository.save(pool.applyEntry(entry));
      await poolRepository.saveTransaction(pool, entry);
    });
  }

  updateTransaction(
    String poolId,
    String entryId, {
    required TransactionType type,
    required double amount,
    required DateTime issuedAt,
    List<String>? labelIds,
  }) async {
    return await work(() async {
      final pool = await poolRepository.withVault().withLabels().get(poolId);
      final entry = await entryRepository.get(entryId);

      final newVault = pool.vault.revokeEntry(entry);
      final newPool = pool.revokeEntry(entry);
      final newLabels = <Label>[];

      if (pool.labels.isNotEmpty) newLabels.addAll(pool.labels);
      if (labelIds != null && labelIds.isNotEmpty) {
        newLabels.addAll(await labelRepository.getByIds(labelIds));
      }

      final newEntry = entry
          .copyWith(note: Pool.entryNote(newPool, type), amount: Pool.entryAmount(type, amount), issuedAt: issuedAt)
          .withVault(newVault)
          .withLabels(newLabels);

      await entryRepository.save(newEntry);
      await entryRepository.saveLabels(newEntry.id, newEntry.labelIds);
      await vaultRepository.save(newVault.applyEntry(newEntry));
      await poolRepository.save(newPool.applyEntry(newEntry));
    });
  }

  deleteTransaction({required String poolId, required String entryId}) async {
    return await work(() async {
      final pool = await poolRepository.withVault().get(poolId);
      final entry = await entryRepository.get(entryId);

      await vaultRepository.save(pool.vault.revokeEntry(entry));
      await poolRepository.save(pool.revokeEntry(entry));
      await entryRepository.delete(entry.id);
    });
  }
}
