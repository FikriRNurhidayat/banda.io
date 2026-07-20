import 'package:bandha/common/services/service.dart';
import 'package:bandha/common/types/controller_type.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/funds/entities/fund.dart';
import 'package:bandha/features/tags/types/read_only_label.dart';
import 'package:bandha/features/journals/repositories/journal_repository.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/tags/repositories/category_repository.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:bandha/features/tags/repositories/label_repository.dart';
import 'package:bandha/features/funds/repositories/fund_repository.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:bandha/common/types/transaction_type.dart';

class FundService extends Service {
  final FundRepository fundRepository;
  final CategoryRepository categoryRepository;
  final EntryRepository entryRepository;
  final JournalRepository journalRepository;
  final LabelRepository labelRepository;

  FundService({
    required this.fundRepository,
    required this.categoryRepository,
    required this.entryRepository,
    required this.journalRepository,
    required this.labelRepository,
  });

  sync(String id) {
    return fundRepository.sync(id);
  }

  retract(String id) {
    return work(() async {
      final now = DateTime.now();
      final fund = await fundRepository
          .withCategory()
          .withJournal()
          .withLabels()
          .get(id);

      await fundRepository.save(
        fund.copyWith(releasedAt: null, status: FundStatus.active),
      );

      final entry = Entry.readOnly(
        amount: fund.balance * -1,
        status: EntryStatus.done,
        issuedAt: now,
        journalId: fund.journalId,
        categoryId: fund.category.id,
      );

      await entryRepository.save(
        entry.controlledBy(fund).withLabels([
          await labelRepository.getByName(
            ReadOnlyLabel.retracted.label,
          ),
          ...fund.labels,
        ]),
      );
      await journalRepository.save(fund.journal.applyEntry(entry));
    });
  }

  release(String id) {
    return work(() async {
      final now = DateTime.now();
      final fund = await fundRepository
          .withJournal()
          .withLabels()
          .withCategory()
          .get(id);

      await fundRepository.save(
        fund.copyWith(releasedAt: now, status: FundStatus.released),
      );

      final entry = Entry.readOnly(
        amount: fund.balance,
        status: EntryStatus.done,
        issuedAt: now,
        journalId: fund.journalId,
        categoryId: fund.category.id,
      );

      await entryRepository.save(
        entry.controlledBy(fund).withLabels([
          await labelRepository.getByName(ReadOnlyLabel.released.label),
          ...fund.labels,
        ]),
      );
      await journalRepository.save(fund.journal.applyEntry(entry));
    });
  }

  Future<Fund> create({
    String? note,
    required double amount,
    required String categoryId,
    required String journalId,
    List<String>? labelIds,
  }) async {
    return await work<Fund>(() async {
      final fund = Fund.create(
        note: note,
        amount: amount,
        balance: 0,
        categoryId: categoryId,
        journalId: journalId,
        status: FundStatus.active,
      );

      await fundRepository.save(fund);
      if (labelIds != null) {
        await fundRepository.saveLabels(fund.id, labelIds);
      }

      return fund;
    });
  }

  update(
    String id, {
    String? note,
    required double amount,
    String? categoryId,
    List<String>? labelIds,
  }) async {
    return await work(() async {
      final eFund = await fundRepository.withLabels().get(id);
      final nFund = eFund.copyWith(
        note: note,
        amount: amount,
        categoryId: categoryId,
      );

      await fundRepository.save(nFund);

      final Iterable<(bool, String)> diffIds = ((labelIds != null)
          ? (eFund.labelIds
                .where((labelId) => !labelIds.contains(labelId))
                .map((labelId) => (false, labelId))
                .followedBy(labelIds.map((labelId) => (true, labelId))))
          : []);

      if (labelIds != null) {
        await fundRepository.saveLabels(eFund.id, labelIds);
      }

      await entryRepository.iterate(
        {
          "controller_id_is": eFund.id,
          "controller_type_is": ControllerType.fund.label,
        },
        (entry) async {
          await entryRepository.save(
            entry.copyWith(categoryId: nFund.categoryId),
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
      final fund = await fundRepository.withJournal().get(id);
      final journal = fund.journal;
      await fundRepository.removeTransactions(fund);
      await fundRepository.delete(fund.id);
      await entryRepository.deleteByController(fund);
      await journalRepository.sync(journal.id);
    });
  }

  search(Filter? specification) {
    return fundRepository
        .withLabels()
        .withJournal()
        .withCategory()
        .search(specification);
  }

  get(String id) {
    return fundRepository.withLabels().withJournal().get(id);
  }

  searchTransactions({required String fundId, Filter? specification}) {
    return entryRepository
        .withCategory()
        .withLabels()
        .withJournal()
        .search({
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
      final fund = await fundRepository
          .withLabels()
          .withCategory()
          .withJournal()
          .get(fundId);

      final labels = <Label>[
        await labelRepository.getByName(
          Fund.entryLabelName(fund, type),
        ),
      ];

      if (fund.labels.isNotEmpty) {
        labels.addAll(fund.labels);
      }

      if (labelIds != null && labelIds.isNotEmpty) {
        labels.addAll(await labelRepository.getByIds(labelIds));
      }

      final entry =
          Entry.readOnly(
                amount: Fund.entryAmount(type, amount),
                status: EntryStatus.done,
                issuedAt: issuedAt,
                journalId: fund.journalId,
                categoryId: fund.category.id,
              )
              .controlledBy(fund)
              .withLabels(labels)
              .withJournal(fund.journal)
              .withCategory(fund.category);

      await entryRepository.save(entry);
      await entryRepository.saveLabels(entry.id, entry.labelIds);
      await journalRepository.save(fund.journal.applyEntry(entry));

      if (!type.isDisbursement) {
        await fundRepository.save(fund.applyEntry(entry));
      }

      await fundRepository.saveTransaction(fund, type, entry);
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
      final fund = await fundRepository.withJournal().withLabels().get(
        fundId,
      );
      final entry = await entryRepository.withLabels().get(entryId);
      final newJournal = fund.journal.revokeEntry(entry);
      final newFund = !entry.isDisbursement
          ? fund.revokeEntry(entry)
          : fund;
      final newLabels = <Label>[
        await labelRepository.getByName(
          Fund.entryLabelName(fund, type),
        ),
      ];

      if (fund.labels.isNotEmpty) newLabels.addAll(fund.labels);
      if (labelIds != null && labelIds.isNotEmpty) {
        newLabels.addAll(await labelRepository.getByIds(labelIds));
      }

      final newEntry = entry
          .copyWith(
            amount: Fund.entryAmount(type, amount),
            issuedAt: issuedAt,
          )
          .withJournal(newJournal)
          .withLabels(newLabels);

      await entryRepository.save(newEntry);
      await entryRepository.saveLabels(newEntry.id, newEntry.labelIds);
      await journalRepository.save(newJournal.applyEntry(newEntry));
      if (type.isDisbursement) {
        await fundRepository.save(newFund.applyEntry(newEntry));
      }

      await fundRepository.saveTransaction(newFund, type, newEntry);
    });
  }

  deleteTransaction({
    required String fundId,
    required String entryId,
  }) async {
    return await work(() async {
      final fund = await fundRepository.withJournal().get(fundId);
      final entry = await entryRepository.get(entryId);

      await journalRepository.save(fund.journal.revokeEntry(entry));
      if (!entry.isDisbursement) {
        await fundRepository.save(fund.revokeEntry(entry));
      }
      await entryRepository.delete(entry.id);
    });
  }
}
