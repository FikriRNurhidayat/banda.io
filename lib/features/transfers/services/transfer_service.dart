import 'package:bandha/common/services/service.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/tags/repositories/label_repository.dart';
import 'package:bandha/features/tags/types/read_only_category.dart';
import 'package:bandha/features/tags/types/read_only_label.dart';
import 'package:bandha/features/transfers/entities/transfer.dart';
import 'package:bandha/features/transfers/repositories/transfer_repository.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/features/vaults/repositories/vault_repository.dart';
import 'package:bandha/features/tags/repositories/category_repository.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';

class TransferService extends Service {
  final VaultRepository vaultRepository;
  final CategoryRepository categoryRepository;
  final EntryRepository entryRepository;
  final TransferRepository transferRepository;
  final LabelRepository labelRepository;

  TransferService({
    required this.vaultRepository,
    required this.categoryRepository,
    required this.entryRepository,
    required this.transferRepository,
    required this.labelRepository,
  });

  Future<void> create({
    required double amount,
    required double? fee,
    required DateTime issuedAt,
    required String debitVaultId,
    required String creditVaultId,
  }) {
    return work(() async {
      final category = await categoryRepository.getByName(ReadOnlyCategory.transfer.label);
      final debitVault = await vaultRepository.get(debitVaultId);
      final creditVault = await vaultRepository.get(creditVaultId);
      final feeLabel = await labelRepository.getByName(ReadOnlyLabel.fee.label);

      final credit = Entry.create(
        amount: amount * -1,
        status: EntryStatus.done,
        issuedAt: issuedAt,
        readonly: true,
        vaultId: creditVault.id,
        categoryId: category.id,
      );

      final debit = Entry.create(
        amount: amount,
        status: EntryStatus.done,
        issuedAt: issuedAt,
        readonly: true,
        vaultId: debitVault.id,
        categoryId: category.id,
      );

      final exchange = !isZero(fee)
          ? Entry.create(
              amount: fee! * -1,
              status: EntryStatus.done,
              issuedAt: issuedAt,
              readonly: true,
              vaultId: creditVault.id,
              categoryId: category.id,
            ).annotate("type", "fee")
          : null;

      var transfer = Transfer.create(
        amount: amount,
        fee: fee,
        debitId: debit.id,
        debitVaultId: debitVault.id,
        exchangeId: exchange?.id,
        creditId: credit.id,
        creditVaultId: creditVault.id,
        issuedAt: issuedAt,
      );

      transfer = transfer
          .withCredit(credit.controlledBy(transfer))
          .withDebit(debit.controlledBy(transfer))
          .withCreditVault(creditVault)
          .withDebitVault(debitVault)
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
    required String debitVaultId,
    required String creditVaultId,
  }) {
    return work(() async {
      var transfer = await transferRepository.withEntries().withVaults().get(id);

      await abortTransfer(transfer);

      final debitVault = await vaultRepository.get(debitVaultId);
      final creditVault = await vaultRepository.get(creditVaultId);
      final feeLabel = await labelRepository.getByName(ReadOnlyLabel.fee.label);

      final credit = transfer.credit.copyWith(
        amount: amount * -1,
        status: EntryStatus.done,
        issuedAt: issuedAt,
        readonly: true,
        vaultId: creditVault.id,
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
                        vaultId: creditVault.id,
                        categoryId: credit.categoryId,
                      )
                    : Entry.create(
                        amount: fee! * -1,
                        status: EntryStatus.done,
                        issuedAt: issuedAt,
                        readonly: true,
                        vaultId: creditVault.id,
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
        vaultId: debitVault.id,
      );

      transfer = transfer
          .copyWith(
            amount: amount,
            fee: fee,
            debitId: debit.id,
            debitVaultId: debitVault.id,
            creditId: credit.id,
            creditVaultId: creditVault.id,
            issuedAt: issuedAt,
          )
          .setExchangeId(exchange?.id)
          .withExchange(exchange)
          .withDebit(debit)
          .withCredit(credit)
          .withDebitVault(debitVault)
          .withCreditVault(creditVault);

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
      final transfer = await transferRepository.withEntries().withVaults().get(id);
      await abortTransfer(transfer);
      await transferRepository.delete(transfer.id);
      await entryRepository.deleteByIds(transfer.entryIds);
    });
  }

  Future<Transfer?> get(String id) {
    return transferRepository.withEntries().withVaults().get(id);
  }

  Future<List<Transfer>> search() {
    return transferRepository.withEntries().withVaults().search();
  }

  Future<void> abortTransfer(Transfer transfer) async {
    await vaultRepository.bulkSave([
      transfer.debitVault.revokeEntry(transfer.debit),
      transfer.creditVault.revokeEntries(transfer.credits),
    ]);
  }

  Future<void> executeTransfer(Transfer transfer) async {
    await vaultRepository.bulkSave([
      transfer.debitVault.applyEntry(transfer.debit),
      transfer.creditVault.applyEntries(transfer.credits),
    ]);
  }
}
