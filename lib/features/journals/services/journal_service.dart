import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/common/services/service.dart';
import 'package:bandha/features/journals/entities/journal.dart';
import 'package:bandha/features/journals/repositories/journal_repository.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:bandha/features/tags/repositories/category_repository.dart';
import 'package:bandha/features/assets/repositories/asset_repository.dart';

class JournalService extends Service {
  final JournalRepository journalRepository;
  final EntryRepository entryRepository;
  final CategoryRepository categoryRepository;
  final AssetRepository assetRepository;

  JournalService({
    required this.journalRepository,
    required this.entryRepository,
    required this.categoryRepository,
    required this.assetRepository,
  });

  Future<Journal> create({
    required String name,
    required String holderName,
    required double balance,
    required String assetId,
  }) {
    return work<Journal>(() async {
      final journal = Journal.create(
        name: name,
        holderName: holderName,
        balance: balance,
        assetId: assetId,
      );

      await journalRepository.save(journal);

      if (!isZero(balance)) {
        final category = await categoryRepository.getByName(
          "Adjustment",
        );

        final entry = Entry.readOnly(
          amount: balance,
          status: EntryStatus.done,
          issuedAt: DateTime.now(),
          journalId: journal.id,
          categoryId: category.id,
        );

        await entryRepository.save(entry);
      }

      return journal;
    });
  }

  update(
    String id, {
    required String name,
    required String holderName,
    required double balance,
    String? assetId,
  }) {
    return work(() async {
      final journal = await journalRepository.get(id);

      if (journal.balance != balance) {
        final category = await categoryRepository.getByName(
          "Adjustment",
        );
        final delta = balance - journal.balance;
        final entry = Entry.readOnly(
          amount: delta,
          status: EntryStatus.done,
          issuedAt: DateTime.now(),
          journalId: journal.id,
          categoryId: category.id,
        );

        await entryRepository.save(entry);
      }

      await journalRepository.save(
        journal.copyWith(
          name: name,
          holderName: holderName,
          balance: balance,
          assetId: assetId,
        ),
      );
    });
  }

  search() {
    return journalRepository.withAsset().search();
  }

  get(String id) {
    return journalRepository.withAsset().get(id);
  }

  delete(String id) {
    return journalRepository.delete(id);
  }

  sync(String id) {
    return journalRepository.sync(id);
  }
}
