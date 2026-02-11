import 'package:banda/features/bills/providers/bill_provider.dart';
import 'package:banda/features/bills/repositories/bill_repository.dart';
import 'package:banda/features/bills/services/bill_service.dart';
import 'package:banda/features/loans/providers/loan_payment_provider.dart';
import 'package:banda/features/loans/providers/loan_tab_provider.dart';
import 'package:banda/features/loans/services/loan_payment_service.dart';
import 'package:banda/features/loans/services/loan_service.dart';
import 'package:banda/features/main/providers/tool_provider.dart';
import 'package:banda/features/main/services/tool_service.dart';
import 'package:banda/features/transfers/providers/transfer_provider.dart';
import 'package:banda/features/transfers/repositories/transfer_repository.dart';
import 'package:banda/features/transfers/services/transfer_service.dart';
import 'package:banda/features/loans/repositories/loan_payment_repository.dart';
import 'package:banda/infra/db.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import "package:banda/features/tags/repositories/category_repository.dart";
import 'package:banda/features/accounts/providers/account_provider.dart';
import 'package:banda/features/accounts/repositories/account_repository.dart';
import 'package:banda/features/accounts/services/account_service.dart';
import 'package:banda/features/entries/providers/entry_filter_provider.dart';
import 'package:banda/features/entries/providers/entry_provider.dart';
import 'package:banda/features/entries/repositories/entry_repository.dart';
import 'package:banda/features/entries/services/entry_service.dart';
import 'package:banda/features/funds/providers/fund_provider.dart';
import 'package:banda/features/funds/repositories/fund_repository.dart';
import 'package:banda/features/funds/services/fund_service.dart';
import 'package:banda/features/loans/providers/loan_filter_provider.dart';
import 'package:banda/features/loans/providers/loan_provider.dart';
import 'package:banda/features/loans/repositories/loan_repository.dart';
import 'package:banda/features/tags/providers/category_provider.dart';
import 'package:banda/features/tags/providers/label_provider.dart';
import 'package:banda/features/tags/providers/party_provider.dart';
import 'package:banda/features/tags/repositories/label_repository.dart';
import 'package:banda/features/tags/repositories/party_repository.dart';
import 'package:banda/features/main/handlers/notification_handler.dart';
import 'package:banda/features/notifications/managers/notification_manager.dart';
import 'package:banda/notification.dart';
import 'package:banda/features/funds/providers/fund_filter_provider.dart';
import 'package:banda/features/notifications/repositories/notification_repository.dart';

makeProvider({
  required Widget child,
  required NotificationHandler notificationHandler,
}) async {
  final dbManager = DatabaseManager();

  final notificationRepository = NotificationRepository(dbManager);
  final categoryRepository = CategoryRepository(dbManager);
  final entryRepository = EntryRepository(dbManager);
  final accountRepository = AccountRepository(dbManager);
  final transferRepository = TransferRepository(dbManager);
  final loanRepository = LoanRepository(dbManager);
  final loanPaymentRepository = LoanPaymentRepository(dbManager);
  final labelRepository = LabelRepository(dbManager);
  final partyRepository = PartyRepository(dbManager);
  final fundRepository = FundRepository(dbManager);
  final billRepository = BillRepository(dbManager);

  final notificationManager = NotificationManager(
    notificationRepository: notificationRepository,
  );

  final entryService = EntryService(
    entryRepository: entryRepository,
    accountRepository: accountRepository,
    labelRepository: labelRepository,
    categoryRepository: categoryRepository,
    notificationManager: notificationManager,
  );
  final accountService = AccountService(
    accountRepository: accountRepository,
    entryRepository: entryRepository,
    categoryRepository: categoryRepository,
  );
  final transferService = TransferService(
    accountRepository: accountRepository,
    categoryRepository: categoryRepository,
    entryRepository: entryRepository,
    labelRepository: labelRepository,
    transferRepository: transferRepository,
  );
  final loanService = LoanService(
    accountRepository: accountRepository,
    categoryRepository: categoryRepository,
    entryRepository: entryRepository,
    loanRepository: loanRepository,
    paymentRepository: loanPaymentRepository,
    partyRepository: partyRepository,
    notificationManager: notificationManager,
  );
  final fundService = FundService(
    accountRepository: accountRepository,
    categoryRepository: categoryRepository,
    entryRepository: entryRepository,
    fundRepository: fundRepository,
    labelRepository: labelRepository,
  );

  final billService = BillService(
    accountRepository: accountRepository,
    billRepository: billRepository,
    categoryRepository: categoryRepository,
    entryRepository: entryRepository,
    labelRepository: labelRepository,
  );

  final loanPaymentService = LoanPaymentService(
    accountRepository: accountRepository,
    entryRepository: entryRepository,
    categoryRepository: categoryRepository,
    loanRepository: loanRepository,
    loanPaymentRepository: loanPaymentRepository,
    partyRepository: partyRepository,
    notificationManager: notificationManager,
  );

  final toolService = ToolService(dbManager);

  await notificationManager.init(
    notificationHandler,
    didReceiveBackgroundNotificationResponseCallback,
  );

  final providers = [
    ChangeNotifierProvider(create: (_) => ToolProvider(toolService)),
    ChangeNotifierProvider(
      create: (_) => CategoryProvider(categoryRepository),
    ),
    ChangeNotifierProvider(
      create: (_) => AccountProvider(accountService),
    ),
    ChangeNotifierProvider(create: (_) => EntryProvider(entryService)),
    ChangeNotifierProvider(
      create: (_) => TransferProvider(transferService),
    ),
    ChangeNotifierProvider(create: (_) => FundProvider(fundService)),
    ChangeNotifierProvider(create: (_) => LoanProvider(loanService)),
    ChangeNotifierProvider(
      create: (_) => LoanPaymentProvider(loanPaymentService),
    ),
    ChangeNotifierProvider(create: (_) => BillProvider(billService)),
    ChangeNotifierProvider(
      create: (_) => LabelProvider(labelRepository),
    ),
    ChangeNotifierProvider(
      create: (_) => PartyProvider(partyRepository),
    ),
    ChangeNotifierProvider(create: (_) => EntryFilterProvider()),
    ChangeNotifierProvider(create: (_) => LoanFilterProvider()),
    ChangeNotifierProvider(create: (_) => LoanTabProvider()),
    ChangeNotifierProvider(create: (_) => FundFilterProvider()),
  ];

  return MultiProvider(providers: providers, child: child);
}
