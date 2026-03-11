import 'package:banda/common/helpers/type_helper.dart';
import 'package:banda/common/services/service.dart';
import 'package:banda/features/accounts/repositories/account_repository.dart';
import 'package:banda/features/bills/entities/bill.dart';
import 'package:banda/features/bills/repositories/bill_repository.dart';
import 'package:banda/features/entries/entities/entry.dart';
import 'package:banda/features/entries/repositories/entry_repository.dart';
import 'package:banda/features/tags/repositories/category_repository.dart';
import 'package:banda/features/tags/repositories/label_repository.dart';
import 'package:banda/features/tags/types/read_only_label.dart';

class BillService extends Service {
  final AccountRepository accountRepository;
  final BillRepository billRepository;
  final CategoryRepository categoryRepository;
  final EntryRepository entryRepository;
  final LabelRepository labelRepository;

  BillService({
    required this.accountRepository,
    required this.billRepository,
    required this.categoryRepository,
    required this.entryRepository,
    required this.labelRepository,
  });

  create({
    String? note,
    required double amount,
    double? fee,
    required BillCycle cycle,
    required BillStatus status,
    required DateTime dueAt,
    required String categoryId,
    required String accountId,
    required List<String> labelIds,
  }) {
    return work(() async {
      final category = await categoryRepository.get(categoryId);
      var account = await accountRepository.get(accountId);
      final labels = await labelRepository.getByIds(labelIds);
      final feeLabel = await labelRepository.getByName(ReadOnlyLabel.fee.label);

      var entry = Entry.readOnly(
        amount: amount * -1,
        status: status.entryStatus,
        issuedAt: dueAt,
        accountId: account.id,
        categoryId: category.id,
      ).withCategory(category).withAccount(account).withLabels(labels).annotate("iteration", 1);

      final addition = fee != null
          ? Entry.readOnly(
                  amount: fee * -1,
                  status: status.entryStatus,
                  issuedAt: dueAt,
                  accountId: account.id,
                  categoryId: category.id,
                )
                .withCategory(category)
                .withAccount(account)
                .withLabels([...labels, feeLabel])
                .annotate("entry_id", entry.id)
                .annotate("iteration", 1)
          : null;

      if (addition != null) entry = entry.annotate("addition_id", addition.id);

      final bill = Bill.create(
        note: note,
        amount: amount,
        fee: fee,
        cycle: cycle,
        status: status,
        categoryId: category.id,
        accountId: account.id,
        entryId: entry.id,
        additionId: addition?.id,
        dueAt: dueAt,
      ).withLabels(labels).withEntry(entry).withAddition(addition).withAccount(account).withCategory(category);

      await entryRepository.withLabels().withAnnotations().bulkSave(
        bill.entries.map((entry) => entry.controlledBy(bill).withLabels(entry.labels).withAnnotations(entry.annotations)),
      );

      if (bill.status.isPaid) {
        await accountRepository.save(bill.account.applyEntries(bill.entries));
      }

      await billRepository.save(bill);
      await billRepository.saveLabels(bill);

      return bill;
    });
  }

  update(
    String id, {
    String? note,
    required double amount,
    double? fee,
    required BillCycle cycle,
    required BillStatus status,
    required DateTime dueAt,
    required String categoryId,
    required String accountId,
    required List<String> labelIds,
  }) {
    return work(() async {
      var bill = await billRepository.withLabels().withAccount().withEntries().withCategory().get(id);

      if (bill == null) {
        return null;
      }

      if (bill.status.isPaid) {
        await accountRepository.save(bill.account.revokeEntries(bill.entries));
      }

      final category = await categoryRepository.get(categoryId);
      var account = await accountRepository.get(accountId);
      final labels = await labelRepository.getByIds(labelIds);
      final feeLabel = await labelRepository.getByName(ReadOnlyLabel.fee.label);

      var entry = bill.entry
          .copyWith(
            amount: amount * -1,
            status: status.entryStatus,
            issuedAt: dueAt,
            accountId: account.id,
            categoryId: category.id,
          )
          .withCategory(category)
          .withAccount(account)
          .withLabels(labels);

      final additionId = bill.additionId;
      final additionRemoved = bill.hasAddition && isZero(fee);
      final addition = fee != null
          ? (bill.hasAddition
                    ? bill.addition!.copyWith(
                        amount: fee * -1,
                        status: status.entryStatus,
                        issuedAt: dueAt,
                        accountId: account.id,
                        categoryId: category.id,
                      )
                    : Entry.readOnly(
                        amount: fee * -1,
                        status: status.entryStatus,
                        issuedAt: dueAt,
                        accountId: account.id,
                        categoryId: category.id,
                      ))
                .withCategory(category)
                .withAccount(account)
                .withLabels([...labels, feeLabel])
                .annotate("entry_id", entry.id)
          : null;

      if (addition != null) {
        entry = entry.annotate("addition_id", addition.id);
      }

      bill = bill.copyWith(
        note: note,
        amount: amount,
        cycle: cycle,
        status: status,
        categoryId: category.id,
        accountId: account.id,
        entryId: entry.id,
        dueAt: dueAt,
      );

      bill = bill
          .withNote(note)
          .withFee(fee)
          .withAdditionId(addition?.id)
          .withLabels(labels)
          .withEntry(entry)
          .withAddition(addition)
          .withAccount(account)
          .withCategory(category);

      for (var entry in bill.entries) {
        await entryRepository.save(entry.controlledBy(bill));
        await entryRepository.saveLabels(entry.id, entry.labelIds);
        await entryRepository.saveAnnotations(entry.id, entry.annotations);
      }

      if (bill.status.isPaid) {
        await accountRepository.save(bill.account.applyEntries(bill.entries));
      }

      await billRepository.save(bill);
      await billRepository.saveLabels(bill);

      if (additionRemoved) {
        await entryRepository.delete(additionId!);
      }

      return bill;
    });
  }

  Future<Bill?> get(String id) async {
    return await billRepository.withCategory().withEntries().withAccount().withLabels().get(id);
  }

  Future<List<Bill>> search() async {
    return await billRepository.withCategory().withLabels().withAccount().search();
  }

  delete(String id) {
    return work(() async {
      var bill = await billRepository.get(id);

      if (bill == null) {
        return null;
      }

      await billRepository.delete(bill.id);

      final entries = await entryRepository.controlledBy(bill);
      final accounts = entries
          .map((entry) => entry.account)
          .toSet()
          .map((account) => account.revokeEntries(entries.where((entry) => account == entry.account)));

      await accountRepository.bulkSave(accounts);
    });
  }

  rollback(String id) async {
    return work(() async {
      var bill = await billRepository.withLabels().withAccount().withCategory().withEntries().get(id);

      if (bill == null) {
        return null;
      }

      if (!bill.canRollback) {
        return null;
      }

      var account = bill.account;
      final entry = bill.entry;
      final iteration = bill.iteration - 1;

      if (entry.annotations == null || !entry.annotations!.containsKey("previous_id")) {
        return null;
      }

      if (bill.status.isPaid) {
        account = account.revokeEntries(bill.entries);
        await accountRepository.save(account);
      }

      final previousEntry = await entryRepository.withAnnotations().get(entry.annotations!["previous_id"]);

      final additionId = previousEntry.annotations!["addition_id"];

      await billRepository.save(
        bill
            .copyWith(iteration: iteration, entryId: previousEntry.id, status: BillStatus.paid, dueAt: bill.previousTime)
            .withAdditionId(additionId),
      );
      await entryRepository.deleteByIds(bill.entryIds);
    });
  }

  rollover(String id) async {
    return work(() async {
      var bill = await billRepository.withLabels().withAccount().withCategory().withEntries().get(id);

      if (bill == null) {
        return null;
      }

      if (!bill.status.isPaid) {
        return null;
      }

      final iteration = bill.iteration + 1;
      final feeLabel = await labelRepository.getByName(ReadOnlyLabel.fee.label);

      var newEntry =
          Entry.readOnly(
                amount: bill.amount * -1,
                status: EntryStatus.pending,
                issuedAt: bill.nextTime,
                accountId: bill.accountId,
                categoryId: bill.categoryId,
              )
              .controlledBy(bill)
              .withLabels(bill.labels)
              .withAccount(bill.account)
              .withCategory(bill.category)
              .annotate("previous_id", bill.entryId)
              .annotate("iteration", iteration);

      final entry = bill.entry.annotate("next_id", newEntry.id);
      final addition = bill.additionId != null ? bill.addition!.annotate("next_id", newEntry.id) : null;

      final newAddition = bill.fee != null
          ? Entry.readOnly(
                  amount: bill.fee! * -1,
                  status: EntryStatus.pending,
                  issuedAt: bill.nextTime,
                  accountId: bill.accountId,
                  categoryId: bill.categoryId,
                )
                .controlledBy(bill)
                .withLabels([...bill.labels, feeLabel])
                .withAccount(bill.account)
                .withCategory(bill.category)
                .annotate("previous_id", bill.entryId)
                .annotate("entry_id", bill.entryId)
                .annotate("iteration", iteration)
          : null;

      if (newAddition != null) {
        newEntry = newEntry.annotate("addition_id", newAddition.id);
      }

      bill = bill
          .copyWith(
            status: BillStatus.pending,
            entryId: newEntry.id,
            iteration: iteration,
            additionId: newAddition?.id,
            dueAt: bill.nextTime,
          )
          .withCategory(bill.category)
          .withAccount(bill.account)
          .withLabels(bill.labels)
          .withEntry(newEntry)
          .withAddition(newAddition);

      final entries = [entry, addition].whereType<Entry>();
      final newEntries = [newEntry, newAddition].whereType<Entry>();

      await entryRepository.withAnnotations().bulkSave(entries);
      await entryRepository.withLabels().withAnnotations().bulkSave(newEntries);

      await billRepository.save(bill);
    });
  }
}
