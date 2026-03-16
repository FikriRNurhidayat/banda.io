import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/common/services/service.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:bandha/features/commitments/entities/commitment_payment.dart';
import 'package:bandha/features/commitments/repositories/commitment_payment_repository.dart';
import 'package:bandha/features/commitments/repositories/commitment_repository.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:bandha/features/notifications/managers/notification_manager.dart';
import 'package:bandha/features/tags/repositories/category_repository.dart';
import 'package:bandha/features/tags/repositories/party_repository.dart';
import 'package:bandha/features/vaults/repositories/vault_repository.dart';

class CommitmentPaymentService extends Service {
  final CommitmentRepository commitmentRepository;
  final CommitmentPaymentRepository commitmentPaymentRepository;
  final CategoryRepository categoryRepository;
  final EntryRepository entryRepository;
  final VaultRepository vaultRepository;
  final PartyRepository partyRepository;
  final NotificationManager notificationManager;

  CommitmentPaymentService({
    required this.vaultRepository,
    required this.entryRepository,
    required this.categoryRepository,
    required this.commitmentRepository,
    required this.commitmentPaymentRepository,
    required this.partyRepository,
    required this.notificationManager,
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
      final addition =
          (!isZero(fee)
                  ? (Entry.readOnly(
                      note: CommitmentPayment.additionNote(commitment),
                      amount: CommitmentPayment.additionAmount(
                        commitment,
                        fee,
                      ),
                      status: EntryStatus.done,
                      issuedAt: issuedAt,
                      vaultId: vaultId,
                      categoryId: commitment.category.id,
                    ))
                  : null)
              ?.annotate("type", "fee");
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
      final addition =
          (!payment.hasAddition && !isZero(fee)
                  ? Entry.readOnly(
                      note: CommitmentPayment.additionNote(commitment),
                      amount: CommitmentPayment.additionAmount(
                        commitment,
                        fee,
                      ),
                      status: EntryStatus.done,
                      issuedAt: issuedAt,
                      vaultId: vault.id,
                      categoryId: commitment.category.id,
                    )
                  : ((payment.hasAddition && !isZero(fee)
                        ? payment.addition!.copyWith(
                            note: CommitmentPayment.additionNote(
                              commitment,
                            ),
                            amount: CommitmentPayment.additionAmount(
                              commitment,
                              fee,
                            ),
                            issuedAt: issuedAt,
                            vaultId: vault.id,
                            categoryId: commitment.category.id,
                          )
                        : null)))
              ?.annotate("type", "fee");

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
    await entryRepository.bulkSave(
      payment.entries.map(
        (entry) => entry.controlledBy(payment.commitment),
      ),
    );
    await vaultRepository.save(
      payment.vault.applyEntries(payment.entries),
    );
    await commitmentRepository.save(
      payment.commitment.applyPayment(payment),
    );
    await commitmentPaymentRepository.save(payment);

    return payment;
  }
}
