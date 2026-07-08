import 'package:bandha/common/services/service.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/settlements/entities/settlement.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/features/notifications/managers/notification_manager.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/tags/repositories/label_repository.dart';
import 'package:bandha/features/tags/types/read_only_label.dart';
import 'package:bandha/features/vaults/repositories/vault_repository.dart';
import 'package:bandha/features/tags/repositories/category_repository.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:bandha/features/settlements/repositories/settlement_payment_repository.dart';
import 'package:bandha/features/settlements/repositories/settlement_repository.dart';
import 'package:bandha/features/tags/repositories/party_repository.dart';
import 'package:bandha/common/types/controller.dart';
import 'package:bandha/common/types/specification.dart';

class SettlementService extends Service {
  final SettlementRepository settlementRepository;
  final SettlementPaymentRepository paymentRepository;
  final CategoryRepository categoryRepository;
  final EntryRepository entryRepository;
  final VaultRepository vaultRepository;
  final PartyRepository partyRepository;
  final LabelRepository labelRepository;
  final NotificationManager notificationManager;

  SettlementService({
    required this.vaultRepository,
    required this.entryRepository,
    required this.categoryRepository,
    required this.settlementRepository,
    required this.paymentRepository,
    required this.partyRepository,
    required this.labelRepository,
    required this.notificationManager,
  });

  Future<Settlement> sync(String id) async {
    return settlementRepository.sync(id);
  }

  Future<Settlement> create({
    required EntryType type,
    required SettlementStatus status,
    required double amount,
    double? fee = 0,
    required String categoryId,
    required String partyId,
    required String vaultId,
    List<String>? labelIds,
    required DateTime issuedAt,
    DateTime? settledAt,
  }) {
    return work<Settlement>(() async {
      final settlementAmount = amount * (type.isIncome ? 1 : -1);
      final category = await categoryRepository.get(categoryId);
      final party = await partyRepository.get(partyId);
      final vault = await vaultRepository.get(vaultId);
      final labels = await labelRepository.getByIds(labelIds);

      final entry = Entry.readOnly(
        amount: Settlement.entryAmount(type, amount: amount),
        status: EntryStatus.done,
        issuedAt: issuedAt,
        vaultId: vaultId,
        categoryId: category.id,
      );

      final addition = (!isZero(fee)
          ? Entry.readOnly(
              amount: Settlement.getFee(fee!),
              status: EntryStatus.done,
              issuedAt: issuedAt,
              vaultId: vault.id,
              categoryId: category.id,
            )
          : null);

      final settlement =
          Settlement.create(
                amount: settlementAmount,
                remainder: status.isSettled ? 0 : settlementAmount,
                feeAmount: fee,
                status: status,
                partyId: party.id,
                vaultId: vault.id,
                entryId: entry.id,
                categoryId: category.id,
                feeId: addition?.id,
                issuedAt: issuedAt,
                settledAt: settledAt,
              )
              .withVault(vault)
              .withEntry(entry)
              .withFee(addition)
              .withParty(party);

      return await applySettlement(settlement, labels);
    });
  }

  update(
    String id, {
    required EntryType type,
    required SettlementStatus status,
    required double amount,
    double? fee,
    required String categoryId,
    required String partyId,
    required String vaultId,
    required DateTime issuedAt,
    DateTime? settledAt,
    List<String>? labelIds,
  }) {
    return work<Settlement>(() async {
      final nAmount = amount * (type.isIncome ? 1 : -1);
      final nCategory = await categoryRepository.get(categoryId);
      final settlement = await settlementRepository
          .withEntries()
          .withCategory()
          .withParty()
          .withVault()
          .get(id);

      await vaultRepository.save(
        settlement.vault.revokeEntries(settlement.entries),
      );

      final nParty = await partyRepository.get(partyId);
      final nVault = await vaultRepository.get(vaultId);
      final labels = await labelRepository.getByIds(labelIds);
      final nEntry = settlement.entry.copyWith(
        amount: Settlement.entryAmount(type, amount: amount),
        issuedAt: issuedAt,
        vaultId: vaultId,
        categoryId: nCategory.id,
      );

      final Entry? nAddition = ((isZero(settlement.feeAmount) && !isZero(fee))
          ? Entry.readOnly(
              amount: Settlement.getFee(fee!),
              status: EntryStatus.done,
              issuedAt: issuedAt,
              vaultId: nVault.id,
              categoryId: nCategory.id,
            )
          : (!isZero(settlement.feeAmount) && !isZero(fee))
          ? settlement.fee!.copyWith(
              amount: Settlement.getFee(fee!),
              issuedAt: issuedAt,
              readonly: true,
              vaultId: nVault.id,
              categoryId: nCategory.id,
            )
          : null);

      final nRemainder = computeRemainder(
        newAmount: nAmount,
        currentAmount: settlement.amount,
        currentRemainder: settlement.remainder,
      );

      final nSettlement = settlement
          .copyWith(
            amount: nAmount,
            feeAmount: fee,
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
          .withFee(nAddition)
          .withVault(nVault)
          .withParty(nParty);

      return await applySettlement(nSettlement, labels);
    });
  }

  Future<Settlement> get(String id) {
    return settlementRepository
        .withCategory()
        .withParty()
        .withEntries()
        .withVault()
        .get(id);
  }

  search(Filter? spec) {
    return settlementRepository
        .withCategory()
        .withParty()
        .withEntries()
        .withVault()
        .withLabels()
        .search(spec);
  }

  debugReminder(String id) async {
    final settlement = await settlementRepository.withParty().get(id);
    await notificationManager.setReminder(
      title: settlement.party.name,
      body: "Outstanding Settlement",
      sentAt: DateTime.now().add(Duration(seconds: 3)),
      controller: Controller.settlement(settlement.id),
    );
  }

  delete(String id) {
    return work(() async {
      final settlement = await settlementRepository
          .withEntries()
          .withParty()
          .withVault()
          .get(id);

      final payments = await paymentRepository
          .withVault()
          .withEntries()
          .getBySettlementId(settlement.id);

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
        settlement.vault.revokeEntries(settlement.entries),
      ];

      await settlementRepository.delete(settlement.id);
      await vaultRepository.bulkSave(vaults);
      await entryRepository.deleteByIds(settlement.entryIds);
    });
  }

  Future<Settlement> applySettlement(
    Settlement settlement,
    Iterable<Label>? labels,
  ) async {
    final [settlementLabel, feeLabel] = await getReadOnlyLabels();
    final labelIds = labels?.map((label) => label.id) ?? <String>[];

    await entryRepository.bulkSave(
      settlement.entries.map((entry) => entry.controlledBy(settlement)),
    );
    for (var entry in settlement.entries) {
      await entryRepository.saveLabels(entry.id, [
        settlementLabel.id,
        if (settlement.fee != null &&
            entry.id == settlement.fee!.id)
          feeLabel.id,
        ...?labels?.map((label) => label.id),
      ]);
    }

    await vaultRepository.save(
      settlement.vault.applyEntries(settlement.entries),
    );
    await settlementRepository.save(settlement);
    await settlementRepository.saveLabels(settlement.id, labelIds);
    return settlement;
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
      ReadOnlyLabel.settlement.label,
      ReadOnlyLabel.fee.label,
    ]);

    return <Label>[
      labels.firstWhere(
        (label) => label.name == ReadOnlyLabel.settlement.label,
      ),
      labels.firstWhere(
        (label) => label.name == ReadOnlyLabel.fee.label,
      ),
    ];
  }
}
