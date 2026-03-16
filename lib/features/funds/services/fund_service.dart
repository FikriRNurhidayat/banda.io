import 'package:bandha/common/services/service.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/funds/entities/fund.dart';
import 'package:bandha/features/vaults/repositories/vault_repository.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/tags/repositories/category_repository.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:bandha/features/tags/repositories/label_repository.dart';
import 'package:bandha/features/funds/repositories/fund_repository.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:bandha/common/types/transaction_type.dart';
import 'package:bandha/features/tags/types/read_only_category.dart';

class FundService extends Service {
  final FundRepository fundRepository;
  final CategoryRepository categoryRepository;
  final EntryRepository entryRepository;
  final VaultRepository vaultRepository;
  final LabelRepository labelRepository;

  FundService({
    required this.fundRepository,
    required this.categoryRepository,
    required this.entryRepository,
    required this.vaultRepository,
    required this.labelRepository,
  });

  sync(String id) {
    return fundRepository.sync(id);
  }

  retract(String id) {
    return work(() async {
      final now = DateTime.now();
      final category = await categoryRepository.getByName(ReadOnlyCategory.fund.label);
      final fund = await fundRepository.withVault().get(id);

      await fundRepository.save(fund.copyWith(releasedAt: null, status: FundStatus.active));

      final entry = Entry.readOnly(
        note: "Retracted from ${fund.note}",
        amount: fund.balance * -1,
        status: EntryStatus.done,
        issuedAt: now,
        vaultId: fund.vaultId,
        categoryId: category.id,
      );

      await entryRepository.save(entry.controlledBy(fund));
      await vaultRepository.save(fund.vault.applyEntry(entry));
    });
  }

  release(String id) {
    return work(() async {
      final now = DateTime.now();
      final category = await categoryRepository.getByName(ReadOnlyCategory.fund.label);
      final fund = await fundRepository.withVault().get(id);
      await fundRepository.save(fund.copyWith(releasedAt: now, status: FundStatus.released));

      final entry = Entry.readOnly(
        note: "Released from ${fund.note}",
        amount: fund.balance,
        status: EntryStatus.done,
        issuedAt: now,
        vaultId: fund.vaultId,
        categoryId: category.id,
      );

      await entryRepository.save(entry.controlledBy(fund));
      await vaultRepository.save(fund.vault.applyEntry(entry));
    });
  }

  Future<Fund> create({String? note, required double goal, required String vaultId, List<String>? labelIds}) async {
    return await work<Fund>(() async {
      final fund = Fund.create(note: note, goal: goal, balance: 0, vaultId: vaultId, status: FundStatus.active);

      await fundRepository.save(fund);
      if (labelIds != null) {
        await fundRepository.saveLabels(fund.id, labelIds);
      }

      return fund;
    });
  }

  update(String id, {String? note, required double goal, List<String>? labelIds}) async {
    return await work(() async {
      final fund = await fundRepository.get(id);
      await fundRepository.save(fund.copyWith(note: note, goal: goal));
      if (labelIds != null) {
        await fundRepository.saveLabels(fund.id, labelIds);
      }
    });
  }

  delete(String id) {
    return work(() async {
      final fund = await fundRepository.withVault().get(id);
      final vault = fund.vault;
      await fundRepository.removeTransactions(fund);
      await fundRepository.delete(fund.id);
      await vaultRepository.sync(vault.id);
    });
  }

  search(Filter? specification) {
    return fundRepository.withLabels().withVault().search(specification);
  }

  get(String id) {
    return fundRepository.withLabels().withVault().get(id);
  }

  searchTransactions({required String fundId, Filter? specification}) {
    return entryRepository.withLabels().withVault().search({
      "fund_in": [fundId],
      ...?specification,
    });
  }

  createTransaction(
    String fundId, {
    required TransactionType type,
    required double amount,
    required DateTime issuedAt,
    List<String>? labelIds,
  }) async {
    return await work(() async {
      final category = await categoryRepository.getByName(ReadOnlyCategory.fund.label);
      final fund = await fundRepository.withLabels().withVault().get(fundId);

      final labels = <Label>[];

      if (fund.labels.isNotEmpty) {
        labels.addAll(fund.labels);
      }

      if (labelIds != null && labelIds.isNotEmpty) {
        labels.addAll(await labelRepository.getByIds(labelIds));
      }

      final entry = Entry.readOnly(
        note: Fund.entryNote(fund, type),
        amount: Fund.entryAmount(type, amount),
        status: EntryStatus.done,
        issuedAt: issuedAt,
        vaultId: fund.vaultId,
        categoryId: category.id,
      ).controlledBy(fund).withLabels(labels).withVault(fund.vault).withCategory(category);

      await entryRepository.save(entry);
      await entryRepository.saveLabels(entry.id, entry.labelIds);
      await vaultRepository.save(fund.vault.applyEntry(entry));
      await fundRepository.save(fund.applyEntry(entry));
      await fundRepository.saveTransaction(fund, entry);
    });
  }

  updateTransaction(
    String fundId,
    String entryId, {
    required TransactionType type,
    required double amount,
    required DateTime issuedAt,
    List<String>? labelIds,
  }) async {
    return await work(() async {
      final fund = await fundRepository.withVault().withLabels().get(fundId);
      final entry = await entryRepository.get(entryId);

      final newVault = fund.vault.revokeEntry(entry);
      final newFund = fund.revokeEntry(entry);
      final newLabels = <Label>[];

      if (fund.labels.isNotEmpty) newLabels.addAll(fund.labels);
      if (labelIds != null && labelIds.isNotEmpty) {
        newLabels.addAll(await labelRepository.getByIds(labelIds));
      }

      final newEntry = entry
          .copyWith(note: Fund.entryNote(newFund, type), amount: Fund.entryAmount(type, amount), issuedAt: issuedAt)
          .withVault(newVault)
          .withLabels(newLabels);

      await entryRepository.save(newEntry);
      await entryRepository.saveLabels(newEntry.id, newEntry.labelIds);
      await vaultRepository.save(newVault.applyEntry(newEntry));
      await fundRepository.save(newFund.applyEntry(newEntry));
    });
  }

  deleteTransaction({required String fundId, required String entryId}) async {
    return await work(() async {
      final fund = await fundRepository.withVault().get(fundId);
      final entry = await entryRepository.get(entryId);

      await vaultRepository.save(fund.vault.revokeEntry(entry));
      await fundRepository.save(fund.revokeEntry(entry));
      await entryRepository.delete(entry.id);
    });
  }
}
