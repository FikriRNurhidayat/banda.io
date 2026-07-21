import 'package:bandha/common/services/service.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/obligations/entities/obligation.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/features/notifications/managers/notification_manager.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/tags/repositories/label_repository.dart';
import 'package:bandha/features/tags/types/read_only_label.dart';
import 'package:bandha/features/journals/repositories/journal_repository.dart';
import 'package:bandha/features/tags/repositories/category_repository.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:bandha/features/obligations/repositories/obligation_payment_repository.dart';
import 'package:bandha/features/obligations/repositories/obligation_repository.dart';
import 'package:bandha/features/tags/repositories/party_repository.dart';
import 'package:bandha/common/types/controller.dart';
import 'package:bandha/common/types/specification.dart';

class ObligationService extends Service {
  final ObligationRepository obligationRepository;
  final ObligationPaymentRepository paymentRepository;
  final CategoryRepository categoryRepository;
  final EntryRepository entryRepository;
  final JournalRepository journalRepository;
  final PartyRepository partyRepository;
  final LabelRepository labelRepository;
  final NotificationManager notificationManager;

  ObligationService({
    required this.journalRepository,
    required this.entryRepository,
    required this.categoryRepository,
    required this.obligationRepository,
    required this.paymentRepository,
    required this.partyRepository,
    required this.labelRepository,
    required this.notificationManager,
  });

  Future<Obligation> sync(String id) async {
    return obligationRepository.sync(id);
  }

  Future<Obligation> create({
    required EntryType type,
    required ObligationStatus status,
    required double amount,
    double? feeAmount = 0,
    required String categoryId,
    required String partyId,
    required String journalId,
    List<String>? labelIds,
    required DateTime issuedAt,
    DateTime? settledAt,
  }) {
    return work<Obligation>(() async {
      final obligationAmount = amount * (type.isIncome ? 1 : -1);
      final category = await categoryRepository.get(categoryId);
      final party = await partyRepository.get(partyId);
      final journal = await journalRepository.get(journalId);
      final labels = await labelRepository.getByIds(labelIds);

      final entry = Entry.readOnly(
        amount: Obligation.entryAmount(type, amount: amount),
        status: EntryStatus.done,
        issuedAt: issuedAt,
        journalId: journalId,
        categoryId: category.id,
      );

      final fee = (!isZero(feeAmount)
          ? Entry.readOnly(
              amount: Obligation.getFee(feeAmount!),
              status: EntryStatus.done,
              issuedAt: issuedAt,
              journalId: journal.id,
              categoryId: category.id,
            )
          : null);

      final obligation =
          Obligation.create(
                amount: obligationAmount,
                remainder: status.isSettled ? 0 : obligationAmount,
                feeAmount: feeAmount,
                status: status,
                partyId: party.id,
                journalId: journal.id,
                entryId: entry.id,
                categoryId: category.id,
                feeId: fee?.id,
                issuedAt: issuedAt,
                settledAt: settledAt,
              )
              .withJournal(journal)
              .withEntry(entry)
              .withFee(fee)
              .withParty(party);

      return await applyObligation(obligation, labels);
    });
  }

  update(
    String id, {
    required EntryType type,
    required ObligationStatus status,
    required double amount,
    double? feeAmount,
    required String categoryId,
    required String partyId,
    required String journalId,
    required DateTime issuedAt,
    DateTime? settledAt,
    List<String>? labelIds,
  }) {
    return work<Obligation>(() async {
      final nAmount = amount * (type.isIncome ? 1 : -1);
      final nCategory = await categoryRepository.get(categoryId);
      final obligation = await obligationRepository
          .withEntries()
          .withCategory()
          .withParty()
          .withJournal()
          .get(id);

      await journalRepository.save(
        obligation.journal.revokeEntries(obligation.entries),
      );

      final nParty = await partyRepository.get(partyId);
      final nJournal = await journalRepository.get(journalId);
      final labels = await labelRepository.getByIds(labelIds);
      final nEntry = obligation.entry.copyWith(
        amount: Obligation.entryAmount(type, amount: amount),
        issuedAt: issuedAt,
        journalId: journalId,
        categoryId: nCategory.id,
      );

      final Entry? nFee =
          ((isZero(obligation.feeAmount) && !isZero(feeAmount))
          ? Entry.readOnly(
              amount: Obligation.getFee(feeAmount!),
              status: EntryStatus.done,
              issuedAt: issuedAt,
              journalId: nJournal.id,
              categoryId: nCategory.id,
            )
          : (!isZero(obligation.feeAmount) && !isZero(feeAmount))
          ? obligation.fee!.copyWith(
              amount: Obligation.getFee(feeAmount!),
              issuedAt: issuedAt,
              readonly: true,
              journalId: nJournal.id,
              categoryId: nCategory.id,
            )
          : null);

      final nRemainder = computeRemainder(
        newAmount: nAmount,
        currentAmount: obligation.amount,
        currentRemainder: obligation.remainder,
      );

      final nObligation = obligation
          .copyWith(
            amount: nAmount,
            feeAmount: feeAmount,
            remainder: status.isSettled ? 0 : nRemainder,
            status: status,
            categoryId: nCategory.id,
            partyId: nParty.id,
            journalId: nJournal.id,
            entryId: nEntry.id,
            issuedAt: issuedAt,
            settledAt: settledAt,
          )
          .withEntry(nEntry)
          .withFee(nFee)
          .withJournal(nJournal)
          .withParty(nParty);

      return await applyObligation(nObligation, labels);
    });
  }

  Future<Obligation> get(String id) {
    return obligationRepository
        .withCategory()
        .withParty()
        .withEntries()
        .withJournal()
        .get(id);
  }

  search(Filter? spec) {
    return obligationRepository
        .withCategory()
        .withParty()
        .withEntries()
        .withJournal()
        .withLabels()
        .search(spec);
  }

  debugReminder(String id) async {
    final obligation = await obligationRepository.withParty().get(id);
    await notificationManager.setReminder(
      title: obligation.party.name,
      body: "Outstanding Obligation",
      sentAt: DateTime.now().add(Duration(seconds: 3)),
      controller: Controller.obligation(obligation.id),
    );
  }

  delete(String id) {
    return work(() async {
      final obligation = await obligationRepository
          .withEntries()
          .withParty()
          .withJournal()
          .get(id);

      final payments = await paymentRepository
          .withJournal()
          .withEntries()
          .getByObligationId(obligation.id);

      final journals = [
        ...payments
            .map((payment) => payment.entry.journal)
            .toSet()
            .map(
              (journal) => journal.revokeEntries(
                payments
                    .where(
                      (payment) => payment.entry.journal == journal,
                    )
                    .map((payment) => payment.entries)
                    .expand((entry) => entry)
                    .whereType<Entry>(),
              ),
            ),
        obligation.journal.revokeEntries(obligation.entries),
      ];

      await obligationRepository.delete(obligation.id);
      await journalRepository.bulkSave(journals);
      await entryRepository.deleteByIds(obligation.entryIds);
    });
  }

  Future<Obligation> applyObligation(
    Obligation obligation,
    Iterable<Label>? labels,
  ) async {
    final [obligationLabel, feeLabel] = await getReadOnlyLabels();
    final labelIds = labels?.map((label) => label.id) ?? <String>[];

    await entryRepository.bulkSave(
      obligation.entries.map((entry) => entry.controlledBy(obligation)),
    );
    for (var entry in obligation.entries) {
      await entryRepository.saveLabels(entry.id, [
        obligationLabel.id,
        if (obligation.fee != null && entry.id == obligation.fee!.id)
          feeLabel.id,
        ...?labels?.map((label) => label.id),
      ]);
    }

    await journalRepository.save(
      obligation.journal.applyEntries(obligation.entries),
    );
    await obligationRepository.save(obligation);
    await obligationRepository.saveLabels(obligation.id, labelIds);
    return obligation;
  }

  computeRemainder({
    required double newAmount,
    required double currentAmount,
    required double currentRemainder,
  }) {
    final paidAmount = currentAmount - currentRemainder;
    return newAmount - paidAmount;
  }

  Future<List<Label>> getReadOnlyLabels() async {
    final labels = await labelRepository.getByNames([
      ReadOnlyLabel.obligation.label,
      ReadOnlyLabel.fee.label,
    ]);

    return <Label>[
      labels.firstWhere(
        (label) => label.name == ReadOnlyLabel.obligation.label,
      ),
      labels.firstWhere(
        (label) => label.name == ReadOnlyLabel.fee.label,
      ),
    ];
  }
}
