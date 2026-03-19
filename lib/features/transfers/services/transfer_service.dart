import 'package:bandha/common/services/service.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/tags/entities/label.dart';
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
    required double debitAmount,
    required double creditAmount,
    required double? fee,
    required DateTime issuedAt,
    required String debitVaultId,
    required String creditVaultId,
    String? note,
  }) {
    return work(() async {
      final category = await categoryRepository.getByName(
        ReadOnlyCategory.transfer.label,
      );
      final debitVault = await vaultRepository.get(debitVaultId);
      final creditVault = await vaultRepository.get(creditVaultId);
      final [creditLabel, debitLabel, feeLabel] =
          await _readOnlyLabels();

      final credit = Entry.create(
        note: note,
        amount: creditAmount * -1,
        status: EntryStatus.done,
        issuedAt: issuedAt,
        readonly: true,
        vaultId: creditVault.id,
        categoryId: category.id,
      );

      final debit = Entry.create(
        note: note,
        amount: debitAmount,
        status: EntryStatus.done,
        issuedAt: issuedAt,
        readonly: true,
        vaultId: debitVault.id,
        categoryId: category.id,
      );

      final exchange = !isZero(fee)
          ? Entry.create(
              note: note,
              amount: fee! * -1,
              status: EntryStatus.done,
              issuedAt: issuedAt,
              readonly: true,
              vaultId: creditVault.id,
              categoryId: category.id,
            ).annotate("type", "fee")
          : null;

      var transfer = Transfer.create(
        note: note,
        debitAmount: debitAmount,
        creditAmount: creditAmount,
        fee: fee,
        debitId: debit.id,
        debitVaultId: debitVault.id,
        exchangeId: exchange?.id,
        creditId: credit.id,
        creditVaultId: creditVault.id,
        issuedAt: issuedAt,
      );

      transfer = transfer
          .withCredit(
            credit.controlledBy(transfer).withLabels([creditLabel]),
          )
          .withDebit(
            debit.controlledBy(transfer).withLabels([debitLabel]),
          )
          .withCreditVault(creditVault)
          .withDebitVault(debitVault)
          .withExchange(
            exchange?.controlledBy(transfer).withLabels([feeLabel]),
          );

      await entryRepository.withLabels().withAnnotations().bulkSave(
        transfer.entries,
      );
      await transferRepository.save(transfer);
      await executeTransfer(transfer);
    });
  }

  Future<void> update({
    required String id,
    required double debitAmount,
    required double creditAmount,
    required double? fee,
    required DateTime issuedAt,
    required String debitVaultId,
    required String creditVaultId,
    String? note,
  }) {
    return work(() async {
      var transfer = await transferRepository
          .withEntries()
          .withVaults()
          .get(id);

      await abortTransfer(transfer);

      final debitVault = await vaultRepository.get(debitVaultId);
      final creditVault = await vaultRepository.get(creditVaultId);
      final [creditLabel, debitLabel, feeLabel] =
          await _readOnlyLabels();

      final credit = transfer.credit
          .copyWith(
            note: note,
            amount: creditAmount * -1,
            status: EntryStatus.done,
            issuedAt: issuedAt,
            readonly: true,
            vaultId: creditVault.id,
          )
          .withLabels([creditLabel]);

      final exchangeId = transfer.exchangeId;
      final exchangeRemoved = !isZero(transfer.fee) && isZero(fee);
      final Entry? exchange = !isZero(fee)
          ? (transfer.hasExchange
                    ? transfer.exchange!.copyWith(
                        note: note,
                        amount: fee! * -1,
                        status: EntryStatus.done,
                        issuedAt: issuedAt,
                        readonly: true,
                        vaultId: creditVault.id,
                        categoryId: credit.categoryId,
                      )
                    : Entry.create(
                        note: note,
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

      final debit = transfer.debit
          .copyWith(
            note: note,
            amount: debitAmount,
            status: EntryStatus.done,
            issuedAt: issuedAt,
            readonly: true,
            vaultId: debitVault.id,
          )
          .withLabels([debitLabel]);

      transfer = transfer
          .copyWith(
            note: note,
            debitAmount: debitAmount,
            creditAmount: creditAmount,
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
      await entryRepository.withAnnotations().withLabels().bulkSave(
        transfer.entries,
      );
      await executeTransfer(transfer);
      if (exchangeRemoved) {
        await entryRepository.delete(exchangeId!);
      }
    });
  }

  Future<void> delete(String id) {
    return work(() async {
      final transfer = await transferRepository
          .withEntries()
          .withVaults()
          .get(id);
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

  Future<List<Label>> _readOnlyLabels() async {
    final labels = await labelRepository.getByNames([
      ReadOnlyLabel.credit.label,
      ReadOnlyLabel.debit.label,
      ReadOnlyLabel.fee.label,
    ]);

    return <Label>[
      labels.firstWhere(
        (label) => label.name == ReadOnlyLabel.credit.label,
      ),
      labels.firstWhere(
        (label) => label.name == ReadOnlyLabel.debit.label,
      ),
      labels.firstWhere(
        (label) => label.name == ReadOnlyLabel.fee.label,
      ),
    ];
  }
}
