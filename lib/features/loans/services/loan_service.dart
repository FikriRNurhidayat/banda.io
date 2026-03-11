import 'package:banda/common/services/service.dart';
import 'package:banda/features/entries/entities/entry.dart';
import 'package:banda/features/loans/entities/loan.dart';
import 'package:banda/features/loans/entities/loan_payment.dart';
import 'package:banda/common/helpers/type_helper.dart';
import 'package:banda/features/notifications/managers/notification_manager.dart';
import 'package:banda/features/accounts/repositories/account_repository.dart';
import 'package:banda/features/tags/repositories/category_repository.dart';
import 'package:banda/features/entries/repositories/entry_repository.dart';
import 'package:banda/features/loans/repositories/loan_payment_repository.dart';
import 'package:banda/features/loans/repositories/loan_repository.dart';
import 'package:banda/features/tags/repositories/party_repository.dart';
import 'package:banda/common/types/controller.dart';
import 'package:banda/common/types/specification.dart';

class LoanService extends Service {
  final LoanRepository loanRepository;
  final LoanPaymentRepository paymentRepository;
  final CategoryRepository categoryRepository;
  final EntryRepository entryRepository;
  final AccountRepository accountRepository;
  final PartyRepository partyRepository;
  final NotificationManager notificationManager;

  LoanService({
    required this.accountRepository,
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
    required String accountId,
    required DateTime issuedAt,
    DateTime? settledAt,
  }) {
    return work<Loan>(() async {
      final category = await categoryRepository.getByName(type.label);
      final party = await partyRepository.get(partyId);
      final account = await accountRepository.get(accountId);
      final entry = Entry.readOnly(
        note: Loan.entryNote(type, party),
        amount: Loan.entryAmount(type, amount: amount, fee: fee),
        status: EntryStatus.done,
        issuedAt: issuedAt,
        accountId: accountId,
        categoryId: category.id,
      );

      final addition =
          (!isZero(fee)
                  ? Entry.readOnly(
                      note: Loan.additionNote(type),
                      amount: Loan.additionAmount(fee!),
                      status: EntryStatus.done,
                      issuedAt: issuedAt,
                      accountId: account.id,
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
        accountId: account.id,
        entryId: entry.id,
        additionId: addition?.id,
        issuedAt: issuedAt,
        settledAt: settledAt,
      ).withAccount(account).withEntry(entry).withAddition(addition).withParty(party);

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
    required String accountId,
    required DateTime issuedAt,
    DateTime? settledAt,
  }) {
    return work<Loan>(() async {
      final category = await categoryRepository.getByName(type.label);
      final loan = await loanRepository.withEntries().withParty().withAccount().get(id);

      await accountRepository.save(loan.account.revokeEntries(loan.entries));

      final nParty = await partyRepository.get(partyId);
      final nAccount = await accountRepository.get(accountId);
      final nEntry = loan.entry.copyWith(
        note: Loan.entryNote(type, nParty),
        amount: Loan.entryAmount(type, amount: amount, fee: fee),
        issuedAt: issuedAt,
        accountId: accountId,
        categoryId: category.id,
      );

      final Entry? nAddition =
          ((isZero(loan.fee) && !isZero(fee))
                  ? Entry.readOnly(
                      note: Loan.additionNote(type),
                      amount: Loan.additionAmount(fee!),
                      status: EntryStatus.done,
                      issuedAt: issuedAt,
                      accountId: nAccount.id,
                      categoryId: category.id,
                    ).annotate("type", "fee")
                  : (!isZero(loan.fee) && !isZero(fee))
                  ? loan.addition!.copyWith(
                      note: Loan.additionNote(type),
                      amount: Loan.additionAmount(fee!),
                      issuedAt: issuedAt,
                      readonly: true,
                      accountId: nAccount.id,
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
            accountId: nAccount.id,
            entryId: nEntry.id,
            issuedAt: issuedAt,
            settledAt: settledAt,
          )
          .withEntry(nEntry)
          .withAddition(nAddition)
          .withAccount(nAccount)
          .withParty(nParty);

      return await applyLoan(nLoan);
    });
  }

  searchPayments({Filter? specification}) {
    return paymentRepository.withAccount().withEntries().withCategory().search(filter: specification);
  }

  deletePayment(String loanId, String entryId) {
    return work(() async {
      final payment = await paymentRepository.withLoan().withAccount().withEntries().get(loanId, entryId);

      final nAccount = payment.account.revokeEntries(payment.entries);
      final nLoan = payment.loan.revokePayment(payment);

      await accountRepository.save(nAccount);
      await loanRepository.save(nLoan);

      await paymentRepository.delete(payment.loan.id, payment.entry.id);
      await entryRepository.deleteByIds(payment.entryIds);
    });
  }

  getPayment(String loanId, String entryId) {
    return paymentRepository.withAccount().withCategory().withEntries().get(loanId, entryId);
  }

  updatePayment(
    String loanId,
    String entryId, {
    required double amount,
    double? fee = 0,
    required String accountId,
    required DateTime issuedAt,
  }) {
    return work<LoanPayment>(() async {
      var payment = await paymentRepository.withLoan().withEntries().withAccount().get(loanId, entryId);

      await accountRepository.save(payment.account.revokeEntries(payment.entries));

      final loan = payment.loan.revokePayment(payment);
      final account = await accountRepository.get(accountId);
      final entry = payment.entry
          .copyWith(
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
                            amount: LoanPayment.additionAmount(loan, fee),
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

      return await applyPayment(payment);
    });
  }

  createPayment(
    String loanId, {
    required double amount,
    double? fee = 0,
    required String accountId,
    required DateTime issuedAt,
  }) {
    return work<LoanPayment>(() async {
      final loan = await loanRepository.withParty().withAccount().get(loanId);
      final category = await categoryRepository.getByName(loan.type.label);

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

      return await applyPayment(payment);
    });
  }

  get(String id) {
    return loanRepository.withParty().withEntries().withAccount().get(id);
  }

  search(Filter? spec) {
    return loanRepository.withParty().withEntries().withAccount().search(spec);
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
      final loan = await loanRepository.withEntries().withParty().withAccount().get(id);

      final payments = await paymentRepository.withAccount().withEntries().getByLoanId(loan.id);

      final accounts = [
        ...payments
            .map((payment) => payment.entry.account)
            .toSet()
            .map(
              (account) => account.revokeEntries(
                payments
                    .where((payment) => payment.entry.account == account)
                    .map((payment) => payment.entries)
                    .expand((entry) => entry)
                    .whereType<Entry>(),
              ),
            ),
        loan.account.revokeEntries(loan.entries),
      ];

      await loanRepository.delete(loan.id);
      await accountRepository.bulkSave(accounts);
      await entryRepository.deleteByIds(loan.entryIds);
    });
  }

  Future<Loan> applyLoan(Loan loan) async {
    await entryRepository.bulkSave(loan.entries.map((entry) => entry.controlledBy(loan)));
    await accountRepository.save(loan.account.applyEntries(loan.entries));
    await loanRepository.save(loan);
    return loan;
  }

  Future<LoanPayment> applyPayment(LoanPayment payment) async {
    await entryRepository.bulkSave(payment.entries.map((entry) => entry.controlledBy(payment.loan)));
    await accountRepository.save(payment.account.applyEntries(payment.entries));
    await loanRepository.save(payment.loan.applyPayment(payment));
    await paymentRepository.save(payment);

    return payment;
  }
}
