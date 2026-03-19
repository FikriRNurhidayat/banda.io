import 'package:bandha/common/services/service.dart';
import 'package:bandha/common/types/controller_type.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/pools/entities/pool.dart';
import 'package:bandha/features/tags/types/read_only_label.dart';
import 'package:bandha/features/vaults/repositories/vault_repository.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/tags/repositories/category_repository.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:bandha/features/tags/repositories/label_repository.dart';
import 'package:bandha/features/pools/repositories/pool_repository.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:bandha/common/types/transaction_type.dart';

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
      final pool = await poolRepository
          .withCategory()
          .withVault()
          .withLabels()
          .get(id);

      await poolRepository.save(
        pool.copyWith(releasedAt: null, status: PoolStatus.active),
      );

      final entry = Entry.readOnly(
        amount: pool.balance * -1,
        status: EntryStatus.done,
        issuedAt: now,
        vaultId: pool.vaultId,
        categoryId: pool.category.id,
      );

      await entryRepository.save(
        entry.controlledBy(pool).withLabels([
          await labelRepository.getByName(
            ReadOnlyLabel.retracted.label,
          ),
          ...pool.labels,
        ]),
      );
      await vaultRepository.save(pool.vault.applyEntry(entry));
    });
  }

  release(String id) {
    return work(() async {
      final now = DateTime.now();
      final pool = await poolRepository
          .withVault()
          .withLabels()
          .withCategory()
          .get(id);

      await poolRepository.save(
        pool.copyWith(releasedAt: now, status: PoolStatus.released),
      );

      final entry = Entry.readOnly(
        amount: pool.balance,
        status: EntryStatus.done,
        issuedAt: now,
        vaultId: pool.vaultId,
        categoryId: pool.category.id,
      );

      await entryRepository.save(
        entry.controlledBy(pool).withLabels([
          await labelRepository.getByName(ReadOnlyLabel.released.label),
          ...pool.labels,
        ]),
      );
      await vaultRepository.save(pool.vault.applyEntry(entry));
    });
  }

  Future<Pool> create({
    String? note,
    required double goal,
    required String categoryId,
    required String vaultId,
    List<String>? labelIds,
  }) async {
    return await work<Pool>(() async {
      final pool = Pool.create(
        note: note,
        goal: goal,
        balance: 0,
        categoryId: categoryId,
        vaultId: vaultId,
        status: PoolStatus.active,
      );

      await poolRepository.save(pool);
      if (labelIds != null) {
        await poolRepository.saveLabels(pool.id, labelIds);
      }

      return pool;
    });
  }

  update(
    String id, {
    String? note,
    required double goal,
    String? categoryId,
    List<String>? labelIds,
  }) async {
    return await work(() async {
      final ePool = await poolRepository.withLabels().get(id);
      final nPool = ePool.copyWith(
        note: note,
        goal: goal,
        categoryId: categoryId,
      );

      await poolRepository.save(nPool);

      final Iterable<(bool, String)> diffIds = ((labelIds != null)
          ? (ePool.labelIds
                .where((labelId) => !labelIds.contains(labelId))
                .map((labelId) => (false, labelId))
                .followedBy(labelIds.map((labelId) => (true, labelId))))
          : []);

      if (labelIds != null) {
        await poolRepository.saveLabels(ePool.id, labelIds);
      }

      await entryRepository.iterate(
        {
          "controller_id_is": ePool.id,
          "controller_type_is": ControllerType.pool.label,
        },
        (entry) async {
          await entryRepository.save(
            entry.copyWith(categoryId: nPool.categoryId),
          );

          if (diffIds.isNotEmpty) {
            await entryRepository.applyLabels(entry.id, diffIds);
          }
        },
      );
    });
  }

  delete(String id) {
    return work(() async {
      final pool = await poolRepository.withVault().get(id);
      final vault = pool.vault;
      await poolRepository.removeTransactions(pool);
      await poolRepository.delete(pool.id);
      await entryRepository.deleteByController(pool);
      await vaultRepository.sync(vault.id);
    });
  }

  search(Filter? specification) {
    return poolRepository
        .withLabels()
        .withVault()
        .withCategory()
        .search(specification);
  }

  get(String id) {
    return poolRepository.withLabels().withVault().get(id);
  }

  searchTransactions({required String poolId, Filter? specification}) {
    return entryRepository
        .withCategory()
        .withLabels()
        .withVault()
        .search({
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
      final pool = await poolRepository
          .withLabels()
          .withCategory()
          .withVault()
          .get(poolId);

      final labels = <Label>[
        await labelRepository.getByName(
          Pool.entryLabelName(pool, type),
        ),
      ];

      if (pool.labels.isNotEmpty) {
        labels.addAll(pool.labels);
      }

      if (labelIds != null && labelIds.isNotEmpty) {
        labels.addAll(await labelRepository.getByIds(labelIds));
      }

      final entry =
          Entry.readOnly(
                amount: Pool.entryAmount(type, amount),
                status: EntryStatus.done,
                issuedAt: issuedAt,
                vaultId: pool.vaultId,
                categoryId: pool.category.id,
              )
              .controlledBy(pool)
              .withLabels(labels)
              .withVault(pool.vault)
              .withCategory(pool.category);

      await entryRepository.save(entry);
      await entryRepository.saveLabels(entry.id, entry.labelIds);
      await vaultRepository.save(pool.vault.applyEntry(entry));

      if (!type.isDisbursement) {
        await poolRepository.save(pool.applyEntry(entry));
      }

      await poolRepository.saveTransaction(pool, type, entry);
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
      final pool = await poolRepository.withVault().withLabels().get(
        poolId,
      );
      final entry = await entryRepository.withLabels().get(entryId);
      final newVault = pool.vault.revokeEntry(entry);
      final newPool = !entry.isDisbursement
          ? pool.revokeEntry(entry)
          : pool;
      final newLabels = <Label>[
        await labelRepository.getByName(
          Pool.entryLabelName(pool, type),
        ),
      ];

      if (pool.labels.isNotEmpty) newLabels.addAll(pool.labels);
      if (labelIds != null && labelIds.isNotEmpty) {
        newLabels.addAll(await labelRepository.getByIds(labelIds));
      }

      final newEntry = entry
          .copyWith(
            amount: Pool.entryAmount(type, amount),
            issuedAt: issuedAt,
          )
          .withVault(newVault)
          .withLabels(newLabels);

      await entryRepository.save(newEntry);
      await entryRepository.saveLabels(newEntry.id, newEntry.labelIds);
      await vaultRepository.save(newVault.applyEntry(newEntry));
      if (type.isDisbursement) {
        await poolRepository.save(newPool.applyEntry(newEntry));
      }

      await poolRepository.saveTransaction(newPool, type, newEntry);
    });
  }

  deleteTransaction({
    required String poolId,
    required String entryId,
  }) async {
    return await work(() async {
      final pool = await poolRepository.withVault().get(poolId);
      final entry = await entryRepository.get(entryId);

      await vaultRepository.save(pool.vault.revokeEntry(entry));
      if (!entry.isDisbursement) {
        await poolRepository.save(pool.revokeEntry(entry));
      }
      await entryRepository.delete(entry.id);
    });
  }
}
