import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/common/services/service.dart';
import 'package:bandha/features/accounts/repositories/account_repository.dart';
import 'package:bandha/features/schedules/entities/schedule.dart';
import 'package:bandha/features/schedules/repositories/schedule_repository.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:bandha/features/tags/repositories/category_repository.dart';
import 'package:bandha/features/tags/repositories/label_repository.dart';
import 'package:bandha/features/tags/types/read_only_label.dart';

class ScheduleService extends Service {
  final AccountRepository accountRepository;
  final ScheduleRepository scheduleRepository;
  final CategoryRepository categoryRepository;
  final EntryRepository entryRepository;
  final LabelRepository labelRepository;

  ScheduleService({
    required this.accountRepository,
    required this.scheduleRepository,
    required this.categoryRepository,
    required this.entryRepository,
    required this.labelRepository,
  });

  create({
    String? note,
    required double amount,
    double? fee,
    required ScheduleCycle cycle,
    required ScheduleStatus status,
    required DateTime dueAt,
    required String categoryId,
    required String accountId,
    required List<String> labelIds,
  }) {
    return work(() async {
      final category = await categoryRepository.get(categoryId);
      var account = await accountRepository.get(accountId);
      final labels = await labelRepository.getByIds(labelIds);
      final feeLabel = await labelRepository.getByName(
        ReadOnlyLabel.fee.label,
      );

      var entry =
          Entry.readOnly(
                amount: amount,
                status: status.entryStatus,
                issuedAt: dueAt,
                accountId: account.id,
                categoryId: category.id,
              )
              .withCategory(category)
              .withAccount(account)
              .withLabels(labels)
              .annotate("iteration", 1);

      final addition = fee != null
          ? Entry.readOnly(
                  amount: fee,
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

      if (addition != null)
        entry = entry.annotate("addition_id", addition.id);

      final schedule =
          Schedule.create(
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
              )
              .withLabels(labels)
              .withEntry(entry)
              .withAddition(addition)
              .withAccount(account)
              .withCategory(category);

      await entryRepository.withLabels().withAnnotations().bulkSave(
        schedule.entries.map(
          (entry) => entry
              .controlledBy(schedule)
              .withLabels(entry.labels)
              .withAnnotations(entry.annotations),
        ),
      );

      if (schedule.status.isPaid) {
        await accountRepository.save(
          schedule.account.applyEntries(schedule.entries),
        );
      }

      await scheduleRepository.save(schedule);
      await scheduleRepository.saveLabels(schedule);

      return schedule;
    });
  }

  update(
    String id, {
    String? note,
    required double amount,
    double? fee,
    required ScheduleCycle cycle,
    required ScheduleStatus status,
    required DateTime dueAt,
    required String categoryId,
    required String accountId,
    required List<String> labelIds,
  }) {
    return work(() async {
      var schedule = await scheduleRepository
          .withLabels()
          .withAccount()
          .withEntries()
          .withCategory()
          .get(id);

      if (schedule == null) {
        return null;
      }

      if (schedule.status.isPaid) {
        await accountRepository.save(
          schedule.account.revokeEntries(schedule.entries),
        );
      }

      final category = await categoryRepository.get(categoryId);
      var account = await accountRepository.get(accountId);
      final labels = await labelRepository.getByIds(labelIds);
      final feeLabel = await labelRepository.getByName(
        ReadOnlyLabel.fee.label,
      );

      var entry = schedule.entry
          .copyWith(
            amount: amount,
            status: status.entryStatus,
            issuedAt: dueAt,
            accountId: account.id,
            categoryId: category.id,
          )
          .withCategory(category)
          .withAccount(account)
          .withLabels(labels);

      final additionId = schedule.additionId;
      final additionRemoved = schedule.hasAddition && isZero(fee);
      final addition = fee != null
          ? (schedule.hasAddition
                    ? schedule.addition!.copyWith(
                        amount: fee,
                        status: status.entryStatus,
                        issuedAt: dueAt,
                        accountId: account.id,
                        categoryId: category.id,
                      )
                    : Entry.readOnly(
                        amount: fee,
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

      schedule = schedule.copyWith(
        note: note,
        amount: amount,
        cycle: cycle,
        status: status,
        categoryId: category.id,
        accountId: account.id,
        entryId: entry.id,
        dueAt: dueAt,
      );

      schedule = schedule
          .withNote(note)
          .withFee(fee)
          .withAdditionId(addition?.id)
          .withLabels(labels)
          .withEntry(entry)
          .withAddition(addition)
          .withAccount(account)
          .withCategory(category);

      for (var entry in schedule.entries) {
        await entryRepository.save(entry.controlledBy(schedule));
        await entryRepository.saveLabels(entry.id, entry.labelIds);
        await entryRepository.saveAnnotations(
          entry.id,
          entry.annotations,
        );
      }

      if (schedule.status.isPaid) {
        await accountRepository.save(
          schedule.account.applyEntries(schedule.entries),
        );
      }

      await scheduleRepository.save(schedule);
      await scheduleRepository.saveLabels(schedule);

      if (additionRemoved) {
        await entryRepository.delete(additionId!);
      }

      return schedule;
    });
  }

  Future<Schedule?> get(String id) async {
    return await scheduleRepository
        .withCategory()
        .withEntries()
        .withAccount()
        .withLabels()
        .get(id);
  }

  Future<List<Schedule>> search() async {
    return await scheduleRepository
        .withCategory()
        .withLabels()
        .withAccount()
        .search();
  }

  delete(String id) {
    return work(() async {
      var schedule = await scheduleRepository.get(id);

      if (schedule == null) {
        return null;
      }

      await scheduleRepository.delete(schedule.id);

      final entries = await entryRepository.controlledBy(schedule);
      final accounts = entries
          .map((entry) => entry.account)
          .toSet()
          .map(
            (account) => account.revokeEntries(
              entries.where((entry) => account == entry.account),
            ),
          );

      await accountRepository.bulkSave(accounts);
    });
  }

  rollback(String id) async {
    return work(() async {
      var schedule = await scheduleRepository
          .withLabels()
          .withAccount()
          .withCategory()
          .withEntries()
          .get(id);

      if (schedule == null) {
        return null;
      }

      if (!schedule.canRollback) {
        return null;
      }

      var account = schedule.account;
      final entry = schedule.entry;
      final iteration = schedule.iteration - 1;

      if (entry.annotations == null ||
          !entry.annotations!.containsKey("previous_id")) {
        return null;
      }

      if (schedule.status.isPaid) {
        account = account.revokeEntries(schedule.entries);
        await accountRepository.save(account);
      }

      final previousEntry = await entryRepository.withAnnotations().get(
        entry.annotations!["previous_id"],
      );

      final additionId = previousEntry.annotations!["addition_id"];

      await scheduleRepository.save(
        schedule
            .copyWith(
              iteration: iteration,
              entryId: previousEntry.id,
              status: ScheduleStatus.paid,
              dueAt: schedule.previousTime,
            )
            .withAdditionId(additionId),
      );
      await entryRepository.deleteByIds(schedule.entryIds);
    });
  }

  rollover(String id) async {
    return work(() async {
      var schedule = await scheduleRepository
          .withLabels()
          .withAccount()
          .withCategory()
          .withEntries()
          .get(id);

      if (schedule == null) {
        return null;
      }

      if (!schedule.status.isPaid) {
        return null;
      }

      final iteration = schedule.iteration + 1;
      final feeLabel = await labelRepository.getByName(
        ReadOnlyLabel.fee.label,
      );

      var newEntry =
          Entry.readOnly(
                amount: schedule.amount,
                status: EntryStatus.pending,
                issuedAt: schedule.nextTime,
                accountId: schedule.accountId,
                categoryId: schedule.categoryId,
              )
              .controlledBy(schedule)
              .withLabels(schedule.labels)
              .withAccount(schedule.account)
              .withCategory(schedule.category)
              .annotate("previous_id", schedule.entryId)
              .annotate("iteration", iteration);

      final entry = schedule.entry.annotate("next_id", newEntry.id);
      final addition = schedule.additionId != null
          ? schedule.addition!.annotate("next_id", newEntry.id)
          : null;

      final newAddition = schedule.fee != null
          ? Entry.readOnly(
                  amount: schedule.fee!,
                  status: EntryStatus.pending,
                  issuedAt: schedule.nextTime,
                  accountId: schedule.accountId,
                  categoryId: schedule.categoryId,
                )
                .controlledBy(schedule)
                .withLabels([...schedule.labels, feeLabel])
                .withAccount(schedule.account)
                .withCategory(schedule.category)
                .annotate("previous_id", schedule.entryId)
                .annotate("entry_id", schedule.entryId)
                .annotate("iteration", iteration)
          : null;

      if (newAddition != null) {
        newEntry = newEntry.annotate("addition_id", newAddition.id);
      }

      schedule = schedule
          .copyWith(
            status: ScheduleStatus.pending,
            entryId: newEntry.id,
            iteration: iteration,
            additionId: newAddition?.id,
            dueAt: schedule.nextTime,
          )
          .withCategory(schedule.category)
          .withAccount(schedule.account)
          .withLabels(schedule.labels)
          .withEntry(newEntry)
          .withAddition(newAddition);

      final entries = [entry, addition].whereType<Entry>();
      final newEntries = [newEntry, newAddition].whereType<Entry>();

      await entryRepository.withAnnotations().bulkSave(entries);
      await entryRepository.withLabels().withAnnotations().bulkSave(
        newEntries,
      );

      await scheduleRepository.save(schedule);
    });
  }
}
