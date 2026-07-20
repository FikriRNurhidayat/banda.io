import 'package:bandha/common/services/service.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/tags/repositories/label_repository.dart';
import 'package:bandha/features/tags/types/read_only_category.dart';
import 'package:bandha/features/tags/types/read_only_label.dart';
import 'package:bandha/features/transfers/entities/transfer.dart';
import 'package:bandha/features/transfers/repositories/transfer_repository.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/features/journals/repositories/journal_repository.dart';
import 'package:bandha/features/tags/repositories/category_repository.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';

class TransferService extends Service {
  final JournalRepository journalRepository;
  final CategoryRepository categoryRepository;
  final EntryRepository entryRepository;
  final TransferRepository transferRepository;
  final LabelRepository labelRepository;

  TransferService({
    required this.journalRepository,
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
    required String debitJournalId,
    required String creditJournalId,
    String? note,
  }) {
    return work(() async {
      final category = await categoryRepository.getByName(
        ReadOnlyCategory.transfer.label,
      );
      final debitJournal = await journalRepository.get(debitJournalId);
      final creditJournal = await journalRepository.get(creditJournalId);
      final [creditLabel, debitLabel, feeLabel] =
          await _readOnlyLabels();

      final credit = Entry.create(
        note: note,
        amount: creditAmount * -1,
        status: EntryStatus.done,
        issuedAt: issuedAt,
        readonly: true,
        journalId: creditJournal.id,
        categoryId: category.id,
      );

      final debit = Entry.create(
        note: note,
        amount: debitAmount,
        status: EntryStatus.done,
        issuedAt: issuedAt,
        readonly: true,
        journalId: debitJournal.id,
        categoryId: category.id,
      );

      final exchange = !isZero(fee)
          ? Entry.create(
              note: note,
              amount: fee! * -1,
              status: EntryStatus.done,
              issuedAt: issuedAt,
              readonly: true,
              journalId: creditJournal.id,
              categoryId: category.id,
            ).annotate("type", "fee")
          : null;

      var transfer = Transfer.create(
        note: note,
        debitAmount: debitAmount,
        creditAmount: creditAmount,
        feeAmount: fee,
        debitId: debit.id,
        debitJournalId: debitJournal.id,
        feeId: exchange?.id,
        creditId: credit.id,
        creditJournalId: creditJournal.id,
        issuedAt: issuedAt,
      );

      transfer = transfer
          .withCredit(
            credit.controlledBy(transfer).withLabels([creditLabel]),
          )
          .withDebit(
            debit.controlledBy(transfer).withLabels([debitLabel]),
          )
          .withCreditJournal(creditJournal)
          .withDebitJournal(debitJournal)
          .withFee(
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
    required String debitJournalId,
    required String creditJournalId,
    String? note,
  }) {
    return work(() async {
      var transfer = await transferRepository
          .withEntries()
          .withJournals()
          .get(id);

      await abortTransfer(transfer);

      final debitJournal = await journalRepository.get(debitJournalId);
      final creditJournal = await journalRepository.get(creditJournalId);
      final [creditLabel, debitLabel, feeLabel] =
          await _readOnlyLabels();

      final credit = transfer.credit
          .copyWith(
            note: note,
            amount: creditAmount * -1,
            status: EntryStatus.done,
            issuedAt: issuedAt,
            readonly: true,
            journalId: creditJournal.id,
          )
          .withLabels([creditLabel]);

      final exchangeId = transfer.feeId;
      final exchangeRemoved =
          !isZero(transfer.feeAmount) && isZero(fee);
      final Entry? exchange = !isZero(fee)
          ? (transfer.hasFee
                    ? transfer.fee!.copyWith(
                        note: note,
                        amount: fee! * -1,
                        status: EntryStatus.done,
                        issuedAt: issuedAt,
                        readonly: true,
                        journalId: creditJournal.id,
                        categoryId: credit.categoryId,
                      )
                    : Entry.create(
                        note: note,
                        amount: fee! * -1,
                        status: EntryStatus.done,
                        issuedAt: issuedAt,
                        readonly: true,
                        journalId: creditJournal.id,
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
            journalId: debitJournal.id,
          )
          .withLabels([debitLabel]);

      transfer = transfer
          .copyWith(
            note: note,
            debitAmount: debitAmount,
            creditAmount: creditAmount,
            feeAmount: fee,
            debitId: debit.id,
            debitJournalId: debitJournal.id,
            creditId: credit.id,
            creditJournalId: creditJournal.id,
            issuedAt: issuedAt,
          )
          .setFeeId(exchange?.id)
          .withFee(exchange)
          .withDebit(debit)
          .withCredit(credit)
          .withDebitJournal(debitJournal)
          .withCreditJournal(creditJournal);

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
          .withJournals()
          .get(id);
      await abortTransfer(transfer);
      await transferRepository.delete(transfer.id);
      await entryRepository.deleteByIds(transfer.entryIds);
    });
  }

  Future<Transfer?> get(String id) {
    return transferRepository.withEntries().withJournals().get(id);
  }

  Future<List<Transfer>> search() {
    return transferRepository.withEntries().withJournals().search();
  }

  Future<void> abortTransfer(Transfer transfer) async {
    await journalRepository.bulkSave([
      transfer.debitJournal.revokeEntry(transfer.debit),
      transfer.creditJournal.revokeEntries(transfer.credits),
    ]);
  }

  Future<void> executeTransfer(Transfer transfer) async {
    await journalRepository.bulkSave([
      transfer.debitJournal.applyEntry(transfer.debit),
      transfer.creditJournal.applyEntries(transfer.credits),
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
