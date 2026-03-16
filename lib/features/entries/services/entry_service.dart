import 'package:bandha/common/services/service.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/notifications/managers/notification_manager.dart';
import 'package:bandha/features/accounts/repositories/account_repository.dart';
import 'package:bandha/features/tags/repositories/category_repository.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:bandha/features/tags/repositories/label_repository.dart';
import 'package:bandha/common/types/controller.dart';
import 'package:bandha/common/types/notification_action.dart';
import 'package:bandha/common/types/specification.dart';

class EntryService extends Service {
  final EntryRepository entryRepository;
  final AccountRepository accountRepository;
  final LabelRepository labelRepository;
  final CategoryRepository categoryRepository;
  final NotificationManager notificationManager;

  EntryService({
    required this.entryRepository,
    required this.accountRepository,
    required this.labelRepository,
    required this.categoryRepository,
    required this.notificationManager,
  });

  Future<void> snooze(String id) async {
    return work(() async {
      final entry = await entryRepository
          .withAccount()
          .withLabels()
          .get(id);
      await entryRepository.save(
        entry.copyWith(issuedAt: entry.issuedAt.add(Duration(days: 1))),
      );
    });
  }

  Future<void> markAsDone(String id) async {
    return work(() async {
      final entry = await entryRepository
          .withAccount()
          .withLabels()
          .get(id);
      await entryRepository.save(
        entry.copyWith(status: EntryStatus.done),
      );
    });
  }

  delete(String id) {
    return work(() async {
      final entry = await entryRepository
          .withAccount()
          .withLabels()
          .get(id);
      final account = entry.account.revokeEntry(entry);
      await entryRepository.delete(id);
      await accountRepository.save(account);
      await notificationManager.cancelReminder(
        Controller.entry(entry.id),
      );
    });
  }

  get(String id) {
    return entryRepository
        .withLabels()
        .withAccount()
        .withCategory()
        .get(id);
  }

  search({Filter? specification}) {
    return entryRepository
        .withLabels()
        .withAccount()
        .withCategory()
        .search(specification);
  }

  Future<Entry> create({
    required String note,
    required double amount,
    required EntryType type,
    required EntryStatus status,
    required String accountId,
    required String categoryId,
    required DateTime timestamp,
    List<String>? labelIds,
  }) {
    return work<Entry>(() async {
      final account = await accountRepository.get(accountId);
      final category = await categoryRepository.get(categoryId);
      final labels = (labelIds != null && labelIds.isNotEmpty)
          ? await labelRepository.getByIds(labelIds)
          : [];

      final entry = Entry.writeable(
        note: note,
        amount: Entry.compute(type, amount),
        status: status,
        issuedAt: timestamp,
        categoryId: categoryId,
        accountId: accountId,
      ).withLabels(labels).withAccount(account).withCategory(category);

      await entryRepository.withLabels().withAnnotations().save(entry);
      await accountRepository.save(account.applyEntry(entry));

      if (entry.status.isPending()) {
        await notificationManager.setReminder(
          title: category.name,
          body:
              "Reminder: One of your ledger entries is still pending settlement.",
          sentAt: entry.issuedAt,
          controller: Controller.entry(entry.id),
          actions: [NotificationAction.markEntryAsDone],
        );
      }

      return entry;
    });
  }

  update({
    required String id,
    required String note,
    required double amount,
    required EntryType type,
    required EntryStatus status,
    required String accountId,
    required String categoryId,
    required DateTime timestamp,
    List<String>? labelIds,
  }) async {
    return work(() async {
      final entry = await entryRepository
          .withCategory()
          .withAccount()
          .withLabels()
          .get(id);

      await accountRepository.save(entry.account.revokeEntry(entry));

      if (entry.status.isPending()) {
        notificationManager.cancelReminder(Controller.entry(entry.id));
      }

      final newAccount = await accountRepository.get(accountId);
      final newCategory = await categoryRepository.get(categoryId);
      final newLabels = (labelIds != null && labelIds.isNotEmpty)
          ? await labelRepository.getByIds(labelIds)
          : [];
      final newEntry = entry
          .copyWith(
            note: note,
            amount: Entry.compute(type, amount),
            status: status,
            issuedAt: timestamp,
            categoryId: categoryId,
            accountId: accountId,
          )
          .withLabels(newLabels)
          .withAccount(newAccount)
          .withCategory(newCategory);

      await entryRepository.withLabels().withAnnotations().save(
        newEntry,
      );
      await accountRepository.save(newAccount.applyEntry(newEntry));

      if (newEntry.status.isPending()) {
        notificationManager.setReminder(
          title: newCategory.name,
          body:
              "Reminder: One of your ledger entries is still pending settlement.",
          sentAt: newEntry.issuedAt,
          controller: Controller.entry(newEntry.id),
          actions: [NotificationAction.markEntryAsDone],
        );
      }
    });
  }

  debugReminder(String id) async {
    final entry = await entryRepository.withCategory().get(id);

    notificationManager.setReminder(
      title: entry.category.name,
      body:
          "Reminder: One of your ledger entries is still pending settlement.",
      sentAt: DateTime.now().add(Duration(seconds: 3)),
      controller: Controller.entry(entry.id),
      actions: [
        NotificationAction.markEntryAsDone,
        NotificationAction.snoozeEntry,
      ],
    );
  }
}
