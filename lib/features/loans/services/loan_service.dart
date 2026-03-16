import 'package:bandha/common/services/service.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/loans/entities/loan.dart';
import 'package:bandha/features/loans/entities/loan_payment.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/features/notifications/managers/notification_manager.dart';
import 'package:bandha/features/vaults/repositories/vault_repository.dart';
import 'package:bandha/features/tags/repositories/category_repository.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:bandha/features/loans/repositories/loan_payment_repository.dart';
import 'package:bandha/features/loans/repositories/loan_repository.dart';
import 'package:bandha/features/tags/repositories/party_repository.dart';
import 'package:bandha/common/types/controller.dart';
import 'package:bandha/common/types/specification.dart';

class LoanService extends Service {
  final LoanRepository loanRepository;
  final LoanPaymentRepository paymentRepository;
  final CategoryRepository categoryRepository;
  final EntryRepository entryRepository;
  final VaultRepository vaultRepository;
  final PartyRepository partyRepository;
  final NotificationManager notificationManager;

  LoanService({
    required this.vaultRepository,
    required this.entryRepository,
    required this.categoryRepository,
    required this.loanRepository,
    required this.paymentRepository,
    required this.partyRepository,
    required this.notificationManager,
  });

  Future<Loan> sync(String id) async {
    return loanRepository.sync(id);
  }

  Future<Loan> create({
    required LoanType type,
    required LoanStatus status,
    required double amount,
    double? fee = 0,
    required String partyId,
    required String vaultId,
    required DateTime issuedAt,
    DateTime? settledAt,
  }) {
    return work<Loan>(() async {
      final category = await categoryRepository.getByName(type.label);
      final party = await partyRepository.get(partyId);
      final vault = await vaultRepository.get(vaultId);
      final entry = Entry.readOnly(
        note: Loan.entryNote(type, party),
        amount: Loan.entryAmount(type, amount: amount, fee: fee),
        status: EntryStatus.done,
        issuedAt: issuedAt,
        vaultId: vaultId,
        categoryId: category.id,
      );

      final addition =
          (!isZero(fee)
                  ? Entry.readOnly(
                      note: Loan.additionNote(type),
                      amount: Loan.additionAmount(fee!),
                      status: EntryStatus.done,
                      issuedAt: issuedAt,
                      vaultId: vault.id,
                      categoryId: category.id,
                    )
                  : null)
              ?.annotate("type", "fee");

      final loan = Loan.create(
        amount: amount,
        remainder: status.isSettled ? 0 : amount,
        fee: fee,
        type: type,
        status: status,
        partyId: party.id,
        vaultId: vault.id,
        entryId: entry.id,
        additionId: addition?.id,
        issuedAt: issuedAt,
        settledAt: settledAt,
      ).withVault(vault).withEntry(entry).withAddition(addition).withParty(party);

      return await applyLoan(loan);
    });
  }

  update(
    String id, {
    required LoanType type,
    required LoanStatus status,
    required double amount,
    double? fee,
    required String partyId,
    required String vaultId,
    required DateTime issuedAt,
    DateTime? settledAt,
  }) {
    return work<Loan>(() async {
      final category = await categoryRepository.getByName(type.label);
      final loan = await loanRepository.withEntries().withParty().withVault().get(id);

      await vaultRepository.save(loan.vault.revokeEntries(loan.entries));

      final nParty = await partyRepository.get(partyId);
      final nVault = await vaultRepository.get(vaultId);
      final nEntry = loan.entry.copyWith(
        note: Loan.entryNote(type, nParty),
        amount: Loan.entryAmount(type, amount: amount, fee: fee),
        issuedAt: issuedAt,
        vaultId: vaultId,
        categoryId: category.id,
      );

      final Entry? nAddition =
          ((isZero(loan.fee) && !isZero(fee))
                  ? Entry.readOnly(
                      note: Loan.additionNote(type),
                      amount: Loan.additionAmount(fee!),
                      status: EntryStatus.done,
                      issuedAt: issuedAt,
                      vaultId: nVault.id,
                      categoryId: category.id,
                    ).annotate("type", "fee")
                  : (!isZero(loan.fee) && !isZero(fee))
                  ? loan.addition!.copyWith(
                      note: Loan.additionNote(type),
                      amount: Loan.additionAmount(fee!),
                      issuedAt: issuedAt,
                      readonly: true,
                      vaultId: nVault.id,
                      categoryId: category.id,
                    )
                  : null)
              ?.annotate("type", "fee");

      final nLoan = loan
          .copyWith(
            amount: amount,
            fee: fee,
            remainder: status.isSettled ? 0 : amount,
            type: type,
            status: status,
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

      return await applyLoan(nLoan);
    });
  }

  searchPayments({Filter? specification}) {
    return paymentRepository.withVault().withEntries().withCategory().search(filter: specification);
  }

  deletePayment(String loanId, String entryId) {
    return work(() async {
      final payment = await paymentRepository.withLoan().withVault().withEntries().get(loanId, entryId);

      final nVault = payment.vault.revokeEntries(payment.entries);
      final nLoan = payment.loan.revokePayment(payment);

      await vaultRepository.save(nVault);
      await loanRepository.save(nLoan);

      await paymentRepository.delete(payment.loan.id, payment.entry.id);
      await entryRepository.deleteByIds(payment.entryIds);
    });
  }

  getPayment(String loanId, String entryId) {
    return paymentRepository.withVault().withCategory().withEntries().get(loanId, entryId);
  }

  updatePayment(
    String loanId,
    String entryId, {
    required double amount,
    double? fee = 0,
    required String vaultId,
    required DateTime issuedAt,
  }) {
    return work<LoanPayment>(() async {
      var payment = await paymentRepository.withLoan().withEntries().withVault().get(loanId, entryId);

      await vaultRepository.save(payment.vault.revokeEntries(payment.entries));

      final loan = payment.loan.revokePayment(payment);
      final vault = await vaultRepository.get(vaultId);
      final entry = payment.entry
          .copyWith(
            amount: LoanPayment.entryAmount(loan, amount),
            status: EntryStatus.done,
            issuedAt: issuedAt,
            vaultId: vault.id,
          )
          .withVault(vault);
      final addition =
          (!payment.hasAddition && !isZero(fee)
                  ? Entry.readOnly(
                      note: LoanPayment.additionNote(loan),
                      amount: LoanPayment.additionAmount(loan, fee),
                      status: EntryStatus.done,
                      issuedAt: issuedAt,
                      vaultId: vault.id,
                      categoryId: entry.categoryId,
                    )
                  : ((payment.hasAddition && !isZero(fee)
                        ? payment.addition!.copyWith(
                            note: LoanPayment.additionNote(loan),
                            amount: LoanPayment.additionAmount(loan, fee),
                            issuedAt: issuedAt,
                            vaultId: vault.id,
                            categoryId: entry.categoryId,
                          )
                        : null)))
              ?.annotate("type", "fee");

      payment = payment
          .copyWith(amount: amount, fee: fee, issuedAt: issuedAt)
          .withAddition(addition)
          .withEntry(entry)
          .withLoan(loan);

      return await applyPayment(payment);
    });
  }

  createPayment(
    String loanId, {
    required double amount,
    double? fee = 0,
    required String vaultId,
    required DateTime issuedAt,
  }) {
    return work<LoanPayment>(() async {
      final loan = await loanRepository.withParty().withVault().get(loanId);
      final category = await categoryRepository.getByName(loan.type.label);

      final vault = await vaultRepository.get(vaultId);
      final entry = Entry.readOnly(
        note: LoanPayment.entryNote(loan),
        amount: LoanPayment.entryAmount(loan, amount),
        status: EntryStatus.done,
        issuedAt: issuedAt,
        vaultId: vault.id,
        categoryId: category.id,
      ).withVault(vault);
      final addition =
          (!isZero(fee)
                  ? (Entry.readOnly(
                      note: LoanPayment.additionNote(loan),
                      amount: LoanPayment.additionAmount(loan, fee),
                      status: EntryStatus.done,
                      issuedAt: issuedAt,
                      vaultId: vaultId,
                      categoryId: category.id,
                    ))
                  : null)
              ?.annotate("type", "fee");

      final payment = LoanPayment.create(
        amount: amount,
        fee: fee,
        loanId: loan.id,
        entryId: entry.id,
        additionId: addition?.id,
        issuedAt: issuedAt,
      ).withAddition(addition).withEntry(entry).withLoan(loan);

      return await applyPayment(payment);
    });
  }

  get(String id) {
    return loanRepository.withParty().withEntries().withVault().get(id);
  }

  search(Filter? spec) {
    return loanRepository.withParty().withEntries().withVault().search(spec);
  }

  debugReminder(String id) async {
    final loan = await loanRepository.withParty().get(id);
    await notificationManager.setReminder(
      title: loan.party.name,
      body: "Outstanding ${loan.type.label}",
      sentAt: DateTime.now().add(Duration(seconds: 3)),
      controller: Controller.loan(loan.id),
    );
  }

  delete(String id) {
    return work(() async {
      final loan = await loanRepository.withEntries().withParty().withVault().get(id);

      final payments = await paymentRepository.withVault().withEntries().getByLoanId(loan.id);

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
        loan.vault.revokeEntries(loan.entries),
      ];

      await loanRepository.delete(loan.id);
      await vaultRepository.bulkSave(vaults);
      await entryRepository.deleteByIds(loan.entryIds);
    });
  }

  Future<Loan> applyLoan(Loan loan) async {
    await entryRepository.bulkSave(loan.entries.map((entry) => entry.controlledBy(loan)));
    await vaultRepository.save(loan.vault.applyEntries(loan.entries));
    await loanRepository.save(loan);
    return loan;
  }

  Future<LoanPayment> applyPayment(LoanPayment payment) async {
    await entryRepository.bulkSave(payment.entries.map((entry) => entry.controlledBy(payment.loan)));
    await vaultRepository.save(payment.vault.applyEntries(payment.entries));
    await loanRepository.save(payment.loan.applyPayment(payment));
    await paymentRepository.save(payment);

    return payment;
  }
}
