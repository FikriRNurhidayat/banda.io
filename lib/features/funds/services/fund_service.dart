import 'package:banda/common/services/service.dart';
import 'package:banda/features/entries/entities/entry.dart';
import 'package:banda/features/funds/entities/fund.dart';
import 'package:banda/features/accounts/repositories/account_repository.dart';
import 'package:banda/features/tags/entities/label.dart';
import 'package:banda/features/tags/repositories/category_repository.dart';
import 'package:banda/features/entries/repositories/entry_repository.dart';
import 'package:banda/features/tags/repositories/label_repository.dart';
import 'package:banda/features/funds/repositories/fund_repository.dart';
import 'package:banda/common/types/specification.dart';
import 'package:banda/common/types/transaction_type.dart';
import 'package:banda/features/tags/types/read_only_category.dart';

class FundService extends Service {
  final FundRepository fundRepository;
  final CategoryRepository categoryRepository;
  final EntryRepository entryRepository;
  final AccountRepository accountRepository;
  final LabelRepository labelRepository;

  FundService({
    required this.fundRepository,
    required this.categoryRepository,
    required this.entryRepository,
    required this.accountRepository,
    required this.labelRepository,
  });

  sync(String id) {
    return fundRepository.sync(id);
  }

  retract(String id) {
    return work(() async {
      final now = DateTime.now();
      final category = await categoryRepository.getByName(ReadOnlyCategory.fund.label);
      final fund = await fundRepository.withAccount().get(id);

      await fundRepository.save(fund.copyWith(releasedAt: null, status: FundStatus.active));

      final entry = Entry.readOnly(
        note: "Retracted from ${fund.note}",
        amount: fund.balance * -1,
        status: EntryStatus.done,
        issuedAt: now,
        accountId: fund.accountId,
        categoryId: category.id,
      );

      await entryRepository.save(entry.controlledBy(fund));
      await accountRepository.save(fund.account.applyEntry(entry));
    });
  }

  release(String id) {
    return work(() async {
      final now = DateTime.now();
      final category = await categoryRepository.getByName(ReadOnlyCategory.fund.label);
      final fund = await fundRepository.withAccount().get(id);
      await fundRepository.save(fund.copyWith(releasedAt: now, status: FundStatus.released));

      final entry = Entry.readOnly(
        note: "Released from ${fund.note}",
        amount: fund.balance,
        status: EntryStatus.done,
        issuedAt: now,
        accountId: fund.accountId,
        categoryId: category.id,
      );

      await entryRepository.save(entry.controlledBy(fund));
      await accountRepository.save(fund.account.applyEntry(entry));
    });
  }

  Future<Fund> create({String? note, required double goal, required String accountId, List<String>? labelIds}) async {
    return await work<Fund>(() async {
      final fund = Fund.create(note: note, goal: goal, balance: 0, accountId: accountId, status: FundStatus.active);

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
      final fund = await fundRepository.withAccount().get(id);
      final account = fund.account;
      await fundRepository.removeTransactions(fund);
      await fundRepository.delete(fund.id);
      await accountRepository.sync(account.id);
    });
  }

  search(Filter? specification) {
    return fundRepository.withLabels().withAccount().search(specification);
  }

  get(String id) {
    return fundRepository.withLabels().withAccount().get(id);
  }

  searchTransactions({required String fundId, Filter? specification}) {
    return entryRepository.withLabels().withAccount().search({
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
      final fund = await fundRepository.withLabels().withAccount().get(fundId);

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
        accountId: fund.accountId,
        categoryId: category.id,
      ).controlledBy(fund).withLabels(labels).withAccount(fund.account).withCategory(category);

      await entryRepository.save(entry);
      await entryRepository.saveLabels(entry.id, entry.labelIds);
      await accountRepository.save(fund.account.applyEntry(entry));
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
      final fund = await fundRepository.withAccount().withLabels().get(fundId);
      final entry = await entryRepository.get(entryId);

      final newAccount = fund.account.revokeEntry(entry);
      final newFund = fund.revokeEntry(entry);
      final newLabels = <Label>[];

      if (fund.labels.isNotEmpty) newLabels.addAll(fund.labels);
      if (labelIds != null && labelIds.isNotEmpty) {
        newLabels.addAll(await labelRepository.getByIds(labelIds));
      }

      final newEntry = entry
          .copyWith(note: Fund.entryNote(newFund, type), amount: Fund.entryAmount(type, amount), issuedAt: issuedAt)
          .withAccount(newAccount)
          .withLabels(newLabels);

      await entryRepository.save(newEntry);
      await entryRepository.saveLabels(newEntry.id, newEntry.labelIds);
      await accountRepository.save(newAccount.applyEntry(newEntry));
      await fundRepository.save(newFund.applyEntry(newEntry));
    });
  }

  deleteTransaction({required String fundId, required String entryId}) async {
    return await work(() async {
      final fund = await fundRepository.withAccount().get(fundId);
      final entry = await entryRepository.get(entryId);

      await accountRepository.save(fund.account.revokeEntry(entry));
      await fundRepository.save(fund.revokeEntry(entry));
      await entryRepository.delete(entry.id);
    });
  }
}
