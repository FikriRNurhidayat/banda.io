import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/common/services/service.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:bandha/features/vaults/repositories/vault_repository.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:bandha/features/loans/entities/loan_payment.dart';
import 'package:bandha/features/loans/repositories/loan_payment_repository.dart';
import 'package:bandha/features/loans/repositories/loan_repository.dart';
import 'package:bandha/features/notifications/managers/notification_manager.dart';
import 'package:bandha/features/tags/repositories/category_repository.dart';
import 'package:bandha/features/tags/repositories/party_repository.dart';

class LoanPaymentService extends Service {
  final LoanRepository loanRepository;
  final LoanPaymentRepository loanPaymentRepository;
  final CategoryRepository categoryRepository;
  final EntryRepository entryRepository;
  final VaultRepository vaultRepository;
  final PartyRepository partyRepository;
  final NotificationManager notificationManager;

  LoanPaymentService({
    required this.vaultRepository,
    required this.entryRepository,
    required this.categoryRepository,
    required this.loanRepository,
    required this.loanPaymentRepository,
    required this.partyRepository,
    required this.notificationManager,
  });

  create(
    String loanId, {
    required double amount,
    double? fee = 0,
    required String vaultId,
    required DateTime issuedAt,
  }) {
    return work<LoanPayment>(() async {
      final loan = await loanRepository.withParty().withVault().get(
        loanId,
      );
      final category = await categoryRepository.getByName(
        loan.type.label,
      );

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

      return await apply(payment);
    });
  }

  Future<LoanPayment> update(
    String loanId,
    String entryId, {
    required double amount,
    double? fee = 0,
    required String vaultId,
    required DateTime issuedAt,
  }) {
    return work<LoanPayment>(() async {
      var loan = await loanRepository
          .withEntries()
          .withVault()
          .withParty()
          .get(loanId);

      var payment = await loanPaymentRepository
          .withEntries()
          .withVault()
          .get(loanId, entryId);

      await vaultRepository.save(
        payment.vault.revokeEntries(payment.entries),
      );

      loan = loan
          .revokePayment(payment)
          .withVault(payment.vault)
          .withEntry(loan.entry)
          .withParty(loan.party)
          .withAddition(loan.addition);

      final vault = await vaultRepository.get(vaultId);
      final entry = payment.entry
          .copyWith(
            note: LoanPayment.entryNote(loan),
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
                            amount: LoanPayment.additionAmount(
                              loan,
                              fee,
                            ),
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

      return await apply(payment);
    });
  }

  get(String loanId, String entryId) {
    return loanPaymentRepository
        .withVault()
        .withCategory()
        .withEntries()
        .get(loanId, entryId);
  }

  search({Filter? filter}) {
    return loanPaymentRepository
        .withVault()
        .withEntries()
        .withCategory()
        .search(filter: filter);
  }

  delete(String loanId, String entryId) {
    return work(() async {
      final payment = await loanPaymentRepository
          .withLoan()
          .withVault()
          .withEntries()
          .get(loanId, entryId);

      final nVault = payment.vault.revokeEntries(payment.entries);
      final nLoan = payment.loan.revokePayment(payment);

      await vaultRepository.save(nVault);
      await loanRepository.save(nLoan);

      await loanPaymentRepository.delete(
        payment.loan.id,
        payment.entry.id,
      );
      await entryRepository.deleteByIds(payment.entryIds);
    });
  }

  Future<LoanPayment> apply(LoanPayment payment) async {
    await entryRepository.bulkSave(
      payment.entries.map((entry) => entry.controlledBy(payment.loan)),
    );
    await vaultRepository.save(
      payment.vault.applyEntries(payment.entries),
    );
    await loanRepository.save(payment.loan.applyPayment(payment));
    await loanPaymentRepository.save(payment);

    return payment;
  }
}
