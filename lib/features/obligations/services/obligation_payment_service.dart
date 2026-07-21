import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/common/services/service.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:bandha/features/obligations/entities/obligation_payment.dart';
import 'package:bandha/features/obligations/repositories/obligation_payment_repository.dart';
import 'package:bandha/features/obligations/repositories/obligation_repository.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:bandha/features/notifications/managers/notification_manager.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/tags/repositories/category_repository.dart';
import 'package:bandha/features/tags/repositories/label_repository.dart';
import 'package:bandha/features/tags/repositories/party_repository.dart';
import 'package:bandha/features/tags/types/read_only_label.dart';
import 'package:bandha/features/journals/repositories/journal_repository.dart';

class ObligationPaymentService extends Service {
  final CategoryRepository categoryRepository;
  final ObligationPaymentRepository obligationPaymentRepository;
  final ObligationRepository obligationRepository;
  final EntryRepository entryRepository;
  final LabelRepository labelRepository;
  final NotificationManager notificationManager;
  final PartyRepository partyRepository;
  final JournalRepository journalRepository;

  ObligationPaymentService({
    required this.categoryRepository,
    required this.obligationPaymentRepository,
    required this.obligationRepository,
    required this.entryRepository,
    required this.labelRepository,
    required this.notificationManager,
    required this.partyRepository,
    required this.journalRepository,
  });

  create(
    String obligationId, {
    required double amount,
    double? feeAmount = 0,
    required String journalId,
    required DateTime issuedAt,
  }) {
    return work<ObligationPayment>(() async {
      final obligation = await obligationRepository
          .withCategory()
          .withParty()
          .withJournal()
          .withLabels()
          .get(obligationId);

      final journal = await journalRepository.get(journalId);
      final entry = Entry.readOnly(
        note: ObligationPayment.entryNote(obligation),
        amount: ObligationPayment.entryAmount(obligation, amount),
        status: EntryStatus.done,
        issuedAt: issuedAt,
        journalId: journal.id,
        categoryId: obligation.category.id,
      ).withJournal(journal);
      final fee = (!isZero(feeAmount)
          ? (Entry.readOnly(
              note: ObligationPayment.feeNote(obligation),
              amount: feeAmount! * -1,
              status: EntryStatus.done,
              issuedAt: issuedAt,
              journalId: journalId,
              categoryId: obligation.category.id,
            ))
          : null);
      final paymentAmount = amount * (obligation.isIncome ? 1 : -1);

      final payment = ObligationPayment.create(
        amount: paymentAmount,
        feeAmount: feeAmount!,
        obligationId: obligation.id,
        entryId: entry.id,
        feeId: fee?.id,
        issuedAt: issuedAt,
      ).withFee(fee).withEntry(entry).withObligation(obligation);

      return await apply(payment);
    });
  }

  Future<ObligationPayment> update(
    String obligationId,
    String entryId, {
    required double amount,
    double? feeAmount = 0,
    required String journalId,
    required DateTime issuedAt,
  }) {
    return work<ObligationPayment>(() async {
      var obligation = await obligationRepository
          .withEntries()
          .withJournal()
          .withCategory()
          .withParty()
          .withLabels()
          .get(obligationId);

      var payment = await obligationPaymentRepository
          .withEntries()
          .withJournal()
          .get(obligationId, entryId);

      await journalRepository.save(
        payment.journal.revokeEntries(payment.entries),
      );

      obligation = obligation
          .revokePayment(payment)
          .withJournal(payment.journal)
          .withEntry(obligation.entry)
          .withParty(obligation.party)
          .withFee(obligation.fee);

      final journal = await journalRepository.get(journalId);
      final entry = payment.entry
          .copyWith(
            note: ObligationPayment.entryNote(obligation),
            amount: ObligationPayment.entryAmount(obligation, amount),
            status: EntryStatus.done,
            issuedAt: issuedAt,
            journalId: journal.id,
          )
          .withJournal(journal);
      final fee = (!payment.hasFee && !isZero(feeAmount)
          ? Entry.readOnly(
              note: ObligationPayment.feeNote(obligation),
              amount: feeAmount!,
              status: EntryStatus.done,
              issuedAt: issuedAt,
              journalId: journal.id,
              categoryId: obligation.category.id,
            )
          : ((payment.hasFee && !isZero(feeAmount)
                ? payment.fee!.copyWith(
                    note: ObligationPayment.feeNote(obligation),
                    amount: feeAmount!,
                    issuedAt: issuedAt,
                    journalId: journal.id,
                    categoryId: obligation.category.id,
                  )
                : null)));

      final paymentAmount = amount * (obligation.isIncome ? 1 : -1);
      payment = payment
          .copyWith(
            amount: paymentAmount,
            feeAmount: feeAmount,
            issuedAt: issuedAt,
          )
          .withFee(fee)
          .withEntry(entry)
          .withObligation(obligation);

      return await apply(payment);
    });
  }

  get(String obligationId, String entryId) {
    return obligationPaymentRepository
        .withJournal()
        .withCategory()
        .withEntries()
        .get(obligationId, entryId);
  }

  search({Filter? filter}) {
    return obligationPaymentRepository
        .withJournal()
        .withEntries()
        .withCategory()
        .search(filter: filter);
  }

  delete(String obligationId, String entryId) {
    return work(() async {
      final payment = await obligationPaymentRepository
          .withObligation()
          .withJournal()
          .withEntries()
          .get(obligationId, entryId);

      final nJournal = payment.journal.revokeEntries(payment.entries);
      final nObligation = payment.obligation.revokePayment(payment);

      await journalRepository.save(nJournal);
      await obligationRepository.save(nObligation);

      await obligationPaymentRepository.delete(
        payment.obligation.id,
        payment.entry.id,
      );
      await entryRepository.deleteByIds(payment.entryIds);
    });
  }

  Future<ObligationPayment> apply(ObligationPayment payment) async {
    final [obligationLabel, paymentLabel, feeLabel] =
        await getReadOnlyLabels();

    await entryRepository.bulkSave(
      payment.entries.map((e) => e.controlledBy(payment.obligation)),
    );

    for (var entry in payment.entries) {
      await entryRepository.saveLabels(entry.id, [
        obligationLabel.id,
        paymentLabel.id,
        if (payment.fee != null && entry.id == payment.fee!.id)
          feeLabel.id,
        ...payment.obligation.labels.map((label) => label.id),
      ]);
    }

    await journalRepository.save(
      payment.journal.applyEntries(payment.entries),
    );
    await obligationRepository.save(
      payment.obligation.applyPayment(payment),
    );
    await obligationPaymentRepository.save(payment);

    return payment;
  }

  Future<List<Label>> getReadOnlyLabels() async {
    final labels = await labelRepository.getByNames([
      ReadOnlyLabel.obligation.label,
      ReadOnlyLabel.payment.label,
      ReadOnlyLabel.fee.label,
    ]);

    return <Label>[
      labels.firstWhere(
        (label) => label.name == ReadOnlyLabel.obligation.label,
      ),
      labels.firstWhere(
        (label) => label.name == ReadOnlyLabel.payment.label,
      ),
      labels.firstWhere(
        (label) => label.name == ReadOnlyLabel.fee.label,
      ),
    ];
  }
}
