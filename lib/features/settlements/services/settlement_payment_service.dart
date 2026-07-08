import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/common/services/service.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:bandha/features/settlements/entities/settlement_payment.dart';
import 'package:bandha/features/settlements/repositories/settlement_payment_repository.dart';
import 'package:bandha/features/settlements/repositories/settlement_repository.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:bandha/features/notifications/managers/notification_manager.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/tags/repositories/category_repository.dart';
import 'package:bandha/features/tags/repositories/label_repository.dart';
import 'package:bandha/features/tags/repositories/party_repository.dart';
import 'package:bandha/features/tags/types/read_only_label.dart';
import 'package:bandha/features/vaults/repositories/vault_repository.dart';

class SettlementPaymentService extends Service {
  final CategoryRepository categoryRepository;
  final SettlementPaymentRepository settlementPaymentRepository;
  final SettlementRepository settlementRepository;
  final EntryRepository entryRepository;
  final LabelRepository labelRepository;
  final NotificationManager notificationManager;
  final PartyRepository partyRepository;
  final VaultRepository vaultRepository;

  SettlementPaymentService({
    required this.categoryRepository,
    required this.settlementPaymentRepository,
    required this.settlementRepository,
    required this.entryRepository,
    required this.labelRepository,
    required this.notificationManager,
    required this.partyRepository,
    required this.vaultRepository,
  });

  create(
    String settlementId, {
    required double amount,
    double? fee = 0,
    required String vaultId,
    required DateTime issuedAt,
  }) {
    return work<SettlementPayment>(() async {
      final settlement = await settlementRepository
          .withCategory()
          .withParty()
          .withVault()
          .withLabels()
          .get(settlementId);

      final vault = await vaultRepository.get(vaultId);
      final entry = Entry.readOnly(
        note: SettlementPayment.entryNote(settlement),
        amount: SettlementPayment.entryAmount(settlement, amount),
        status: EntryStatus.done,
        issuedAt: issuedAt,
        vaultId: vault.id,
        categoryId: settlement.category.id,
      ).withVault(vault);
      final addition = (!isZero(fee)
          ? (Entry.readOnly(
              note: SettlementPayment.additionNote(settlement),
              amount: SettlementPayment.additionAmount(settlement, fee),
              status: EntryStatus.done,
              issuedAt: issuedAt,
              vaultId: vaultId,
              categoryId: settlement.category.id,
            ))
          : null);
      final paymentAmount = amount * (settlement.isIncome ? 1 : -1);

      final payment =
          SettlementPayment.create(
                amount: paymentAmount,
                fee: fee,
                settlementId: settlement.id,
                entryId: entry.id,
                additionId: addition?.id,
                issuedAt: issuedAt,
              )
              .withAddition(addition)
              .withEntry(entry)
              .withSettlement(settlement);

      return await apply(payment);
    });
  }

  Future<SettlementPayment> update(
    String settlementId,
    String entryId, {
    required double amount,
    double? fee = 0,
    required String vaultId,
    required DateTime issuedAt,
  }) {
    return work<SettlementPayment>(() async {
      var settlement = await settlementRepository
          .withEntries()
          .withVault()
          .withCategory()
          .withParty()
          .withLabels()
          .get(settlementId);

      var payment = await settlementPaymentRepository
          .withEntries()
          .withVault()
          .get(settlementId, entryId);

      await vaultRepository.save(
        payment.vault.revokeEntries(payment.entries),
      );

      settlement = settlement
          .revokePayment(payment)
          .withVault(payment.vault)
          .withEntry(settlement.entry)
          .withParty(settlement.party)
          .withFee(settlement.fee);

      final vault = await vaultRepository.get(vaultId);
      final entry = payment.entry
          .copyWith(
            note: SettlementPayment.entryNote(settlement),
            amount: SettlementPayment.entryAmount(settlement, amount),
            status: EntryStatus.done,
            issuedAt: issuedAt,
            vaultId: vault.id,
          )
          .withVault(vault);
      final addition = (!payment.hasAddition && !isZero(fee)
          ? Entry.readOnly(
              note: SettlementPayment.additionNote(settlement),
              amount: SettlementPayment.additionAmount(settlement, fee),
              status: EntryStatus.done,
              issuedAt: issuedAt,
              vaultId: vault.id,
              categoryId: settlement.category.id,
            )
          : ((payment.hasAddition && !isZero(fee)
                ? payment.addition!.copyWith(
                    note: SettlementPayment.additionNote(settlement),
                    amount: SettlementPayment.additionAmount(
                      settlement,
                      fee,
                    ),
                    issuedAt: issuedAt,
                    vaultId: vault.id,
                    categoryId: settlement.category.id,
                  )
                : null)));

      final paymentAmount = amount * (settlement.isIncome ? 1 : -1);
      payment = payment
          .copyWith(amount: paymentAmount, fee: fee, issuedAt: issuedAt)
          .withAddition(addition)
          .withEntry(entry)
          .withSettlement(settlement);

      return await apply(payment);
    });
  }

  get(String settlementId, String entryId) {
    return settlementPaymentRepository
        .withVault()
        .withCategory()
        .withEntries()
        .get(settlementId, entryId);
  }

  search({Filter? filter}) {
    return settlementPaymentRepository
        .withVault()
        .withEntries()
        .withCategory()
        .search(filter: filter);
  }

  delete(String settlementId, String entryId) {
    return work(() async {
      final payment = await settlementPaymentRepository
          .withSettlement()
          .withVault()
          .withEntries()
          .get(settlementId, entryId);

      final nVault = payment.vault.revokeEntries(payment.entries);
      final nSettlement = payment.settlement.revokePayment(payment);

      await vaultRepository.save(nVault);
      await settlementRepository.save(nSettlement);

      await settlementPaymentRepository.delete(
        payment.settlement.id,
        payment.entry.id,
      );
      await entryRepository.deleteByIds(payment.entryIds);
    });
  }

  Future<SettlementPayment> apply(SettlementPayment payment) async {
    final [settlementLabel, paymentLabel, feeLabel] =
        await getReadOnlyLabels();

    await entryRepository.bulkSave(
      payment.entries.map((e) => e.controlledBy(payment.settlement)),
    );

    for (var entry in payment.entries) {
      await entryRepository.saveLabels(entry.id, [
        settlementLabel.id,
        paymentLabel.id,
        if (payment.addition != null &&
            entry.id == payment.addition!.id)
          feeLabel.id,
        ...payment.settlement.labels.map((label) => label.id),
      ]);
    }

    await vaultRepository.save(
      payment.vault.applyEntries(payment.entries),
    );
    await settlementRepository.save(
      payment.settlement.applyPayment(payment),
    );
    await settlementPaymentRepository.save(payment);

    return payment;
  }

  Future<List<Label>> getReadOnlyLabels() async {
    final labels = await labelRepository.getByNames([
      ReadOnlyLabel.settlement.label,
      ReadOnlyLabel.payment.label,
      ReadOnlyLabel.fee.label,
    ]);

    return <Label>[
      labels.firstWhere(
        (label) => label.name == ReadOnlyLabel.settlement.label,
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
