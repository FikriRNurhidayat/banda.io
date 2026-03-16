import 'package:bandha/common/services/service.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/commitments/entities/commitment.dart';
import 'package:bandha/features/commitments/entities/commitment_payment.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/features/notifications/managers/notification_manager.dart';
import 'package:bandha/features/vaults/repositories/vault_repository.dart';
import 'package:bandha/features/tags/repositories/category_repository.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:bandha/features/commitments/repositories/commitment_payment_repository.dart';
import 'package:bandha/features/commitments/repositories/commitment_repository.dart';
import 'package:bandha/features/tags/repositories/party_repository.dart';
import 'package:bandha/common/types/controller.dart';
import 'package:bandha/common/types/specification.dart';

class CommitmentService extends Service {
  final CommitmentRepository commitmentRepository;
  final CommitmentPaymentRepository paymentRepository;
  final CategoryRepository categoryRepository;
  final EntryRepository entryRepository;
  final VaultRepository vaultRepository;
  final PartyRepository partyRepository;
  final NotificationManager notificationManager;

  CommitmentService({
    required this.vaultRepository,
    required this.entryRepository,
    required this.categoryRepository,
    required this.commitmentRepository,
    required this.paymentRepository,
    required this.partyRepository,
    required this.notificationManager,
  });

  Future<Commitment> sync(String id) async {
    return commitmentRepository.sync(id);
  }

  Future<Commitment> create({
    required EntryType type,
    required CommitmentStatus status,
    required double amount,
    double? fee = 0,
    required String categoryId,
    required String partyId,
    required String vaultId,
    required DateTime issuedAt,
    DateTime? settledAt,
  }) {
    return work<Commitment>(() async {
      final commitmentAmount = amount * (type.isIncome ? 1 : -1);
      final category = await categoryRepository.get(categoryId);
      final party = await partyRepository.get(partyId);
      final vault = await vaultRepository.get(vaultId);
      final entry = Entry.readOnly(
        note: Commitment.entryNote(type, party),
        amount: Commitment.entryAmount(type, amount: amount),
        status: EntryStatus.done,
        issuedAt: issuedAt,
        vaultId: vaultId,
        categoryId: category.id,
      );

      final addition =
          (!isZero(fee)
                  ? Entry.readOnly(
                      note: Commitment.additionNote(type),
                      amount: Commitment.additionAmount(fee!),
                      status: EntryStatus.done,
                      issuedAt: issuedAt,
                      vaultId: vault.id,
                      categoryId: category.id,
                    )
                  : null)
              ?.annotate("type", "fee");

      final commitment =
          Commitment.create(
                amount: commitmentAmount,
                remainder: status.isSettled ? 0 : commitmentAmount,
                fee: fee,
                status: status,
                partyId: party.id,
                vaultId: vault.id,
                entryId: entry.id,
                categoryId: category.id,
                additionId: addition?.id,
                issuedAt: issuedAt,
                settledAt: settledAt,
              )
              .withVault(vault)
              .withEntry(entry)
              .withAddition(addition)
              .withParty(party);

      return await applyCommitment(commitment);
    });
  }

  update(
    String id, {
    required EntryType type,
    required CommitmentStatus status,
    required double amount,
    double? fee,
    required String categoryId,
    required String partyId,
    required String vaultId,
    required DateTime issuedAt,
    DateTime? settledAt,
  }) {
    return work<Commitment>(() async {
      final nAmount = amount * (type.isIncome ? 1 : -1);
      final nCategory = await categoryRepository.get(categoryId);
      final commitment = await commitmentRepository
          .withEntries()
          .withCategory()
          .withParty()
          .withVault()
          .get(id);

      await vaultRepository.save(
        commitment.vault.revokeEntries(commitment.entries),
      );

      final nParty = await partyRepository.get(partyId);
      final nVault = await vaultRepository.get(vaultId);
      final nEntry = commitment.entry.copyWith(
        note: Commitment.entryNote(type, nParty),
        amount: Commitment.entryAmount(type, amount: amount),
        issuedAt: issuedAt,
        vaultId: vaultId,
        categoryId: nCategory.id,
      );

      final Entry? nAddition =
          ((isZero(commitment.fee) && !isZero(fee))
                  ? Entry.readOnly(
                      note: Commitment.additionNote(type),
                      amount: Commitment.additionAmount(fee!),
                      status: EntryStatus.done,
                      issuedAt: issuedAt,
                      vaultId: nVault.id,
                      categoryId: nCategory.id,
                    ).annotate("type", "fee")
                  : (!isZero(commitment.fee) && !isZero(fee))
                  ? commitment.addition!.copyWith(
                      note: Commitment.additionNote(type),
                      amount: Commitment.additionAmount(fee!),
                      issuedAt: issuedAt,
                      readonly: true,
                      vaultId: nVault.id,
                      categoryId: nCategory.id,
                    )
                  : null)
              ?.annotate("type", "fee");

      final nRemainder = _newRemainder(
        newAmount: nAmount,
        currentAmount: commitment.amount,
        currentRemainder: commitment.remainder,
      );

      final nCommitment = commitment
          .copyWith(
            amount: nAmount,
            fee: fee,
            remainder: status.isSettled ? 0 : nRemainder,
            status: status,
            categoryId: nCategory.id,
            partyId: nParty.id,
            vaultId: nVault.id,
            entryId: nEntry.id,
            issuedAt: issuedAt,
            settledAt: settledAt,
          )
          .withEntry(nEntry)
          .withAddition(nAddition)
          .withVault(nVault)
          .withParty(nParty);

      return await applyCommitment(nCommitment);
    });
  }

  Future<Commitment> get(String id) {
    return commitmentRepository
        .withCategory()
        .withParty()
        .withEntries()
        .withVault()
        .get(id);
  }

  search(Filter? spec) {
    return commitmentRepository
        .withCategory()
        .withParty()
        .withEntries()
        .withVault()
        .search(spec);
  }

  debugReminder(String id) async {
    final commitment = await commitmentRepository.withParty().get(id);
    await notificationManager.setReminder(
      title: commitment.party.name,
      body: "Outstanding Commitment",
      sentAt: DateTime.now().add(Duration(seconds: 3)),
      controller: Controller.commitment(commitment.id),
    );
  }

  delete(String id) {
    return work(() async {
      final commitment = await commitmentRepository
          .withEntries()
          .withParty()
          .withVault()
          .get(id);

      final payments = await paymentRepository
          .withVault()
          .withEntries()
          .getByCommitmentId(commitment.id);

      final vaults = [
        ...payments
            .map((payment) => payment.entry.vault)
            .toSet()
            .map(
              (vault) => vault.revokeEntries(
                payments
                    .where((payment) => payment.entry.vault == vault)
                    .map((payment) => payment.entries)
                    .expand((entry) => entry)
                    .whereType<Entry>(),
              ),
            ),
        commitment.vault.revokeEntries(commitment.entries),
      ];

      await commitmentRepository.delete(commitment.id);
      await vaultRepository.bulkSave(vaults);
      await entryRepository.deleteByIds(commitment.entryIds);
    });
  }

  Future<Commitment> applyCommitment(Commitment commitment) async {
    await entryRepository.bulkSave(
      commitment.entries.map((entry) => entry.controlledBy(commitment)),
    );
    await vaultRepository.save(
      commitment.vault.applyEntries(commitment.entries),
    );
    await commitmentRepository.save(commitment);
    return commitment;
  }

  Future<CommitmentPayment> applyPayment(
    CommitmentPayment payment,
  ) async {
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
    await paymentRepository.save(payment);

    return payment;
  }

  _newRemainder({
    required double newAmount,
    required double currentAmount,
    required double currentRemainder,
  }) {
    final paidAmount = currentAmount - currentRemainder;
    return newAmount - paidAmount;
  }
}
