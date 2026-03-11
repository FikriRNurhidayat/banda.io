import 'package:banda/common/services/service.dart';
import 'package:banda/features/entries/entities/entry.dart';
import 'package:banda/features/tags/repositories/label_repository.dart';
import 'package:banda/features/tags/types/read_only_category.dart';
import 'package:banda/features/tags/types/read_only_label.dart';
import 'package:banda/features/transfers/entities/transfer.dart';
import 'package:banda/features/transfers/repositories/transfer_repository.dart';
import 'package:banda/common/helpers/type_helper.dart';
import 'package:banda/features/accounts/repositories/account_repository.dart';
import 'package:banda/features/tags/repositories/category_repository.dart';
import 'package:banda/features/entries/repositories/entry_repository.dart';

class TransferService extends Service {
  final AccountRepository accountRepository;
  final CategoryRepository categoryRepository;
  final EntryRepository entryRepository;
  final TransferRepository transferRepository;
  final LabelRepository labelRepository;

  TransferService({
    required this.accountRepository,
    required this.categoryRepository,
    required this.entryRepository,
    required this.transferRepository,
    required this.labelRepository,
  });

  Future<void> create({
    required double amount,
    required double? fee,
    required DateTime issuedAt,
    required String debitAccountId,
    required String creditAccountId,
  }) {
    return work(() async {
      final category = await categoryRepository.getByName(ReadOnlyCategory.transfer.label);
      final debitAccount = await accountRepository.get(debitAccountId);
      final creditAccount = await accountRepository.get(creditAccountId);
      final feeLabel = await labelRepository.getByName(ReadOnlyLabel.fee.label);

      final credit = Entry.create(
        amount: amount * -1,
        status: EntryStatus.done,
        issuedAt: issuedAt,
        readonly: true,
        accountId: creditAccount.id,
        categoryId: category.id,
      );

      final debit = Entry.create(
        amount: amount,
        status: EntryStatus.done,
        issuedAt: issuedAt,
        readonly: true,
        accountId: debitAccount.id,
        categoryId: category.id,
      );

      final exchange = !isZero(fee)
          ? Entry.create(
              amount: fee! * -1,
              status: EntryStatus.done,
              issuedAt: issuedAt,
              readonly: true,
              accountId: creditAccount.id,
              categoryId: category.id,
            ).annotate("type", "fee")
          : null;

      var transfer = Transfer.create(
        amount: amount,
        fee: fee,
        debitId: debit.id,
        debitAccountId: debitAccount.id,
        exchangeId: exchange?.id,
        creditId: credit.id,
        creditAccountId: creditAccount.id,
        issuedAt: issuedAt,
      );

      transfer = transfer
          .withCredit(credit.controlledBy(transfer))
          .withDebit(debit.controlledBy(transfer))
          .withCreditAccount(creditAccount)
          .withDebitAccount(debitAccount)
          .withExchange(exchange?.controlledBy(transfer).withLabels([feeLabel]));

      await entryRepository.withLabels().withAnnotations().bulkSave(transfer.entries);
      await transferRepository.save(transfer);
      await executeTransfer(transfer);
    });
  }

  Future<void> update({
    required String id,
    required double amount,
    required double? fee,
    required DateTime issuedAt,
    required String debitAccountId,
    required String creditAccountId,
  }) {
    return work(() async {
      var transfer = await transferRepository.withEntries().withAccounts().get(id);

      await abortTransfer(transfer);

      final debitAccount = await accountRepository.get(debitAccountId);
      final creditAccount = await accountRepository.get(creditAccountId);
      final feeLabel = await labelRepository.getByName(ReadOnlyLabel.fee.label);

      final credit = transfer.credit.copyWith(
        amount: amount * -1,
        status: EntryStatus.done,
        issuedAt: issuedAt,
        readonly: true,
        accountId: creditAccount.id,
      );

      final exchangeId = transfer.exchangeId;
      final exchangeRemoved = !isZero(transfer.fee) && isZero(fee);
      final Entry? exchange = !isZero(fee)
          ? (transfer.hasExchange
                    ? transfer.exchange!.copyWith(
                        amount: fee! * -1,
                        status: EntryStatus.done,
                        issuedAt: issuedAt,
                        readonly: true,
                        accountId: creditAccount.id,
                        categoryId: credit.categoryId,
                      )
                    : Entry.create(
                        amount: fee! * -1,
                        status: EntryStatus.done,
                        issuedAt: issuedAt,
                        readonly: true,
                        accountId: creditAccount.id,
                        categoryId: credit.categoryId,
                      ).controlledBy(transfer))
                .withLabels([feeLabel])
                .annotate("type", "fee")
          : null;

      final debit = transfer.debit.copyWith(
        amount: amount,
        status: EntryStatus.done,
        issuedAt: issuedAt,
        readonly: true,
        accountId: debitAccount.id,
      );

      transfer = transfer
          .copyWith(
            amount: amount,
            fee: fee,
            debitId: debit.id,
            debitAccountId: debitAccount.id,
            creditId: credit.id,
            creditAccountId: creditAccount.id,
            issuedAt: issuedAt,
          )
          .setExchangeId(exchange?.id)
          .withExchange(exchange)
          .withDebit(debit)
          .withCredit(credit)
          .withDebitAccount(debitAccount)
          .withCreditAccount(creditAccount);

      await transferRepository.save(transfer);
      await entryRepository.withAnnotations().withLabels().bulkSave(transfer.entries);
      await executeTransfer(transfer);
      if (exchangeRemoved) {
        await entryRepository.delete(exchangeId!);
      }
    });
  }

  Future<void> delete(String id) {
    return work(() async {
      final transfer = await transferRepository.withEntries().withAccounts().get(id);
      await abortTransfer(transfer);
      await transferRepository.delete(transfer.id);
      await entryRepository.deleteByIds(transfer.entryIds);
    });
  }

  Future<Transfer?> get(String id) {
    return transferRepository.withEntries().withAccounts().get(id);
  }

  Future<List<Transfer>> search() {
    return transferRepository.withEntries().withAccounts().search();
  }

  Future<void> abortTransfer(Transfer transfer) async {
    await accountRepository.bulkSave([
      transfer.debitAccount.revokeEntry(transfer.debit),
      transfer.creditAccount.revokeEntries(transfer.credits),
    ]);
  }

  Future<void> executeTransfer(Transfer transfer) async {
    await accountRepository.bulkSave([
      transfer.debitAccount.applyEntry(transfer.debit),
      transfer.creditAccount.applyEntries(transfer.credits),
    ]);
  }
}
