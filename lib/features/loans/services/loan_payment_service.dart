import 'package:banda/common/helpers/type_helper.dart';
import 'package:banda/common/services/service.dart';
import 'package:banda/common/types/specification.dart';
import 'package:banda/features/accounts/repositories/account_repository.dart';
import 'package:banda/features/entries/entities/entry.dart';
import 'package:banda/features/entries/repositories/entry_repository.dart';
import 'package:banda/features/loans/entities/loan_payment.dart';
import 'package:banda/features/loans/repositories/loan_payment_repository.dart';
import 'package:banda/features/loans/repositories/loan_repository.dart';
import 'package:banda/features/notifications/managers/notification_manager.dart';
import 'package:banda/features/tags/repositories/category_repository.dart';
import 'package:banda/features/tags/repositories/party_repository.dart';

class LoanPaymentService extends Service {
  final LoanRepository loanRepository;
  final LoanPaymentRepository loanPaymentRepository;
  final CategoryRepository categoryRepository;
  final EntryRepository entryRepository;
  final AccountRepository accountRepository;
  final PartyRepository partyRepository;
  final NotificationManager notificationManager;

  LoanPaymentService({
    required this.accountRepository,
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
    required String accountId,
    required DateTime issuedAt,
  }) {
    return work<LoanPayment>(() async {
      final loan = await loanRepository.withParty().withAccount().get(
        loanId,
      );
      final category = await categoryRepository.getByName(
        loan.type.label,
      );

      final account = await accountRepository.get(accountId);
      final entry = Entry.readOnly(
        note: LoanPayment.entryNote(loan),
        amount: LoanPayment.entryAmount(loan, amount),
        status: EntryStatus.done,
        issuedAt: issuedAt,
        accountId: account.id,
        categoryId: category.id,
      ).withAccount(account);
      final addition =
          (!isZero(fee)
                  ? (Entry.readOnly(
                      note: LoanPayment.additionNote(loan),
                      amount: LoanPayment.additionAmount(loan, fee),
                      status: EntryStatus.done,
                      issuedAt: issuedAt,
                      accountId: accountId,
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
    required String accountId,
    required DateTime issuedAt,
  }) {
    return work<LoanPayment>(() async {
      var loan = await loanRepository
          .withEntries()
          .withAccount()
          .withParty()
          .get(loanId);

      var payment = await loanPaymentRepository
          .withEntries()
          .withAccount()
          .get(loanId, entryId);

      await accountRepository.save(
        payment.account.revokeEntries(payment.entries),
      );

      loan = loan
          .revokePayment(payment)
          .withAccount(payment.account)
          .withEntry(loan.entry)
          .withParty(loan.party)
          .withAddition(loan.addition);

      final account = await accountRepository.get(accountId);
      final entry = payment.entry
          .copyWith(
            note: LoanPayment.entryNote(loan),
            amount: LoanPayment.entryAmount(loan, amount),
            status: EntryStatus.done,
            issuedAt: issuedAt,
            accountId: account.id,
          )
          .withAccount(account);
      final addition =
          (!payment.hasAddition && !isZero(fee)
                  ? Entry.readOnly(
                      note: LoanPayment.additionNote(loan),
                      amount: LoanPayment.additionAmount(loan, fee),
                      status: EntryStatus.done,
                      issuedAt: issuedAt,
                      accountId: account.id,
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
                            accountId: account.id,
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
        .withAccount()
        .withCategory()
        .withEntries()
        .get(loanId, entryId);
  }

  search({Filter? filter}) {
    return loanPaymentRepository
        .withAccount()
        .withEntries()
        .withCategory()
        .search(filter: filter);
  }

  delete(String loanId, String entryId) {
    return work(() async {
      final payment = await loanPaymentRepository
          .withLoan()
          .withAccount()
          .withEntries()
          .get(loanId, entryId);

      final nAccount = payment.account.revokeEntries(payment.entries);
      final nLoan = payment.loan.revokePayment(payment);

      await accountRepository.save(nAccount);
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
    await accountRepository.save(
      payment.account.applyEntries(payment.entries),
    );
    await loanRepository.save(payment.loan.applyPayment(payment));
    await loanPaymentRepository.save(payment);

    return payment;
  }
}
