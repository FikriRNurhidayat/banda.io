import 'package:banda/common/helpers/type_helper.dart';
import 'package:banda/common/services/service.dart';
import 'package:banda/features/accounts/entities/account.dart';
import 'package:banda/features/accounts/repositories/account_repository.dart';
import 'package:banda/features/entries/entities/entry.dart';
import 'package:banda/features/entries/repositories/entry_repository.dart';
import 'package:banda/features/tags/repositories/category_repository.dart';

class AccountService extends Service {
  final AccountRepository accountRepository;
  final EntryRepository entryRepository;
  final CategoryRepository categoryRepository;

  AccountService({
    required this.accountRepository,
    required this.entryRepository,
    required this.categoryRepository,
  });

  Future<Account> create({
    required String name,
    required String holderName,
    required double balance,
    required AccountKind? kind,
  }) {
    return work<Account>(() async {
      final account = Account.create(
        name: name,
        holderName: holderName,
        balance: balance,
        kind: kind,
      );

      await accountRepository.save(account);

      if (!isZero(balance)) {
        final category = await categoryRepository.getByName("Adjustment");

        final entry = Entry.readOnly(
          amount: balance,
          status: EntryStatus.done,
          issuedAt: DateTime.now(),
          accountId: account.id,
          categoryId: category.id,
        );

        await entryRepository.save(entry);
      }

      return account;
    });
  }

  update(
    String id, {
    required String name,
    required String holderName,
    required double balance,
    required AccountKind? kind,
  }) {
    return work(() async {
      final account = await accountRepository.get(id);

      if (account.balance != balance) {
        final category = await categoryRepository.getByName("Adjustment");
        final delta = balance - account.balance;
        final entry = Entry.readOnly(
          amount: delta,
          status: EntryStatus.done,
          issuedAt: DateTime.now(),
          accountId: account.id,
          categoryId: category.id,
        );

        await entryRepository.save(entry);
      }

      await accountRepository.save(
        account.copyWith(
          name: name,
          holderName: holderName,
          kind: kind,
          balance: balance,
        ),
      );
    });
  }

  search() {
    return accountRepository.search();
  }

  get(String id) {
    return accountRepository.get(id);
  }

  delete(String id) {
    return accountRepository.delete(id);
  }

  sync(String id) {
    return accountRepository.sync(id);
  }
}
