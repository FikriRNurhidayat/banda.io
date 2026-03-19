import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/common/services/service.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:bandha/features/commitments/entities/commitment_payment.dart';
import 'package:bandha/features/commitments/repositories/commitment_payment_repository.dart';
import 'package:bandha/features/commitments/repositories/commitment_repository.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:bandha/features/notifications/managers/notification_manager.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/tags/repositories/category_repository.dart';
import 'package:bandha/features/tags/repositories/label_repository.dart';
import 'package:bandha/features/tags/repositories/party_repository.dart';
import 'package:bandha/features/tags/types/read_only_label.dart';
import 'package:bandha/features/vaults/repositories/vault_repository.dart';

class CommitmentPaymentService extends Service {
  final CategoryRepository categoryRepository;
  final CommitmentPaymentRepository commitmentPaymentRepository;
  final CommitmentRepository commitmentRepository;
  final EntryRepository entryRepository;
  final LabelRepository labelRepository;
  final NotificationManager notificationManager;
  final PartyRepository partyRepository;
  final VaultRepository vaultRepository;

  CommitmentPaymentService({
    required this.categoryRepository,
    required this.commitmentPaymentRepository,
    required this.commitmentRepository,
    required this.entryRepository,
    required this.labelRepository,
    required this.notificationManager,
    required this.partyRepository,
    required this.vaultRepository,
  });

  create(
    String commitmentId, {
    required double amount,
    double? fee = 0,
    required String vaultId,
    required DateTime issuedAt,
  }) {
    return work<CommitmentPayment>(() async {
      final commitment = await commitmentRepository
          .withCategory()
          .withParty()
          .withVault()
          .withLabels()
          .get(commitmentId);

      final vault = await vaultRepository.get(vaultId);
      final entry = Entry.readOnly(
        note: CommitmentPayment.entryNote(commitment),
        amount: CommitmentPayment.entryAmount(commitment, amount),
        status: EntryStatus.done,
        issuedAt: issuedAt,
        vaultId: vault.id,
        categoryId: commitment.category.id,
      ).withVault(vault);
      final addition = (!isZero(fee)
          ? (Entry.readOnly(
              note: CommitmentPayment.additionNote(commitment),
              amount: CommitmentPayment.additionAmount(commitment, fee),
              status: EntryStatus.done,
              issuedAt: issuedAt,
              vaultId: vaultId,
              categoryId: commitment.category.id,
            ))
          : null);
      final paymentAmount = amount * (commitment.isIncome ? 1 : -1);

      final payment =
          CommitmentPayment.create(
                amount: paymentAmount,
                fee: fee,
                commitmentId: commitment.id,
                entryId: entry.id,
                additionId: addition?.id,
                issuedAt: issuedAt,
              )
              .withAddition(addition)
              .withEntry(entry)
              .withCommitment(commitment);

      return await apply(payment);
    });
  }

  Future<CommitmentPayment> update(
    String commitmentId,
    String entryId, {
    required double amount,
    double? fee = 0,
    required String vaultId,
    required DateTime issuedAt,
  }) {
    return work<CommitmentPayment>(() async {
      var commitment = await commitmentRepository
          .withEntries()
          .withVault()
          .withCategory()
          .withParty()
          .withLabels()
          .get(commitmentId);

      var payment = await commitmentPaymentRepository
          .withEntries()
          .withVault()
          .get(commitmentId, entryId);

      await vaultRepository.save(
        payment.vault.revokeEntries(payment.entries),
      );

      commitment = commitment
          .revokePayment(payment)
          .withVault(payment.vault)
          .withEntry(commitment.entry)
          .withParty(commitment.party)
          .withAddition(commitment.addition);

      final vault = await vaultRepository.get(vaultId);
      final entry = payment.entry
          .copyWith(
            note: CommitmentPayment.entryNote(commitment),
            amount: CommitmentPayment.entryAmount(commitment, amount),
            status: EntryStatus.done,
            issuedAt: issuedAt,
            vaultId: vault.id,
          )
          .withVault(vault);
      final addition = (!payment.hasAddition && !isZero(fee)
          ? Entry.readOnly(
              note: CommitmentPayment.additionNote(commitment),
              amount: CommitmentPayment.additionAmount(commitment, fee),
              status: EntryStatus.done,
              issuedAt: issuedAt,
              vaultId: vault.id,
              categoryId: commitment.category.id,
            )
          : ((payment.hasAddition && !isZero(fee)
                ? payment.addition!.copyWith(
                    note: CommitmentPayment.additionNote(commitment),
                    amount: CommitmentPayment.additionAmount(
                      commitment,
                      fee,
                    ),
                    issuedAt: issuedAt,
                    vaultId: vault.id,
                    categoryId: commitment.category.id,
                  )
                : null)));

      final paymentAmount = amount * (commitment.isIncome ? 1 : -1);
      payment = payment
          .copyWith(amount: paymentAmount, fee: fee, issuedAt: issuedAt)
          .withAddition(addition)
          .withEntry(entry)
          .withCommitment(commitment);

      return await apply(payment);
    });
  }

  get(String commitmentId, String entryId) {
    return commitmentPaymentRepository
        .withVault()
        .withCategory()
        .withEntries()
        .get(commitmentId, entryId);
  }

  search({Filter? filter}) {
    return commitmentPaymentRepository
        .withVault()
        .withEntries()
        .withCategory()
        .search(filter: filter);
  }

  delete(String commitmentId, String entryId) {
    return work(() async {
      final payment = await commitmentPaymentRepository
          .withCommitment()
          .withVault()
          .withEntries()
          .get(commitmentId, entryId);

      final nVault = payment.vault.revokeEntries(payment.entries);
      final nCommitment = payment.commitment.revokePayment(payment);

      await vaultRepository.save(nVault);
      await commitmentRepository.save(nCommitment);

      await commitmentPaymentRepository.delete(
        payment.commitment.id,
        payment.entry.id,
      );
      await entryRepository.deleteByIds(payment.entryIds);
    });
  }

  Future<CommitmentPayment> apply(CommitmentPayment payment) async {
    final [commitmentLabel, paymentLabel, feeLabel] =
        await getReadOnlyLabels();

    await entryRepository.bulkSave(
      payment.entries.map((e) => e.controlledBy(payment.commitment)),
    );

    for (var entry in payment.entries) {
      await entryRepository.saveLabels(entry.id, [
        commitmentLabel.id,
        paymentLabel.id,
        if (payment.addition != null &&
            entry.id == payment.addition!.id)
          feeLabel.id,
        ...payment.commitment.labels.map((label) => label.id),
      ]);
    }

    await vaultRepository.save(
      payment.vault.applyEntries(payment.entries),
    );
    await commitmentRepository.save(
      payment.commitment.applyPayment(payment),
    );
    await commitmentPaymentRepository.save(payment);

    return payment;
  }

  Future<List<Label>> getReadOnlyLabels() async {
    final labels = await labelRepository.getByNames([
      ReadOnlyLabel.commitment.label,
      ReadOnlyLabel.payment.label,
      ReadOnlyLabel.fee.label,
    ]);

    return <Label>[
      labels.firstWhere(
        (label) => label.name == ReadOnlyLabel.commitment.label,
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
