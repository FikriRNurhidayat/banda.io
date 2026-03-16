import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/common/services/service.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:bandha/features/schedules/entities/schedule.dart';
import 'package:bandha/features/schedules/repositories/schedule_repository.dart';
import 'package:bandha/features/tags/repositories/category_repository.dart';
import 'package:bandha/features/tags/repositories/label_repository.dart';
import 'package:bandha/features/tags/types/read_only_label.dart';
import 'package:bandha/features/vaults/repositories/vault_repository.dart';

class ScheduleService extends Service {
  final VaultRepository vaultRepository;
  final ScheduleRepository scheduleRepository;
  final CategoryRepository categoryRepository;
  final EntryRepository entryRepository;
  final LabelRepository labelRepository;

  ScheduleService({
    required this.vaultRepository,
    required this.scheduleRepository,
    required this.categoryRepository,
    required this.entryRepository,
    required this.labelRepository,
  });

  create({
    String? note,
    required double amount,
    double? fee,
    required EntryType type,
    required ScheduleCycle cycle,
    required ScheduleStatus status,
    required DateTime dueAt,
    required String categoryId,
    required String vaultId,
    required List<String> labelIds,
  }) {
    return work(() async {
      final category = await categoryRepository.get(categoryId);
      var vault = await vaultRepository.get(vaultId);
      final labels = await labelRepository.getByIds(labelIds);
      final feeLabel = await labelRepository.getByName(
        ReadOnlyLabel.fee.label,
      );
      final sign = (type.isIncome ? 1 : -1);

      var entry =
          Entry.readOnly(
                amount: amount * sign,
                status: status.entryStatus,
                issuedAt: dueAt,
                vaultId: vault.id,
                categoryId: category.id,
              )
              .withCategory(category)
              .withVault(vault)
              .withLabels(labels)
              .annotate("iteration", 1);

      final addition = fee != null
          ? Entry.readOnly(
                  amount: fee * sign,
                  status: status.entryStatus,
                  issuedAt: dueAt,
                  vaultId: vault.id,
                  categoryId: category.id,
                )
                .withCategory(category)
                .withVault(vault)
                .withLabels([...labels, feeLabel])
                .annotate("entry_id", entry.id)
                .annotate("iteration", 1)
          : null;

      if (addition != null) {
        entry = entry.annotate("addition_id", addition.id);
      }

      final schedule =
          Schedule.create(
                note: note,
                amount: amount * sign,
                fee: fee != null ? fee * sign : null,
                cycle: cycle,
                status: status,
                categoryId: category.id,
                vaultId: vault.id,
                entryId: entry.id,
                additionId: addition?.id,
                dueAt: dueAt,
              )
              .withLabels(labels)
              .withEntry(entry)
              .withAddition(addition)
              .withVault(vault)
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
        await vaultRepository.save(
          schedule.vault.applyEntries(schedule.entries),
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
    required EntryType type,
    required ScheduleCycle cycle,
    required ScheduleStatus status,
    required DateTime dueAt,
    required String categoryId,
    required String vaultId,
    required List<String> labelIds,
  }) {
    return work(() async {
      var schedule = await scheduleRepository
          .withLabels()
          .withVault()
          .withEntries()
          .withCategory()
          .get(id);

      if (schedule == null) {
        return null;
      }

      if (schedule.status.isPaid) {
        await vaultRepository.save(
          schedule.vault.revokeEntries(schedule.entries),
        );
      }

      final category = await categoryRepository.get(categoryId);
      var vault = await vaultRepository.get(vaultId);
      final labels = await labelRepository.getByIds(labelIds);
      final feeLabel = await labelRepository.getByName(
        ReadOnlyLabel.fee.label,
      );

      final sign = type.isIncome ? 1 : -1;

      var entry = schedule.entry
          .copyWith(
            amount: amount * sign,
            status: status.entryStatus,
            issuedAt: dueAt,
            vaultId: vault.id,
            categoryId: category.id,
          )
          .withCategory(category)
          .withVault(vault)
          .withLabels(labels);

      final additionId = schedule.additionId;
      final additionRemoved = schedule.hasAddition && isZero(fee);
      final addition = fee != null
          ? (schedule.hasAddition
                    ? schedule.addition!.copyWith(
                        amount: fee * sign,
                        status: status.entryStatus,
                        issuedAt: dueAt,
                        vaultId: vault.id,
                        categoryId: category.id,
                      )
                    : Entry.readOnly(
                        amount: fee * sign,
                        status: status.entryStatus,
                        issuedAt: dueAt,
                        vaultId: vault.id,
                        categoryId: category.id,
                      ))
                .withCategory(category)
                .withVault(vault)
                .withLabels([...labels, feeLabel])
                .annotate("entry_id", entry.id)
          : null;

      if (addition != null) {
        entry = entry.annotate("addition_id", addition.id);
      }

      schedule = schedule.copyWith(
        note: note,
        amount: amount * sign,
        cycle: cycle,
        status: status,
        categoryId: category.id,
        vaultId: vault.id,
        entryId: entry.id,
        dueAt: dueAt,
      );

      schedule = schedule
          .withNote(note)
          .withFee(fee != null ? fee * sign : fee)
          .withAdditionId(addition?.id)
          .withLabels(labels)
          .withEntry(entry)
          .withAddition(addition)
          .withVault(vault)
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
        await vaultRepository.save(
          schedule.vault.applyEntries(schedule.entries),
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
        .withVault()
        .withLabels()
        .get(id);
  }

  Future<List<Schedule>> search() async {
    return await scheduleRepository
        .withCategory()
        .withLabels()
        .withVault()
        .search();
  }

  delete(String id) {
    return work(() async {
      var schedule = await scheduleRepository.get(id);

      if (schedule == null) {
        return null;
      }

      await scheduleRepository.delete(schedule.id);

      final entries = await entryRepository.withVault().controlledBy(schedule);
      final entryIds = entries.map((entry) => entry.id).toList();
      final vaults = entries
          .map((entry) => entry.vault)
          .toSet()
          .map(
            (vault) => vault.revokeEntries(
              entries.where((entry) => vault == entry.vault),
            ),
          );

      await vaultRepository.bulkSave(vaults);
      await entryRepository.deleteByIds(entryIds);
    });
  }

  rollback(String id) async {
    return work(() async {
      var schedule = await scheduleRepository
          .withLabels()
          .withVault()
          .withCategory()
          .withEntries()
          .get(id);

      if (schedule == null) {
        return null;
      }

      if (!schedule.canRollback) {
        return null;
      }

      var vault = schedule.vault;
      final entry = schedule.entry;
      final iteration = schedule.iteration - 1;

      if (entry.annotations == null ||
          !entry.annotations!.containsKey("previous_id")) {
        return null;
      }

      if (schedule.status.isPaid) {
        vault = vault.revokeEntries(schedule.entries);
        await vaultRepository.save(vault);
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
          .withVault()
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
                vaultId: schedule.vaultId,
                categoryId: schedule.categoryId,
              )
              .controlledBy(schedule)
              .withLabels(schedule.labels)
              .withVault(schedule.vault)
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
                  vaultId: schedule.vaultId,
                  categoryId: schedule.categoryId,
                )
                .controlledBy(schedule)
                .withLabels([...schedule.labels, feeLabel])
                .withVault(schedule.vault)
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
          .withVault(schedule.vault)
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
